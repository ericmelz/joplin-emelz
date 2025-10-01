#!/bin/bash

# Enhanced deployment script with encrypted secrets support
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HELM_DIR="$PROJECT_ROOT/helm"

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
    echo "Usage: $0 [OPTIONS] [RELEASE_NAME]"
    echo "Deploy Joplin server with encrypted secrets"
    echo ""
    echo "Arguments:"
    echo "  RELEASE_NAME    Helm release name (default: joplin-server)"
    echo ""
    echo "Options:"
    echo "  --namespace NS  Deploy to specific namespace (default: default)"
    echo "  --upgrade       Upgrade existing release"
    echo "  --dry-run       Show what would be deployed without deploying"
    echo "  --debug         Enable debug output"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --upgrade joplin-prod"
    echo "  $0 --namespace joplin-prod --dry-run"
}

# Default values
RELEASE_NAME="joplin-server"
NAMESPACE="default"
UPGRADE=false
DRY_RUN=false
DEBUG=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --upgrade)
            UPGRADE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        -*)
            error "Unknown option: $1"
            usage >&2
            exit 1
            ;;
        *)
            RELEASE_NAME="$1"
            shift
            ;;
    esac
done

# Check if secrets are set up
check_secrets_setup() {
    local secrets_file="$PROJECT_ROOT/secrets/secrets.yaml"
    local age_key_file="$PROJECT_ROOT/secrets/age-key.txt"

    if [ ! -f "$secrets_file" ] || [ ! -f "$age_key_file" ]; then
        error "Encrypted secrets not set up!"
        echo "Run: ./scripts/setup-secrets.sh"
        exit 1
    fi

    info "Encrypted secrets found"
}

# Decrypt secrets and create temporary values file
prepare_secrets() {
    info "Decrypting secrets..."

    local jwt_secret
    jwt_secret=$("$SCRIPT_DIR/decrypt-secrets.sh" --key jwtSecret)

    # Remove the export prefix and quotes for Helm
    jwt_secret=$(echo "$jwt_secret" | sed 's/export JWTSECRET="//' | sed 's/"$//')

    debug "JWT Secret length: ${#jwt_secret} characters"

    # Create temporary values file with decrypted secrets
    local temp_values="/tmp/joplin-secrets-values.yaml"
    cat > "$temp_values" << EOF
secrets:
  jwtSecret: "$jwt_secret"
EOF

    echo "$temp_values"
}

# Deploy with Helm
deploy() {
    local temp_values_file
    temp_values_file=$(prepare_secrets)

    # Ensure namespace exists
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        info "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi

    # Prepare Helm command
    local helm_cmd="helm"
    local helm_args=()

    if $UPGRADE; then
        helm_args+=("upgrade" "--install")
        info "Upgrading/installing release: $RELEASE_NAME"
    else
        helm_args+=("install")
        info "Installing release: $RELEASE_NAME"
    fi

    helm_args+=("$RELEASE_NAME" "$HELM_DIR")
    helm_args+=("--namespace" "$NAMESPACE")
    helm_args+=("--values" "$HELM_DIR/values.yaml")
    helm_args+=("--values" "$temp_values_file")

    if $DRY_RUN; then
        helm_args+=("--dry-run")
        info "Dry run mode - no actual deployment"
    fi

    if $DEBUG; then
        helm_args+=("--debug")
    fi

    # Execute Helm command
    info "Running: $helm_cmd ${helm_args[*]}"
    "$helm_cmd" "${helm_args[@]}"

    # Clean up temporary files
    rm -f "$temp_values_file"

    if ! $DRY_RUN; then
        info "Deployment complete!"
        echo
        info "Check status with:"
        echo "  kubectl get pods -n $NAMESPACE"
        echo "  kubectl logs -f deployment/joplin-emelz -n $NAMESPACE"
        echo
        info "Access the service:"
        echo "  kubectl port-forward -n $NAMESPACE svc/joplin-emelz 22300:22300"
        echo "  curl http://localhost:22300/api/ping"
    fi
}

# Main execution
main() {
    info "Deploying Joplin server with encrypted secrets..."

    check_secrets_setup
    deploy
}

main "$@"