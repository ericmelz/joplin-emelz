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
      -p "22300:22300@loadbalancer"
fi
