#!/bin/bash

# Configure traefik ingress controller for k3s cluster
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Configure traefik ingress controller for Joplin server in k3s cluster"
    echo ""
    echo "Options:"
    echo "  --context CONTEXT   Kubectl context (default: k3s-aws-prod)"
    echo "  --domain DOMAIN     Domain name (default: joplin.emelz.org)"
    echo "  --nodeport PORT     NodePort for traefik (default: 30080)"
    echo "  --install-traefik   Install traefik if not present"
    echo "  --dry-run           Show configuration without applying"
    echo "  --help              Show this help message"
    echo ""
    echo "This script configures traefik ingress resources for the Joplin service."
}

# Default values
CONTEXT="k3s-aws-prod"
DOMAIN="joplin.emelz.org"
NODEPORT="30080"
INSTALL_TRAEFIK=false
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --context)
            CONTEXT="$2"
            shift 2
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --nodeport)
            NODEPORT="$2"
            shift 2
            ;;
        --install-traefik)
            INSTALL_TRAEFIK=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage >&2
            exit 1
            ;;
    esac
done

# Check kubectl context
check_context() {
    local current_context
    current_context=$(kubectl config current-context 2>/dev/null || echo "none")

    if [[ "$current_context" != "$CONTEXT" ]]; then
        info "Switching to context: $CONTEXT"
        kubectl config use-context "$CONTEXT"
    fi

    info "Using kubectl context: $CONTEXT"
}

# Check if traefik is installed
check_traefik() {
    info "Checking traefik installation"

    if kubectl get namespace traefik &>/dev/null; then
        info "✅ Traefik namespace exists"
    elif kubectl get service traefik -n kube-system &>/dev/null; then
        info "✅ Traefik service found in kube-system namespace"
        # Update context for kube-system traefik
        TRAEFIK_NAMESPACE="kube-system"
    else
        warn "⚠️  Traefik not found"
        if $INSTALL_TRAEFIK; then
            install_traefik
        else
            error "Traefik not installed. Use --install-traefik or install manually"
            exit 1
        fi
    fi
}

# Install traefik ingress controller
install_traefik() {
    info "Installing traefik ingress controller"

    # Create traefik namespace
    if ! kubectl get namespace traefik &>/dev/null; then
        kubectl create namespace traefik
    fi

    # Create traefik configuration
    local traefik_config="/tmp/traefik-config.yaml"
    cat > "$traefik_config" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
  namespace: traefik
data:
  traefik.yml: |
    api:
      dashboard: true
      insecure: true

    entryPoints:
      web:
        address: ":80"

    providers:
      kubernetesIngress: {}

    log:
      level: INFO
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: traefik
  labels:
    app: traefik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik
      containers:
      - name: traefik
        image: traefik:v2.10
        args:
        - --configFile=/config/traefik.yml
        ports:
        - name: web
          containerPort: 80
        - name: admin
          containerPort: 8080
        volumeMounts:
        - name: config
          mountPath: /config
      volumes:
      - name: config
        configMap:
          name: traefik-config
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: traefik
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: $NODEPORT
    name: web
  - port: 8080
    name: admin
  selector:
    app: traefik
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik
  namespace: traefik
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik
rules:
- apiGroups: [""]
  resources: ["services", "endpoints", "secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions", "networking.k8s.io"]
  resources: ["ingresses", "ingressclasses"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions", "networking.k8s.io"]
  resources: ["ingresses/status"]
  verbs: ["update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik
subjects:
- kind: ServiceAccount
  name: traefik
  namespace: traefik
EOF

    if $DRY_RUN; then
        info "Would apply traefik configuration:"
        cat "$traefik_config"
    else
        kubectl apply -f "$traefik_config"
        rm "$traefik_config"
        info "✅ Traefik installed successfully"

        # Wait for traefik to be ready
        info "Waiting for traefik deployment to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/traefik -n traefik
    fi
}

# Create traefik ingress for joplin
create_joplin_ingress() {
    info "Creating traefik ingress for $DOMAIN"

    local ingress_file="/tmp/joplin-traefik-ingress.yaml"
    cat > "$ingress_file" << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: joplin-emelz-traefik
  namespace: joplin-prod
  labels:
    app: joplin-emelz
    environment: aws-prod
  annotations:
    # Traefik v2 annotations
    traefik.ingress.kubernetes.io/router.rule: "Host(\`$DOMAIN\`)"
    traefik.ingress.kubernetes.io/router.entrypoints: "web"
    # Remove default ingress class annotation to avoid conflicts
spec:
  rules:
  - host: $DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: joplin-emelz
            port:
              number: 22300
---
# Create a middleware for custom headers if needed
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: joplin-headers
  namespace: joplin-prod
spec:
  headers:
    customRequestHeaders:
      X-Forwarded-Proto: "http"
    customResponseHeaders:
      X-Ingress-Path: "traefik"
EOF

    if $DRY_RUN; then
        info "Would apply joplin ingress configuration:"
        cat "$ingress_file"
    else
        kubectl apply -f "$ingress_file"
        rm "$ingress_file"
        info "✅ Joplin traefik ingress created successfully"
    fi
}

# Verify traefik service
verify_traefik_service() {
    info "Verifying traefik service configuration"

    # Check traefik service
    local traefik_svc_info
    if kubectl get service traefik -n traefik &>/dev/null; then
        traefik_svc_info=$(kubectl get service traefik -n traefik -o wide)
    elif kubectl get service traefik -n kube-system &>/dev/null; then
        traefik_svc_info=$(kubectl get service traefik -n kube-system -o wide)
    else
        error "❌ Traefik service not found"
        return 1
    fi

    echo "$traefik_svc_info"

    # Check NodePort
    local actual_nodeport
    if kubectl get service traefik -n traefik &>/dev/null; then
        actual_nodeport=$(kubectl get service traefik -n traefik -o jsonpath='{.spec.ports[0].nodePort}')
    elif kubectl get service traefik -n kube-system &>/dev/null; then
        actual_nodeport=$(kubectl get service traefik -n kube-system -o jsonpath='{.spec.ports[0].nodePort}')
    fi

    if [[ "$actual_nodeport" == "$NODEPORT" ]]; then
        info "✅ Traefik NodePort matches expected: $NODEPORT"
    else
        warn "⚠️  Traefik NodePort ($actual_nodeport) differs from expected ($NODEPORT)"
        echo "Update nginx configuration or use --nodeport $actual_nodeport"
    fi
}

# Test ingress configuration
test_ingress() {
    info "Testing ingress configuration"

    # Check if ingress was created
    if kubectl get ingress joplin-emelz-traefik -n joplin-prod &>/dev/null; then
        info "✅ Joplin ingress resource exists"
        kubectl get ingress joplin-emelz-traefik -n joplin-prod
    else
        error "❌ Joplin ingress resource not found"
        return 1
    fi

    # Check joplin service
    if kubectl get service joplin-emelz -n joplin-prod &>/dev/null; then
        info "✅ Joplin service exists"
        kubectl get service joplin-emelz -n joplin-prod
    else
        error "❌ Joplin service not found"
        return 1
    fi
}

# Show configuration summary
show_summary() {
    info "Traefik ingress configuration summary:"
    echo ""
    echo "  Domain: $DOMAIN"
    echo "  Traefik NodePort: $NODEPORT"
    echo "  Joplin service: joplin-emelz.joplin-prod.svc.cluster.local:22300"
    echo ""
    info "Traffic flow:"
    echo "  Internet → Nginx (AWS) → Traefik (NodePort $NODEPORT) → Joplin Service → Joplin Pods"
    echo ""
    info "Next steps:"
    echo "  1. Configure nginx on AWS instance: ./scripts/configure-nginx.sh --domain $DOMAIN"
    echo "  2. Ensure DNS points $DOMAIN to AWS instance"
    echo "  3. Test locally: curl -H 'Host: $DOMAIN' http://AWS_IP:$NODEPORT"
    echo "  4. Test end-to-end: curl https://$DOMAIN"
}

# Main execution
main() {
    info "Configuring traefik ingress for Joplin server"

    if $DRY_RUN; then
        info "DRY RUN MODE - No changes will be applied"
    fi

    check_context
    check_traefik

    if ! $DRY_RUN; then
        create_joplin_ingress
        verify_traefik_service
        test_ingress

        info "✅ Traefik ingress configuration complete!"
    fi

    show_summary
}

main "$@"