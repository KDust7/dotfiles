#!/usr/bin/env bash

echo "Dotfiles install.sh running..."

###############################################
# 1. Ensure needed dirs
###############################################
mkdir -p "$HOME/.devcontainer"
mkdir -p "$HOME/.tailscale"


###############################################
# 2. Install Bun
###############################################
if ! command -v bun >/dev/null 2>&1; then
  echo "[install.sh] Installing Bun..."
  curl -fsSL https://bun.sh/install | bash


fi

# Reload env so Bun is usable right away
source /home/codespace/.bashrc



###############################################
# 3. Install Tailscale (OFFICIAL command)
###############################################
if ! command -v tailscale >/dev/null 2>&1; then
  echo "[install.sh] Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi



###############################################
# 4. Generate devcontainer.json
###############################################
cat > "$HOME/.devcontainer/devcontainer.json" << 'EOF'
{
  "name": "Codespace",
  "postStartCommand": "/bin/bash .devcontainer/post-start.sh"
}
EOF



###############################################
# 5. Generate post-start.sh (runs every boot)
###############################################
cat > "$HOME/.devcontainer/post-start.sh" << 'EOF'
#!/usr/bin/env bash
set -e

echo "[post-start] Starting Tailscale..."

mkdir -p "$HOME/.tailscale"
pkill tailscaled 2>/dev/null || true
sleep 1

# Boot tailscaled
nohup tailscaled \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --state="$HOME/.tailscale/tailscaled.state" \
  --socket="$HOME/.tailscale/tailscaled.sock" \
  >> "$HOME/.tailscale/tailscaled.log" 2>&1 &

sleep 2

# Connect to Tailnet
tailscale --socket "$HOME/.tailscale/tailscaled.sock" up \
  --hostname "codespace-$(hostname)" \
  --operator "$USER" \
  2>&1 | tee "$HOME/.tailscale/tailscale-up.log" || true
EOF

chmod +x "$HOME/.devcontainer/post-start.sh"

echo "install.sh finished."
