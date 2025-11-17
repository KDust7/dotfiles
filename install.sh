#!/usr/bin/env bash

echo "Dotfiles install.sh running..."

# --- Ensure folders exist ---
mkdir -p "$HOME/.codespaces"
mkdir -p "$HOME/.tailscale"

# --- Install Bun if missing ---
if ! command -v bun >/dev/null 2>&1; then
  echo "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash

  # Make sure Bun loads each session
  if ! grep -q 'source ~/.bun/_bun' "$HOME/.bashrc" 2>/dev/null; then
    echo 'source ~/.bun/_bun' >> "$HOME/.bashrc"
  fi
fi

# 🔥 Force reload bashrc NOW
source /home/codespace/.bashrc

# --- Write setup script for Tailscale autostart ---
SETUP_FILE="$HOME/.codespaces/setup.sh"

cat > "$SETUP_FILE" << 'EOF'
#!/usr/bin/env bash
set -e

echo ">>> Starting Tailscale (setup.sh)..."

mkdir -p "$HOME/.tailscale"
pkill tailscaled 2>/dev/null || true
sleep 1

nohup tailscaled \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --state="$HOME/.tailscale/tailscaled.state" \
  --socket="$HOME/.tailscale/tailscaled.sock" \
  >> "$HOME/.tailscale/tailscaled.log" 2>&1 &

sleep 2

tailscale --socket "$HOME/.tailscale/tailscaled.sock" up \
   --hostname "codespace-$(hostname)" \
   --operator "$USER" \
   2>&1 | tee "$HOME/.tailscale/tailscale-up.log" || true
EOF

chmod +x "$SETUP_FILE"

echo "Created $SETUP_FILE"
echo "install.sh finished."
