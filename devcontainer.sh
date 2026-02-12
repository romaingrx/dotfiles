#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- tmux ---
sudo apt-get update && sudo apt-get install -y --no-install-recommends tmux
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || true
ln -sf "$DOTFILES_DIR/config/tmux/tmux.conf" ~/.tmux.conf
~/.tmux/plugins/tpm/bin/install_plugins || true

# --- neovim ---
NVIM_VERSION=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" -o /tmp/nvim.tar.gz
sudo tar xzf /tmp/nvim.tar.gz -C /usr/local --strip-components=1
rm -f /tmp/nvim.tar.gz
mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/config/nvim" ~/.config/nvim

# --- shell ---
echo 'export EDITOR=nvim' >> ~/.bashrc
echo 'export EDITOR=nvim' >> ~/.zshrc 2>/dev/null || true
