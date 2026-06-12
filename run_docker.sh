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

OS="$(uname -s)"

ensure_docker_running() {
  if docker info >/dev/null 2>&1; then
    return 0
  fi

  echo "Docker CLI is installed, but the daemon does not seem to be running."

  case "$OS" in
    Darwin)
      echo "Attempting to start Docker Desktop..."
      open -g -a Docker || true

      echo "Waiting for Docker Desktop to start..."
      for i in {1..30}; do
        if docker info >/dev/null 2>&1; then
          echo "Docker is now running."
          return 0
        fi
        sleep 2
      done

      echo "Docker Desktop is still not responding."
      echo "Please open the 'Docker' app from Applications manually,"
      echo "wait until it says 'Docker is running', and then re-run this script."
      exit 1
      ;;

Linux)
      if is_wsl; then
        echo "Docker Desktop does not appear to be running on Windows."
        echo "Attempting to start Docker Desktop..."
        powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'" 2>/dev/null || true

        echo "Waiting for Docker Desktop to start (this may take ~30 seconds)..."
        for i in {1..30}; do
          if docker info >/dev/null 2>&1; then
            echo "Docker is now running."
            return 0
          fi
          sleep 2
        done

        echo "Docker Desktop is still not responding."
        echo "Please open Docker Desktop from the Windows Start menu manually,"
        echo "wait until it says 'Docker is running', and then re-run ./setup_docker.sh"
        exit 1
      fi

      # Native Linux (not WSL)
      echo "Attempting to start Docker service on Linux..."
      if command_exists systemctl; then
        sudo systemctl start docker || true
      else
        sudo service docker start || true
      fi

      if docker info >/dev/null 2>&1; then
        echo "Docker service started."
        return 0
      fi

      echo "Could not start Docker automatically."
      echo "Please start Docker manually (for example: 'sudo systemctl start docker')"
      echo "and then re-run this script."
      exit 1
      ;;
        esac
}

# Make sure the daemon is actually running
ensure_docker_running

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

# Check for image updates
OLD_DIGEST=$(docker image inspect "$IMAGE" --format '{{index .RepoDigests 0}}' 2>/dev/null || echo "none")

# Call our custom module for the pull progress bar
bash "$SCRIPT_DIR/modules/docker_pull_progress.sh" "$IMAGE"

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
