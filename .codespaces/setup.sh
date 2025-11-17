#!/usr/bin/env bash

# Reload env so Bun/Tailscale PATH works
source /home/codespace/.bashrc

mkdir -p ~/.tailscale

# Stop old instance
pkill tailscaled 2>/dev/null || true

# Start new instance
tailscaled \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --state=$HOME/.tailscale/tailscaled.state \
  --socket=$HOME/.tailscale/tailscaled.sock &

sleep 1

# Bring up interface (no auth key = prints a URL)
tailscale \
  --socket=$HOME/.tailscale/tailscaled.sock \
  up --hostname=codespace-$(hostname) --operator=$USER
