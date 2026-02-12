#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSH_PLUGINS_DIR="$HOME/.zsh/plugins"

# --- system packages ---
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
  tmux \
  fzf \
  zsh

# --- tmux ---
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || true
ln -sf "$DOTFILES_DIR/config/tmux/tmux.conf" ~/.tmux.conf
~/.tmux/plugins/tpm/bin/install_plugins || true

# --- zsh plugins ---
mkdir -p "$ZSH_PLUGINS_DIR"
git clone --depth 1 https://github.com/jeffreytse/zsh-vi-mode.git "$ZSH_PLUGINS_DIR/zsh-vi-mode" 2>/dev/null || true
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" 2>/dev/null || true
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_PLUGINS_DIR/zsh-autosuggestions" 2>/dev/null || true
git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$ZSH_PLUGINS_DIR/powerlevel10k" 2>/dev/null || true

# --- zsh config ---
cat > ~/.zshrc << ZSHEOF
# Plugins
source "$ZSH_PLUGINS_DIR/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$ZSH_PLUGINS_DIR/powerlevel10k/powerlevel10k.zsh-theme"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Shared config
source "$DOTFILES_DIR/config/zsh/zshrc"
ZSHEOF

# --- lazygit ---
LAZYGIT_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4 | sed 's/^v//')
curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" -o /tmp/lazygit.tar.gz
sudo tar xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
rm -f /tmp/lazygit.tar.gz

# --- neovim ---
NVIM_VERSION=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" -o /tmp/nvim.tar.gz
sudo tar xzf /tmp/nvim.tar.gz -C /usr/local --strip-components=1
rm -f /tmp/nvim.tar.gz
mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/config/nvim" ~/.config/nvim

# --- set default shell to zsh ---
sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || true
