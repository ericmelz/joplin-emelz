#!/bin/bash

# Deploy nginx configuration to AWS instance via SSH and Tailscale
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
    echo "Deploy nginx configuration to AWS instance via Tailscale"
    echo ""
    echo "Options:"
    echo "  --host HOST         AWS instance Tailscale hostname or IP (default: rs2423.porgy-sole.ts.net)"
    echo "  --user USER         SSH user (default: ubuntu)"
    echo "  --domain DOMAIN     Domain name (default: joplin.emelz.org)"
    echo "  --no-ssl            Skip SSL setup (test HTTP first)"
    echo "  --dry-run           Show commands without executing"
    echo "  --help              Show this help message"
}

# Default values
AWS_HOST="rs2423.porgy-sole.ts.net"
SSH_USER="ubuntu"
DOMAIN="joplin.emelz.org"
ENABLE_SSL=true
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            AWS_HOST="$2"
            shift 2
            ;;
        --user)
            SSH_USER="$2"
            shift 2
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --no-ssl)
            ENABLE_SSL=false
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

# Test connectivity to AWS instance
test_connectivity() {
    info "Testing connectivity to $AWS_HOST"

    if ping -c 1 "$AWS_HOST" >/dev/null 2>&1; then
        info "✅ Can ping $AWS_HOST"
    else
        error "❌ Cannot ping $AWS_HOST - check Tailscale connection"
        echo "Run: tailscale status"
        exit 1
    fi

    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$AWS_HOST" "echo 'SSH OK'" 2>/dev/null; then
        info "✅ SSH connection works"
    else
        error "❌ SSH connection failed"
        echo "Ensure you can SSH to $SSH_USER@$AWS_HOST"
        echo "Try: ssh $SSH_USER@$AWS_HOST"
        exit 1
    fi
}

# Copy script to AWS instance
copy_script() {
    info "Copying configure-nginx.sh to AWS instance"

    local remote_path="/tmp/configure-nginx.sh"
    local local_script="$SCRIPT_DIR/configure-nginx.sh"

    if [[ ! -f "$local_script" ]]; then
        error "Local script not found: $local_script"
        exit 1
    fi

    if $DRY_RUN; then
        info "Would copy: $local_script -> $SSH_USER@$AWS_HOST:$remote_path"
    else
        scp "$local_script" "$SSH_USER@$AWS_HOST:$remote_path"
        ssh "$SSH_USER@$AWS_HOST" "chmod +x $remote_path"
        info "✅ Script copied and made executable"
    fi
}

# Run nginx configuration on AWS instance
run_nginx_config() {
    info "Running nginx configuration on AWS instance"

    local ssl_flag=""
    if $ENABLE_SSL; then
        ssl_flag="--ssl"
    else
        ssl_flag="--no-ssl"
        warn "SSL disabled - testing HTTP only"
    fi

    local cmd="sudo /tmp/configure-nginx.sh --domain $DOMAIN $ssl_flag"

    if $DRY_RUN; then
        info "Would run on $AWS_HOST: $cmd"
    else
        info "Running: $cmd"
        ssh -t "$SSH_USER@$AWS_HOST" "$cmd"
    fi
}

# Test nginx configuration
test_nginx() {
    info "Testing nginx configuration"

    local protocol="http"
    local port=""

    if $ENABLE_SSL; then
        protocol="https"
        port=""
    else
        protocol="http"
        port=""
    fi

    local test_url="${protocol}://${DOMAIN}/api/ping"

    info "Testing: $test_url"

    if $DRY_RUN; then
        info "Would test: curl $test_url"
    else
        sleep 5  # Give nginx time to reload

        if curl -f -s "$test_url" >/dev/null; then
            info "✅ Nginx configuration working!"
            curl "$test_url"
        else
            warn "⚠️  Initial test failed, this might be expected for SSL setup"
            echo "Try testing manually:"
            echo "  curl -k $test_url  # Skip SSL verification"
            echo "  curl -H 'Host: $DOMAIN' http://$AWS_HOST:30080/api/ping  # Direct to traefik"
        fi
    fi
}

# Show next steps
show_next_steps() {
    info "Next steps:"
    echo ""

    if $ENABLE_SSL; then
        echo "1. Verify SSL certificate was created:"
        echo "   ssh $SSH_USER@$AWS_HOST 'sudo certbot certificates'"
        echo ""
        echo "2. Test HTTPS access:"
        echo "   curl https://$DOMAIN/api/ping"
        echo ""
        echo "3. If SSL fails, test HTTP first:"
        echo "   $0 --no-ssl"
    else
        echo "1. Test HTTP access:"
        echo "   curl http://$DOMAIN/api/ping"
        echo ""
        echo "2. If working, enable SSL:"
        echo "   $0 --domain $DOMAIN"
    fi

    echo ""
    echo "Troubleshooting:"
    echo "  - Check DNS: nslookup $DOMAIN"
    echo "  - Check AWS security groups (ports 80, 443, 30080)"
    echo "  - Check nginx logs: ssh $SSH_USER@$AWS_HOST 'sudo tail -f /var/log/nginx/error.log'"
    echo "  - Test traefik directly: curl -H 'Host: $DOMAIN' http://$AWS_HOST:30080/api/ping"
}

# Main execution
main() {
    info "Deploying nginx configuration to AWS instance"

    if $DRY_RUN; then
        info "DRY RUN MODE - No changes will be applied"
    fi

    test_connectivity
    copy_script
    run_nginx_config

    if ! $DRY_RUN; then
        test_nginx
    fi

    show_next_steps
}

main "$@"