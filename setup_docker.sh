#!/usr/bin/env bash
set -euo pipefail

IMAGE="ghcr.io/cuadvprog/ap-env:latest"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_wsl() {
  # WSL usually has "Microsoft" or "WSL" in /proc/version
  if [ -f /proc/version ]; then
    grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null
  else
    return 1
  fi
}

install_docker_macos() {
  echo "Docker CLI not found. Attempting to install Docker Desktop via Homebrew..."
  if ! command_exists brew; then
    echo "Homebrew is not installed."
    echo "Please install Homebrew from https://brew.sh and then re-run this script."
    exit 1
  fi

  brew install --cask docker

  echo
  echo "Docker Desktop has been installed."
  echo "IMPORTANT: You must now open the Docker app once (from Applications),"
  echo "wait until it says 'Docker is running', and then re-run this script."
  exit 0
}

install_docker_linux_or_wsl() {
  if is_wsl; then
    echo "Detected WSL (Windows Subsystem for Linux)."
    echo "Docker Desktop needs to be installed on Windows (not inside WSL)."

    if command_exists winget.exe; then
      echo "Found winget. Installing Docker Desktop on Windows..."
      winget.exe install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
      echo ""
      echo "Docker Desktop installed. Please:"
      echo "  1. Open Docker Desktop from the Windows Start menu"
      echo "  2. Wait until it says 'Docker is running'"
      echo "  3. In Settings > Resources > WSL Integration, enable your distro"
      echo "  4. Re-open this WSL terminal and re-run ./setup_docker.sh"
    else
      echo "winget not found. Please install Docker Desktop manually:"
      echo "  https://www.docker.com/products/docker-desktop/"
      echo ""
      echo "Then:"
      echo "  1. Open Docker Desktop and wait until it says 'Docker is running'"
      echo "  2. In Settings > Resources > WSL Integration, enable your distro"
      echo "  3. Re-open this WSL terminal and re-run ./setup_docker.sh"
    fi
    exit 0
  fi

  # Native Linux (not WSL)
  echo "Docker CLI not found. Attempting to install Docker Engine (Linux)..."
  echo "This requires sudo and will run Docker's convenience script from get.docker.com."
  echo "Press Ctrl+C within 5 seconds to abort."
  sleep 5

  if ! command_exists curl; then
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
  fi

  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"

  echo
  echo "Docker installed."
  echo "You may need to log out and log back in so group changes take effect."
  echo "Then re-run this script."
  exit 0
}

OS="$(uname -s)"

ensure_docker_running() {
  # If docker info works, daemon is reachable
  if docker info >/dev/null 2>&1; then
    return 0
  fi

  echo "Docker CLI is installed, but the daemon does not seem to be running."

  case "$OS" in
    Darwin)
      echo "Attempting to start Docker Desktop..."
      # Try to start Docker.app in the background (no error if it already runs)
      open -g -a Docker || true

      echo "Waiting for Docker Desktop to start..."
      # Wait up to ~60 seconds
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
        echo "Please:"
        echo "  1. Open Docker Desktop from the Windows Start menu"
        echo "  2. Wait until it says 'Docker is running'"
        echo "  3. Re-run ./setup_docker.sh"
        exit 1
      fi

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

    *)
      echo "Unsupported OS: $OS"
      echo "Docker is installed but not running. Please start Docker manually and rerun this script."
      exit 1
      ;;
  esac
}

# 1. Check for docker, install if missing
if ! command_exists docker; then
  case "$OS" in
    Darwin)
      install_docker_macos
      ;;
    Linux)
      install_docker_linux_or_wsl
      ;;
    *)
      echo "Unsupported OS: $OS"
      echo "Please install Docker manually from https://docs.docker.com/get-docker/"
      exit 1
      ;;
  esac
fi

# Detect native platform
ARCH="$(uname -m)"
case "$ARCH" in
  arm64|aarch64)
    PLATFORM="linux/arm64"
    ;;
  *)
    PLATFORM="linux/amd64"
    ;;
esac

# 2. Make sure the daemon is actually running
ensure_docker_running

echo "Docker is installed and running. Pulling course image: $IMAGE"
if docker pull "$IMAGE"; then
  # Make run script executable and launch it
  chmod +x "$(dirname "$0")/run_docker.sh"
  exec "$(dirname "$0")/run_docker.sh"
else
  echo "Failed to pull image. Please check your internet connection and try again."
  exit 1
fi
