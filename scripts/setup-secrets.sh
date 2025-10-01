#!/bin/bash

# Setup script for encrypted secrets using SOPS and age
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SECRETS_DIR="$PROJECT_ROOT/secrets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if required tools are installed
check_dependencies() {
    info "Checking dependencies..."

    if ! command -v sops &> /dev/null; then
        error "sops is required but not installed."
        echo "Install with: brew install sops"
        exit 1
    fi

    if ! command -v age &> /dev/null; then
        error "age is required but not installed."
        echo "Install with: brew install age"
        exit 1
    fi

    info "All dependencies are installed."
}

# Generate age key if it doesn't exist
generate_age_key() {
    local age_key_file="$SECRETS_DIR/age-key.txt"

    if [ ! -f "$age_key_file" ]; then
        info "Generating new age key..."
        mkdir -p "$SECRETS_DIR"
        age-keygen -o "$age_key_file"
        chmod 600 "$age_key_file"
        info "Age key generated: $age_key_file"
        warn "IMPORTANT: Store this key securely and add to your password manager!"
        echo
        echo "Public key for .sops.yaml:"
        grep "public key:" "$age_key_file"
    else
        info "Age key already exists: $age_key_file"
    fi
}

# Create .sops.yaml configuration
create_sops_config() {
    local sops_config="$PROJECT_ROOT/.sops.yaml"
    local age_key_file="$SECRETS_DIR/age-key.txt"

    if [ ! -f "$sops_config" ]; then
        info "Creating .sops.yaml configuration..."
        local public_key=$(grep "public key:" "$age_key_file" | cut -d' ' -f4)

        cat > "$sops_config" << EOF
keys:
  - &age_key $public_key
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: *age_key
EOF
        info ".sops.yaml created"
    else
        info ".sops.yaml already exists"
    fi
}

# Create initial encrypted secrets file
create_encrypted_secrets() {
    local secrets_file="$SECRETS_DIR/secrets.yaml"

    if [ ! -f "$secrets_file" ]; then
        info "Creating encrypted secrets file..."

        # Generate a random JWT secret
        local jwt_secret=$(openssl rand -base64 32)

        # Create unencrypted template
        cat > "$secrets_file.tmp" << EOF
# Encrypted secrets for Joplin
jwtSecret: "$jwt_secret"
# Add more secrets here as needed
# postgresPassword: "your-db-password"
EOF

        # Encrypt the file with SOPS
        sops --encrypt "$secrets_file.tmp" > "$secrets_file"
        rm "$secrets_file.tmp"

        info "Encrypted secrets file created: $secrets_file"
    else
        info "Encrypted secrets file already exists: $secrets_file"
    fi
}

# Update .gitignore
update_gitignore() {
    local gitignore="$PROJECT_ROOT/.gitignore"

    if ! grep -q "secrets/age-key.txt" "$gitignore" 2>/dev/null; then
        info "Updating .gitignore..."
        cat >> "$gitignore" << EOF

# Age encryption key - never commit this!
secrets/age-key.txt

# Temporary unencrypted files
secrets/*.tmp
EOF
        info ".gitignore updated"
    else
        info ".gitignore already configured"
    fi
}

# Main setup
main() {
    info "Setting up encrypted secrets for Joplin project..."

    check_dependencies
    generate_age_key
    create_sops_config
    create_encrypted_secrets
    update_gitignore

    echo
    info "Setup complete! Next steps:"
    echo "1. Edit secrets: ./scripts/edit-secrets.sh"
    echo "2. Deploy with secrets: helm install joplin-server ./helm"
    echo "3. Store your age key securely: secrets/age-key.txt"
}

main "$@"