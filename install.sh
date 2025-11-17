#!/usr/bin/env bash

echo "Dotfiles install.sh running..."

# --- Ensure dirs ---
mkdir -p "$HOME/.devcontainer"
mkdir -p "$HOME/.tailscale"

###############################################
# 1. Install Bun
###############################################
if ! command -v bun >/dev/null 2>&1; then
  echo "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash

 
fi

# 🔥 Reload environment now
source /home/codespace/.bashrc


###############################################
# 2. Write .devcontainer/devcontainer.json
###############################################
cat > "$HOME/.devcontainer/devcontainer.json" << 'EOF'
{
  "name": "Codespace",
  "postStartCommand": "/bin/bash .devcontainer/post-start.sh"
}
EOF


###############################################
# 3. Write post-start.sh (runs EVERY boot)
###############################################
cat > "$HOME/.devcontainer/post-start.sh" << 'EOF'
#!/usr/bin/env bash
set -e

echo "[post-start] running..."

mkdir -p "$HOME/.tailscale"
pkill tailscaled 2>/dev/null || true
sleep 1

# Start tailscaled
nohup tailscaled \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --state="$HOME/.tailscale/tailscaled.state" \
  --socket="$HOME/.tailscale/tailscaled.sock" \
  >> "$HOME/.tailscale/tailscaled.log" 2>&1 &

sleep 2

# Try to bring up Tailscale
tailscale --socket "$HOME/.tailscale/tailscaled.sock" up \
  --hostname "codespace-$(hostname)" \
  --operator "$USER" \
  2>&1 | tee "$HOME/.tailscale/tailscale-up.log" || true
EOF

chmod +x "$HOME/.devcontainer/post-start.sh"

echo "Wrote .devcontainer/devcontainer.json and post-start.sh"
echo "install.sh finished."
