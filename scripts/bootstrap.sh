#!/usr/bin/env bash
# Bootstrap a fresh machine into this dotfiles configuration.
# Idempotent: safe to re-run after partial failures.
#
# Override defaults via env vars:
#   REPO_URL=git@github.com:romaingrx/dotfiles.git
#   DOTFILES_PATH=$HOME/code/dotfiles
#   HOST=goddard       # bypass hostname detection
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/romaingrx/dotfiles.git}"
DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"
HOST="${HOST:-$(hostname -s)}"

log() { printf '\033[0;32m[bootstrap]\033[0m %s\n' "$*"; }
err() { printf '\033[0;31m[bootstrap]\033[0m %s\n' "$*" >&2; }

if ! command -v nix >/dev/null 2>&1; then
  log "Nix not found; installing via Determinate Systems installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if [ ! -d "$DOTFILES_PATH/.git" ]; then
  log "Cloning $REPO_URL into $DOTFILES_PATH..."
  git clone "$REPO_URL" "$DOTFILES_PATH"
fi

cd "$DOTFILES_PATH"

case "$(uname -s)" in
  Darwin)
    log "Activating darwinConfigurations.$HOST..."
    sudo nix run github:LnL7/nix-darwin -- switch --flake "path:.#$HOST"
    ;;
  Linux)
    log "Activating nixosConfigurations.$HOST..."
    sudo nixos-rebuild switch --flake "path:.#$HOST"
    ;;
  *)
    err "Unsupported OS: $(uname -s)"
    exit 1
    ;;
esac

log "Done. Open a new shell to pick up the home-manager environment."
