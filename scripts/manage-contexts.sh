#!/bin/bash

# kubectl context management script for multi-environment deployment
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
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo "Manage kubectl contexts for multi-environment deployment"
    echo ""
    echo "Commands:"
    echo "  list                 List all available contexts"
    echo "  current              Show current context"
    echo "  switch ENV           Switch to environment context"
    echo "  validate ENV         Validate environment connectivity"
    echo "  setup-aws-prod       Interactive setup for AWS production context"
    echo "  setup-onprem-prod    Interactive setup for On-prem production context"
    echo "  help                 Show this help message"
    echo ""
    echo "Environments:"
    echo "  local                k3d local development cluster"
    echo "  aws-prod             AWS k3s production cluster"
    echo "  aws-staging          AWS k3s staging cluster"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 current"
    echo "  $0 switch aws-prod"
    echo "  $0 validate aws-prod"
}

# Environment to context mapping
get_context_for_env() {
    local env="$1"
    case "$env" in
        local) echo "k3d-joplin" ;;
        aws-prod) echo "k3s-aws-prod" ;;
        onprem-prod) echo "k3s-onprem-prod" ;;
        aws-staging) echo "k3s-aws-staging" ;;
        *) error "Unknown environment: $env"; exit 1 ;;
    esac
}

list_contexts() {
    info "Available kubectl contexts:"
    kubectl config get-contexts
    echo
    info "Environment mappings:"
    echo "  local      → k3d-joplin"
    echo "  aws-prod   → k3s-aws-prod"
    echo "  onprem-prod → k3s-onprem-prod"
    echo "  aws-staging → k3s-aws-staging"
}

show_current() {
    local current_context
    current_context=$(kubectl config current-context 2>/dev/null || echo "none")
    info "Current context: $current_context"

    # Map back to environment
    case "$current_context" in
        k3d-joplin) info "Environment: local" ;;
        k3s-aws-prod) info "Environment: aws-prod" ;;
        k3s-onprem-prod) info "Environment: onprem-prod" ;;
        k3s-aws-staging) info "Environment: aws-staging" ;;
        *) warn "Context not managed by this script" ;;
    esac
}

switch_context() {
    local env="$1"
    local context
    context=$(get_context_for_env "$env")

    info "Switching to environment: $env"
    info "Target context: $context"

    if kubectl config get-contexts "$context" >/dev/null 2>&1; then
        kubectl config use-context "$context"
        info "Successfully switched to $env environment"
    else
        error "Context '$context' not found!"
        echo "Available contexts:"
        kubectl config get-contexts -o name
        echo
        echo "To set up the context, run:"
        echo "  $0 setup-$env"
        exit 1
    fi
}

validate_environment() {
    local env="$1"
    local context
    context=$(get_context_for_env "$env")

    info "Validating environment: $env"
    info "Testing context: $context"

    if ! kubectl config get-contexts "$context" >/dev/null 2>&1; then
        error "Context '$context' not found"
        return 1
    fi

    info "Testing cluster connectivity..."
    if kubectl --context="$context" get nodes >/dev/null 2>&1; then
        info "✅ Cluster connectivity OK"
    else
        error "❌ Cannot connect to cluster"
        return 1
    fi

    if [[ "$env" == "aws-prod" ]] || [[ "$env" == "aws-staging" ]] \
       || [[ "$env" == "onprem-prod" ]]; then
        info "Testing Tailscale connectivity..."
        # Try to resolve the Tailscale hostname
        if nslookup rs2423.porgy-sole.ts.net >/dev/null 2>&1; then
            info "✅ Tailscale DNS resolution OK"
        else
            warn "⚠️  Tailscale DNS resolution failed - check Tailscale connection"
        fi
    fi

    info "Environment validation complete"
}

setup_onprem_prod() {
    info "Interactive setup for On-prem production k3s cluster"
    echo
    warn "Prerequisites:"
    echo "  1. Tailscale connected and can reach On-prem instance"
    echo "  2. k3s running on AWS instance"
    echo "  3. kubectl installed locally"
    echo

    read -p "Enter On-prem instance Tailscale IP or hostname: " onprem_host
    read -p "Enter k3s API port (default: 6443): " api_port
    api_port=${api_port:-6443}

    info "Testing connectivity to $onprem_host:$api_port..."
    if ! nc -z "$onprem_host" "$api_port" 2>/dev/null; then
        error "Cannot connect to $onprem_host:$api_port"
        echo "Check:"
        echo "  1. Tailscale is connected: tailscale status"
        echo "  2. k3s is running on Onprem instance"
        echo "  3. Firewall allows port $api_port"
        exit 1
    fi

    info "Connectivity OK. You'll need to manually configure the context."
    echo
    echo "On your Onprem k3s instance, run:"
    echo "  sudo cat /etc/rancher/k3s/k3s.yaml"
    echo
    echo "Then configure kubectl context locally:"
    echo "  kubectl config set-cluster k3s-onprem-prod \\"
    echo "    --server=https://$onprem_host:$api_port \\"
    echo "    --certificate-authority=<BASE64_CA_FROM_K3S_YAML>"
    echo
    echo "  kubectl config set-credentials k3s-onprem-prod \\"
    echo "    --token=<TOKEN_FROM_K3S_YAML>"
    echo
    echo "  kubectl config set-context k3s-onprem-prod \\"
    echo "    --cluster=k3s-onprem-prod \\"
    echo "    --user=k3s-onprem-prod"
    echo
    echo "Test with: $0 validate onprem-prod"
}

setup_aws_prod() {
    info "Interactive setup for AWS production k3s cluster"
    echo
    warn "Prerequisites:"
    echo "  1. Tailscale connected and can reach AWS instance"
    echo "  2. k3s running on Onprem instance"
    echo "  3. kubectl installed locally"
    echo

    read -p "Enter AWS instance Tailscale IP or hostname: " aws_host
    read -p "Enter k3s API port (default: 6443): " api_port
    api_port=${api_port:-6443}

    info "Testing connectivity to $aws_host:$api_port..."
    if ! nc -z "$aws_host" "$api_port" 2>/dev/null; then
        error "Cannot connect to $aws_host:$api_port"
        echo "Check:"
        echo "  1. Tailscale is connected: tailscale status"
        echo "  2. k3s is running on AWS instance"
        echo "  3. Firewall allows port $api_port"
        exit 1
    fi

    info "Connectivity OK. You'll need to manually configure the context."
    echo
    echo "On your AWS k3s instance, run:"
    echo "  sudo cat /etc/rancher/k3s/k3s.yaml"
    echo
    echo "Then configure kubectl context locally:"
    echo "  kubectl config set-cluster k3s-aws-prod \\"
    echo "    --server=https://$aws_host:$api_port \\"
    echo "    --certificate-authority=<BASE64_CA_FROM_K3S_YAML>"
    echo
    echo "  kubectl config set-credentials k3s-aws-prod \\"
    echo "    --token=<TOKEN_FROM_K3S_YAML>"
    echo
    echo "  kubectl config set-context k3s-aws-prod \\"
    echo "    --cluster=k3s-aws-prod \\"
    echo "    --user=k3s-aws-prod"
    echo
    echo "Test with: $0 validate aws-prod"
}

# Main command handling
case "${1:-help}" in
    list)
        list_contexts
        ;;
    current)
        show_current
        ;;
    switch)
        if [[ $# -lt 2 ]]; then
            error "Environment required for switch command"
            usage
            exit 1
        fi
        switch_context "$2"
        ;;
    validate)
        if [[ $# -lt 2 ]]; then
            error "Environment required for validate command"
            usage
            exit 1
        fi
        validate_environment "$2"
        ;;
    setup-aws-prod)
        setup_aws_prod
        ;;
    setup-onprem-prod)
        setup_onprem_prod
        ;;
    help)
        usage
        ;;
    *)
        error "Unknown command: $1"
        usage
        exit 1
        ;;
esac
