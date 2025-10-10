#!/bin/bash

set -euo pipefail

CLUSTER_NAME="joplin"

k3d cluster delete $CLUSTER_NAME
