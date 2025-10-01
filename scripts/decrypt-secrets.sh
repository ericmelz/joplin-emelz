#!/bin/bash

# Script to decrypt secrets and output as environment variables or YAML
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
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Decrypt secrets and output in various formats"
    echo ""
    echo "Options:"
    echo "  --env           Output as environment variables (default)"
    echo "  --yaml          Output as YAML"
    echo "  --json          Output as JSON"
    echo "  --key KEY       Output specific key only"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --key jwtSecret"
    echo "  $0 --yaml"
    echo "  eval \"\$($0 --env)\""
}

# Check if secrets file exists
if [ ! -f "$SECRETS_FILE" ]; then
    error "Encrypted secrets file not found: $SECRETS_FILE"
    echo "Run ./scripts/setup-secrets.sh first" >&2
    exit 1
fi

# Check if age key exists
AGE_KEY_FILE="$SECRETS_DIR/age-key.txt"
if [ ! -f "$AGE_KEY_FILE" ]; then
    error "Age key file not found: $AGE_KEY_FILE"
    echo "Run ./scripts/setup-secrets.sh first" >&2
    exit 1
fi

# Set SOPS_AGE_KEY_FILE environment variable
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"

# Parse command line arguments
OUTPUT_FORMAT="env"
SPECIFIC_KEY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            OUTPUT_FORMAT="env"
            shift
            ;;
        --yaml)
            OUTPUT_FORMAT="yaml"
            shift
            ;;
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --key)
            SPECIFIC_KEY="$2"
            shift 2
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

# Decrypt the secrets
case $OUTPUT_FORMAT in
    env)
        if [ -n "$SPECIFIC_KEY" ]; then
            # Output specific key as environment variable
            value=$(sops --decrypt --extract "[\"$SPECIFIC_KEY\"]" "$SECRETS_FILE")
            echo "export ${SPECIFIC_KEY^^}=\"$value\""
        else
            # Convert YAML to env vars
            sops --decrypt "$SECRETS_FILE" | \
            yq eval -o=props | \
            sed 's/^/export /' | \
            sed 's/=/="/' | \
            sed 's/$/"/'
        fi
        ;;
    yaml)
        if [ -n "$SPECIFIC_KEY" ]; then
            echo "$SPECIFIC_KEY: $(sops --decrypt --extract "[\"$SPECIFIC_KEY\"]" "$SECRETS_FILE")"
        else
            sops --decrypt "$SECRETS_FILE"
        fi
        ;;
    json)
        if [ -n "$SPECIFIC_KEY" ]; then
            echo "{\"$SPECIFIC_KEY\": \"$(sops --decrypt --extract "[\"$SPECIFIC_KEY\"]" "$SECRETS_FILE")\"}"
        else
            sops --decrypt --output-type json "$SECRETS_FILE"
        fi
        ;;
esac