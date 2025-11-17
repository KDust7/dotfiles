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
