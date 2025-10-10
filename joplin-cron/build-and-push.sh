#!/bin/bash
# Build and push joplin-cron Docker image to GitHub Container Registry (ghcr.io)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="ghcr.io/ericmelz/joplin-cron"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Build and push joplin-cron Docker image to GitHub Container Registry

Options:
  --tag TAG          Image tag (default: latest)
  --platform ARCH    Target platform (default: linux/amd64)
  --no-cache         Build without cache
  --skip-push        Build only, don't push
  --help             Show this help message

Examples:
  $0                                    # Build and push with 'latest' tag
  $0 --tag v1.0.0                      # Build and push with specific tag
  $0 --tag latest --skip-push          # Build only, don't push
  $0 --platform linux/arm64            # Build for ARM64

Prerequisites:
  1. Docker installed and running
  2. Authenticated with GitHub Container Registry:
     echo \$GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
EOF
}

# Parse arguments
TAG="latest"
PLATFORM="linux/amd64"
NO_CACHE=""
SKIP_PUSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --tag)
            TAG="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --skip-push)
            SKIP_PUSH=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# Verify Docker is running
if ! docker info >/dev/null 2>&1; then
    error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build the image
info "Building Docker image: ${FULL_IMAGE}"
info "Platform: ${PLATFORM}"
info "Build context: ${SCRIPT_DIR}"

if docker build \
    --platform "${PLATFORM}" \
    ${NO_CACHE} \
    -t "${FULL_IMAGE}" \
    "${SCRIPT_DIR}"; then
    info "✅ Build successful: ${FULL_IMAGE}"
else
    error "❌ Build failed"
    exit 1
fi

# Show image info
info "Image details:"
docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Push to registry
if [ "$SKIP_PUSH" = true ]; then
    warn "Skipping push (--skip-push flag set)"
    info "To push manually, run:"
    echo "  docker push ${FULL_IMAGE}"
    exit 0
fi

info "Pushing image to GitHub Container Registry..."

# Check if logged in to ghcr.io
if ! docker info 2>/dev/null | grep -q "ghcr.io"; then
    warn "Not logged in to ghcr.io"
    echo ""
    echo "To authenticate, run:"
    echo "  echo \$GITHUB_TOKEN | docker login ghcr.io -u ericmelz --password-stdin"
    echo ""
    echo "Or create a GitHub Personal Access Token with 'write:packages' scope:"
    echo "  https://github.com/settings/tokens/new?scopes=write:packages"
    echo ""
    read -p "Continue without pushing? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    exit 0
fi

if docker push "${FULL_IMAGE}"; then
    info "✅ Push successful: ${FULL_IMAGE}"
    echo ""
    info "Image is now available at:"
    echo "  ${FULL_IMAGE}"
    echo ""
    info "To pull this image:"
    echo "  docker pull ${FULL_IMAGE}"
else
    error "❌ Push failed"
    exit 1
fi
