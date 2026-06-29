#!/usr/bin/env bash
# Override REPO_URL / DOTFILES_PATH / HOST to customize.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/romaingrx/dotfiles.git}"
DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"
HOST="${HOST:-$(hostname -s)}"

log() { printf '\033[0;32m[install]\033[0m %s\n' "$*"; }
err() { printf '\033[0;31m[install]\033[0m %s\n' "$*" >&2; }

# sops needs the age key present to decrypt secrets during the switch; fail early
# with a clear message instead of a cryptic mid-activation error.
AGE_KEY="$HOME/.config/sops/age/keys.txt"
if [ ! -f "$AGE_KEY" ]; then
  err "Missing sops age key at $AGE_KEY."
  err "Copy it from another host (chmod 600) before bootstrapping — see docs/new-host-setup.md."
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  log "Nix not found; installing via Determinate Systems installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if [ ! -d "$DOTFILES_PATH/.git" ]; then
  log "Cloning $REPO_URL into $DOTFILES_PATH..."
  # Use nix-provided git so a fresh Mac needs no Xcode Command Line Tools.
  nix run nixpkgs#git -- clone "$REPO_URL" "$DOTFILES_PATH"
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
log "Manual follow-ups: grant Accessibility + Screen Recording when prompted (aerospace, sketchybar, jankyborders); set your default browser; install claude-code."
