#!/usr/bin/env bash
# Dev container bootstrap: installs single-user Nix, then applies the
# `devcontainer` home-manager profile from this checkout.
set -euo pipefail

export DOTFILES="$(cd "$(dirname "$0")" && pwd)"
export NIX_CONFIG="experimental-features = nix-command flakes"

if ! command -v nix >/dev/null; then
  curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon
fi
nix_profile="$HOME/.nix-profile/etc/profile.d/nix.sh"
# shellcheck disable=SC1090
[ -e "$nix_profile" ] && . "$nix_profile"

# --impure: the profile reads $USER, $HOME and $DOTFILES.
nix run "$DOTFILES#home-manager" -- switch --impure -b bckp --flake "$DOTFILES#devcontainer"

sudo chsh -s "$HOME/.nix-profile/bin/zsh" "$USER" 2>/dev/null || true
