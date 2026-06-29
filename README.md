[![check](https://github.com/romaingrx/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/romaingrx/dotfiles/actions/workflows/check.yml) [![build](https://github.com/romaingrx/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/romaingrx/dotfiles/actions/workflows/build.yml)

> macOS + Linux dotfiles on Nix — nix-darwin, home-manager, and NixOS.

## Install

```sh
curl -fsSL https://romaingrx.com/dotfiles/install.sh | bash
```

Installs Nix, clones to `~/.dotfiles`, and activates the host (`HOST=<name>` to pick a config; defaults to the hostname). The only secret you carry over is the sops age key — see [docs/new-host-setup.md](docs/new-host-setup.md).

## Features

- **One flake, many hosts.** A shared base with thin per-host overrides drives macOS (`goddard`, `brobot`, via nix-darwin) and NixOS (`carl`) alike — a new host is one flake entry plus an optional override file.
- **Declarative end to end.** Packages, macOS defaults, fonts, and the handful of Homebrew casks Nix can't own all come from the flake — no manual install steps.
- **One key for every secret.** A single sops age key decrypts the GPG and SSH keys at activation; nothing else is copied onto a new machine.
- **Theming that follows the system.** A light/dark theme contract drives the terminal, sketchybar, and the rest, switching automatically with macOS appearance.
- **Reproducible and self-maintaining.** Inputs are pinned in `flake.lock` and refreshed in lockstep by Renovate; CI evaluates and builds every host on each PR.

## Develop

```sh
nix develop          # dev shell: nixfmt, deadnix, statix, pre-commit
nix flake check      # eval + lint every host
nix fmt
```

`hosts/` per-host · `modules/` shared · `users/` · `overlays/` · `config/` app configs · `lib/` · `scripts/`
