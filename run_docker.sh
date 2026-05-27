#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="cs3157"
IMAGE="ghcr.io/cs3157-borowski/ap-env:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ARCH="$(uname -m)"
case "$ARCH" in
  arm64|aarch64) PLATFORM="linux/arm64" ;;
  *)             PLATFORM="linux/amd64" ;;
esac

print_banner() {
  printf '\033[1;33m\n'
  printf '  ╔══════════════════════════════════════════════════════════════════╗\n'
  printf '  ║                                                                  ║\n'
  printf '  ║                       !! IMPORTANT !!                            ║\n'
  printf '  ║                                                                  ║\n'
  printf '  ║   Always save your work inside /ap                               ║\n'
  printf '  ║                                                                  ║\n'
  printf '  ║   /ap is shared with your computer - files there are safe.       ║\n'
  printf '  ║   Files saved OUTSIDE /ap will be LOST if the container          ║\n'
  printf '  ║   is ever recreated (e.g., after a course image update).         ║\n'
  printf '  ║                                                                  ║\n'
  printf '  ╚══════════════════════════════════════════════════════════════════╝\n'
  printf '\033[0m\n'
}

# Check for image updates (fast no-op if already up to date)
echo "Checking for course image updates..."
OLD_DIGEST=$(docker image inspect "$IMAGE" --format '{{index .RepoDigests 0}}' 2>/dev/null || echo "none")
docker pull --quiet "$IMAGE"
NEW_DIGEST=$(docker image inspect "$IMAGE" --format '{{index .RepoDigests 0}}' 2>/dev/null || echo "none")

IMAGE_UPDATED=false
if [ "$OLD_DIGEST" != "$NEW_DIGEST" ]; then
  IMAGE_UPDATED=true
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  if [ "$IMAGE_UPDATED" = true ]; then
    echo ""
    echo "A new version of the course image is available."
    echo ""
    echo "  Files inside /ap are stored on your computer and will NOT be lost."
    echo "  Files saved OUTSIDE /ap (e.g. in ~ or /root) will be lost."
    echo ""
    read -rp "Recreate container with the new image? [y/N] " reply
    echo
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      docker rm "$CONTAINER_NAME"
    else
      echo "Keeping existing container."
      print_banner
      docker start -ai "$CONTAINER_NAME"
      exit 0
    fi
  else
    echo "Container '$CONTAINER_NAME' found. Resuming..."
    print_banner
    docker start -ai "$CONTAINER_NAME"
    exit 0
  fi
fi

echo "Creating new container '$CONTAINER_NAME'..."
echo "Shared folder: $SCRIPT_DIR <-> /ap (inside container)"
print_banner
docker run -it \
  --platform="$PLATFORM" \
  --cpus="4" \
  --memory="4g" \
  --name "$CONTAINER_NAME" \
  -v "$SCRIPT_DIR:/ap" \
  "$IMAGE" \
  /bin/bash
