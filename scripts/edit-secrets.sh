#!/bin/bash

# Script to edit encrypted secrets using SOPS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SECRETS_DIR="$PROJECT_ROOT/secrets"
SECRETS_FILE="$SECRETS_DIR/secrets.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if secrets file exists
if [ ! -f "$SECRETS_FILE" ]; then
    error "Encrypted secrets file not found: $SECRETS_FILE"
    echo "Run ./scripts/setup-secrets.sh first"
    exit 1
fi

# Check if age key exists
AGE_KEY_FILE="$SECRETS_DIR/age-key.txt"
if [ ! -f "$AGE_KEY_FILE" ]; then
    error "Age key file not found: $AGE_KEY_FILE"
    echo "Run ./scripts/setup-secrets.sh first"
    exit 1
fi

# Set SOPS_AGE_KEY_FILE environment variable
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"

info "Opening encrypted secrets file for editing..."
info "File: $SECRETS_FILE"

# Open the encrypted file with SOPS
sops "$SECRETS_FILE"

info "Secrets file updated."