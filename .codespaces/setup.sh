#!/usr/bin/env bash

# Install Tailscale if missing
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

mkdir -p ~/.tailscale

# Kill old instance (Codespaces sometimes reuse containers)
pkill tailscaled 2>/dev/null || true

# Start daemon in userspace mode
tailscaled \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --state=~/.tailscale/tailscaled.state \
  --socket=~/.tailscale/tailscaled.sock &

sleep 1

# Bring up Tailscale (no authkey = prints login URL)
tailscale --socket ~/.tailscale/tailscaled.sock up \
  --hostname=codespace-$(hostname) \
  --operator=$USER
