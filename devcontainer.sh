#!/usr/bin/env bash
# Installs single-user Nix unless a Nix is already there, then applies a standalone home-manager profile.
# Usage: ./devcontainer.sh [devcontainer|devbox|devbox-sre]
set -euo pipefail

profile="${1:-devcontainer}"

export DOTFILES="$(cd "$(dirname "$0")" && pwd)"
export NIX_CONFIG="experimental-features = nix-command flakes"

daemon_profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
# shellcheck disable=SC1090
[ -e "$daemon_profile" ] && . "$daemon_profile"

if ! command -v nix >/dev/null; then
  curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon
fi
nix_profile="$HOME/.nix-profile/etc/profile.d/nix.sh"
# shellcheck disable=SC1090
[ -e "$nix_profile" ] && . "$nix_profile"

# --impure: the profile reads $USER, $HOME and $DOTFILES.
HOME_MANAGER_BACKUP_EXT=bckp "$(nix build --impure --no-link --print-out-paths "$DOTFILES#$profile")/activate"

sudo -n chsh -s "$HOME/.nix-profile/bin/zsh" "$USER" 2>/dev/null || true
