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
  # Install upstream (vanilla) Nix so nix-darwin can manage the Nix installation
  # itself. Do NOT use the Determinate installer here: its daemon makes
  # nix-darwin abort activation ("Determinate detected"), and as of 2026 it no
  # longer offers an upstream-Nix option. The official installer prompts once
  # for confirmation (read from /dev/tty) and for your sudo password.
  log "Nix not found; installing upstream Nix (multi-user)..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://nixos.org/nix/install \
    | sh -s -- --daemon --no-channel-add
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
    # nix-darwin insists on owning several /etc files, but on a fresh machine the
    # upstream Nix installer already created them, so nix-darwin aborts
    # ("Unexpected files in /etc") rather than clobber them. Move its managed
    # files aside once — nix-darwin regenerates them. Idempotent via the guard;
    # if a future nix-darwin flags more files, add them here.
    for f in /etc/nix/nix.conf /etc/bashrc /etc/zshrc; do
      if [ -e "$f" ] && [ ! -e "$f.before-nix-darwin" ]; then
        sudo mv "$f" "$f.before-nix-darwin"
      fi
    done
    # The switch below, annotated:
    #   "$(command -v nix)"          absolute path — sudo's reduced PATH may not
    #                                expose a freshly installed `nix`.
    #   --extra-experimental-features  we just moved /etc/nix/nix.conf aside, so
    #                                the outer `nix run` can't read nix-command/
    #                                flakes from it (darwin-rebuild sets these
    #                                itself for its inner build).
    #   --option extra-substituters  bootstrap chicken-and-egg — our binary cache
    #                                (modules/cachix.nix) isn't in the daemon's
    #                                nix.conf until the first activation succeeds,
    #                                so hand it to this first build. Honored:
    #                                darwin-rebuild forwards --option and we run
    #                                as root (trusted). Keep the URL/key in sync
    #                                with modules/cachix.nix.
    sudo "$(command -v nix)" run --extra-experimental-features "nix-command flakes" \
      github:LnL7/nix-darwin -- switch --flake "path:.#$HOST" \
      --option extra-substituters "https://romaingrx-dotfiles.cachix.org" \
      --option extra-trusted-public-keys "romaingrx-dotfiles.cachix.org-1:8fwAzNpph5XT2vgLrEFXBKYxUPeaWdfeaGu5AUNkQDc="
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
