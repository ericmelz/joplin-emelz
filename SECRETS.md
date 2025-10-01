# Encrypted Secrets Management

This project uses **SOPS** (Secrets OPerationS) with **age** encryption to manage sensitive configuration data using the "ConfigMap with encrypted values" pattern.

## Overview

Instead of storing secrets in plain text or using complex secret management systems, we:
1. **Encrypt secrets** with SOPS and age
2. **Store encrypted files** in git (safe to commit)
3. **Decrypt at deployment time** and inject into Kubernetes ConfigMaps
4. **Mount ConfigMaps** as files in containers

## Prerequisites

Install required tools:
```bash
# macOS
brew install sops age

# Ubuntu/Debian
sudo apt install age
# Install sops from GitHub releases
```

## Setup

**1. Initialize encrypted secrets:**
```bash
./scripts/setup-secrets.sh
```

This will:
- Generate an age encryption key
- Create `.sops.yaml` configuration
- Create initial `secrets/secrets.yaml` with a JWT secret
- Update `.gitignore` to protect the private key

**2. Edit secrets:**
```bash
./scripts/edit-secrets.sh
```

**3. Deploy with encrypted secrets:**
```bash
./scripts/deploy.sh
```

## File Structure

```
secrets/
├── age-key.txt          # Private key (NEVER commit this!)
├── secrets.yaml         # Encrypted secrets (safe to commit)
└── .gitkeep

.sops.yaml              # SOPS configuration
scripts/
├── setup-secrets.sh    # Initial setup
├── edit-secrets.sh     # Edit encrypted secrets
├── decrypt-secrets.sh  # Decrypt for scripts/debugging
└── deploy.sh          # Deploy with decryption
```

## Security Benefits

✅ **Encrypted at rest**: Secrets are encrypted in git
✅ **Key separation**: Private keys stored separately
✅ **Audit trail**: Git tracks all secret changes
✅ **No plain text**: Secrets never stored unencrypted
✅ **Simple deployment**: One command deploys with secrets

## Usage Examples

**View decrypted secrets:**
```bash
# View all secrets
./scripts/decrypt-secrets.sh --yaml

# Get specific secret
./scripts/decrypt-secrets.sh --key jwtSecret

# Export as environment variables
eval "$(./scripts/decrypt-secrets.sh --env)"
```

**Deploy to different environments:**
```bash
# Deploy to staging
./scripts/deploy.sh --namespace joplin-staging joplin-staging

# Upgrade production
./scripts/deploy.sh --upgrade --namespace production joplin-prod

# Dry run
./scripts/deploy.sh --dry-run
```

## Key Management

**⚠️ Important**: The age private key (`secrets/age-key.txt`) is critical:
- **Backup securely** (password manager, encrypted drive, etc.)
- **Never commit to git** (already in .gitignore)
- **Share securely** with team members who need access
- **Rotate periodically** for security

**To share with team members:**
1. Give them the age private key securely
2. They place it in `secrets/age-key.txt`
3. They can now decrypt and edit secrets

## Migration from PVC Pattern

The old JWT secret was stored in a PersistentVolume. This new approach:
- ✅ **Eliminates host path dependencies**
- ✅ **Works in any Kubernetes cluster**
- ✅ **Supports multiple secrets easily**
- ✅ **Enables git-based secret management**
- ✅ **Simplifies backup/restore**

## Troubleshooting

**"age key not found" error:**
```bash
# Ensure age key exists
ls -la secrets/age-key.txt
# Re-run setup if missing
./scripts/setup-secrets.sh
```

**"sops command not found":**
```bash
# Install sops
brew install sops  # macOS
```

**Cannot decrypt secrets:**
```bash
# Check SOPS configuration
cat .sops.yaml
# Verify age key matches
head -1 secrets/age-key.txt
```