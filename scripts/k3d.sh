#!/bin/bash

set -euo pipefail

CLUSTER_NAME="dev"

VAR_DIR="$HOME/Data/var"
#set -x
echo "CLUSTER_NAME=$CLUSTER_NAME"

if echo $CLUSTER_LIST | grep -q "$CLUSTER_NAME"; then
  echo "Cluster '$CLUSTER_NAME' already exists.  Skipping creation"
else
  echo "Creating cluster '$CLUSTER_NAME' using project-specific config..."
  #  k3d cluster create "$CLUSTER_NAME" --config k8s-k3d/config.yaml \
  k3d cluster create "$CLUSTER_NAME" \
      -p "8880:80@loadbalancer" \
      --volume "$VAR_DIR:/mnt/var@server:0"

  # This is a bug that I don't have a better solution for fixing...
#  echo "Fixing ~/.kube/config"
#  sed -i '' 's|server: https://host.docker.internal|server: https://127.0.0.1|g' ~/.kube/config

fi
