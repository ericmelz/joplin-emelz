#!/bin/bash

set -euo pipefail

if [ -z "${PG_PASSWORD:-}" ]; then
    echo "❌ Environment variable POSTGREG_PASSWORD must be set before running make k3d.  Example:"
    echo "  export POSTGRESG_PASSWORD=s3cr3t! && make k3d"
    exit 1
fi
  

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

echo "Deploying resources to k3d..."
helm upgrade --install joplin-emelz ./helm --set postgresPassword=${POSTGRES_PASSWORD}
