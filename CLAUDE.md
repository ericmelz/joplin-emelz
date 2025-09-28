# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Kubernetes infrastructure project for deploying a Joplin notes server using k3d for local development. The project provides both direct Kubernetes manifests and Helm chart deployment options.

## Commands

### Cluster Management
- `make k3d` - Create k3d cluster named "joplin" with port forwarding (22300:22300)
- `make destroy-k3d` - Destroy k3d cluster (NOTE: destroys cluster named "dev", inconsistent with creation)

### Manual Cluster Commands
- `bash scripts/k3d.sh` - Create cluster directly
- `bash scripts/destroy-k3d.sh` - Destroy cluster directly

### Deployment Options

**Option 1: Direct Kubernetes manifests**
```bash
kubectl apply -f k8s/k3d-manifests/all-in-one.yaml
```

**Option 2: Helm deployment** (requires creating values.yaml first)
```bash
helm install joplin-server ./helm
```

## Architecture

### Core Components
- **Joplin Server**: Containerized note-taking server (joplin/server:latest)
- **k3d Cluster**: Local Kubernetes development environment
- **Persistent Storage**: HostPath volumes for data persistence
- **External Dependencies**: PostgreSQL database, JWT secrets

### Directory Structure
- `k8s/k3d-manifests/` - Direct Kubernetes YAML files
- `helm/` - Helm chart templates and configuration
- `scripts/` - Cluster management scripts

### Storage Configuration
The application expects these local directories:
- `/Users/ericmelz/Data/var/joplin-server/data` - Joplin application data
- `/Users/ericmelz/Data/secrets/.jwt_secret` - JWT secret file

## Known Issues

1. **Cluster naming inconsistency**: Creation script uses "joplin" cluster name but destruction script uses "dev"
2. **Missing Helm values**: Helm templates reference `.Values` but no values.yaml file exists
3. **Template syntax errors**: Secret template in helm/templates/secret.yaml has malformed Go template syntax
4. **Missing variable definition**: `CLUSTER_LIST` variable is referenced but not defined in k3d.sh

## Configuration

### Required Environment Variables (for direct deployment)
- `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DATABASE`
- `POSTGRES_USER`, `POSTGRES_PASSWORD`
- `JWT_SECRET_FILE` (points to mounted secret file)

### Service Access
- Joplin server runs on port 22300
- Accessible at `localhost:22300` when k3d cluster is running

## Development Workflow

1. Ensure local storage directories exist
2. Create k3d cluster: `make k3d`
3. Deploy application using preferred method
4. Access Joplin at `localhost:22300`
5. Clean up: `make destroy-k3d`