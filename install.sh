#!/usr/bin/env bash

echo "Dotfiles install.sh running..."

mkdir -p ~/.config

### --- Install Bun ---
if ! command -v bun >/dev/null 2>&1; then
  echo "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
fi

# Ensure Bun PATH loads
if [ -f "$HOME/.bun/_bun" ]; then
  if ! grep -q 'source ~/.bun/_bun' "$HOME/.bashrc" 2>/dev/null; then
    echo 'source ~/.bun/_bun' >> "$HOME/.bashrc"
  fi
fi

# Reload shell
source /home/codespace/.bashrc


### --- Install Tailscale ---
if ! command -v tailscale >/dev/null 2>&1; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo "install.sh finished."
#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.codespaces/setup.log"
mkdir -p "$(dirname "$LOG")"
echo ">>> setup.sh start: $(date -Iseconds)" >> "$LOG"
echo ">>> env: SHELL=$SHELL, USER=$USER, HOME=$HOME" >> "$LOG"

# Force reload shell env (user asked for exact path)
if [ -f /home/codespace/.bashrc ]; then
  echo "Sourcing /home/codespace/.bashrc" >> "$LOG"
  # shellcheck disable=SC1090
  source /home/codespace/.bashrc || true
fi

# Ensure tailscale binary exists
if ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale NOT found in PATH. Aborting setup.sh. (install.sh should install it on create)" | tee -a "$LOG"
  echo ">>> setup.sh end: $(date -Iseconds)" >> "$LOG"
  exit 0
fi
echo "tailscale found: $(command -v tailscale)" >> "$LOG"

# Prepare writable state/socket dir
TS_DIR="$HOME/.tailscale"
mkdir -p "$TS_DIR"
echo "Using Tailscale state dir: $TS_DIR" >> "$LOG"

# Kill old tailscaled (if present)
pkill tailscaled 2>/dev/null || true
sleep 1

# Start tailscaled and capture its logs
TAILSCALED_LOG="$TS_DIR/tailscaled.log"
echo "Starting tailscaled..." | tee -a "$LOG" "$TAILSCALED_LOG"
nohup tailscaled \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --state="$TS_DIR/tailscaled.state" \
  --socket="$TS_DIR/tailscaled.sock" \
  >> "$TAILSCALED_LOG" 2>&1 &

# Give it a second to spin up
sleep 2

echo "tailscaled pid: $(pgrep -f tailscaled || echo none)" >> "$LOG"
echo "tailscaled recent log:" >> "$LOG"
tail -n 60 "$TAILSCALED_LOG" >> "$LOG" 2>/dev/null || true

# Try to bring interface up and capture output (prints URL if interactive)
UP_LOG="$TS_DIR/tailscale-up.log"
echo "Running tailscale up (socket=$TS_DIR/tailscaled.sock)..." | tee -a "$LOG" "$UP_LOG"
tailscale --socket "$TS_DIR/tailscaled.sock" up --hostname="codespace-$(hostname)" --operator="$USER" 2>&1 | tee -a "$UP_LOG" "$LOG" || true

echo "tailscale up finished. Last lines of up log:" >> "$LOG"
tail -n 100 "$UP_LOG" >> "$LOG" 2>/dev/null || true

# If the up command printed a login URL, it will be in the up log. Show last 50 lines to stdout so you can see it in the Codespaces terminal.
echo "---- tailscale up output (last 50 lines) ----"
tail -n 50 "$UP_LOG" || true
echo "---- tailscaled log (last 20 lines) ----"
tail -n 20 "$TAILSCALED_LOG" || true

echo ">>> setup.sh end: $(date -Iseconds)" >> "$LOG"
