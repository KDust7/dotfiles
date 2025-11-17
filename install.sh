#!/usr/bin/env bash

echo "Dotfiles install.sh running..."

mkdir -p ~/.config

# Install Bun if not installed
if ! command -v bun >/dev/null 2>&1; then
  echo "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
fi

# Make sure ~/.bashrc sources Bun's env
if [ -f "$HOME/.bun/_bun" ]; then
  if ! grep -q 'source ~/.bun/_bun' "$HOME/.bashrc" 2>/dev/null; then
    echo 'source ~/.bun/_bun' >> "$HOME/.bashrc"
  fi
fi

# 🔥 Force the Codespace shell to pick up all new PATH updates
echo "Reloading shell environment..."
source /home/codespace/.bashrc

echo "install.sh finished."
