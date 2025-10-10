#!/bin/bash

set -euo pipefail

CLUSTER_NAME="joplin"

VAR_DIR="$HOME/Data/var"

echo "CLUSTER_NAME=$CLUSTER_NAME"

CLUSTER_LIST=$(k3d cluster list)

if echo $CLUSTER_LIST | grep -q "$CLUSTER_NAME"; then
  echo "Cluster '$CLUSTER_NAME' already exists.  Skipping creation"
else
  echo "Creating cluster '$CLUSTER_NAME' using project-specific config..."
  k3d cluster create "$CLUSTER_NAME" \
      -p "22300:22300@loadbalancer" \
      --volume "$VAR_DIR:/mnt/var@server:0"
fi

echo "✅ k3d cluster '$CLUSTER_NAME' is ready!"
echo ""
echo "Next steps:"
echo "  1. Deploy with encrypted secrets: ./scripts/deploy.sh"
echo "  2. Or use legacy method: helm install joplin-server ./helm"
