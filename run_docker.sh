#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="cs3157"
IMAGE="ghcr.io/cuadvprog/ap-env:latest"

ARCH="$(uname -m)"
case "$ARCH" in
  arm64|aarch64) PLATFORM="linux/arm64" ;;
  *)             PLATFORM="linux/amd64" ;;
esac

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container '$CONTAINER_NAME' found. Resuming..."
  docker start -ai "$CONTAINER_NAME"
else
  echo "Creating new container '$CONTAINER_NAME'..."
  docker run -it \
    --platform="$PLATFORM" \
    --cpus="4" \
    --memory="4g" \
    --name "$CONTAINER_NAME" \
    "$IMAGE" \
    /bin/bash
fi
