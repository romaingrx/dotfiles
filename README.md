[![check](https://github.com/romaingrx/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/romaingrx/dotfiles/actions/workflows/check.yml)
[![build](https://github.com/romaingrx/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/romaingrx/dotfiles/actions/workflows/build.yml)

> My dotfiles for macOS and Linux using Nix, home-manager, and nix-darwin.

> [!Warning]
> Note that this configuration is actively evolving. While functional, some components are still being refined and optimized to ensure the best possible implementation.

## Overview

This repository contains my system configurations managed through Nix. It supports both macOS (via nix-darwin) and Linux (NixOS), with a focus on maintaining a consistent development environment across different machines.

## Repository Structure

```
.
├── assets/          # Assets like wallpapers and images
├── config/          # Application configuration linked by home-manager
├── hosts/           # Host-specific configurations (e.g. nixos, darwin)
├── lib/             # Helper functions and utilities
├── modules/         # Shared configuration modules
├── overlays/        # Nix package overlays
├── scripts/         # Bootstrap and helper scripts
└── users/           # User-specific configurations
```

## Key Components

- **Flake-based**: Uses Nix flakes for reproducible builds and dependencies
- **Multi-user**: Supports different user configurations on the same machine
- **Cross-platform**: Works on both MacOS (via nix-darwin) and Linux (NixOS)
- **Modular**: Configurations are split into reusable modules

## Supported Systems

- **macOS (aarch64-darwin)**
  - Primary configuration for `goddard` machine
  
- **Linux (x86_64-linux)**
  - NixOS configuration for `carl` machine

## Common Commands

```sh
nix develop
nix fmt
nix flake check
```

Bootstrap a fresh machine (installs Nix, clones to `~/.dotfiles`, switches):

```sh
curl -fsSL https://raw.githubusercontent.com/romaingrx/dotfiles/main/scripts/bootstrap.sh | bash
```

See [docs/new-host-setup.md](docs/new-host-setup.md) for the manual prerequisites (the sops age key, plus a couple of permission grants).

## Known Issues and Limitations

### macOS (Darwin)
- **Homebrew Multi-user Support**: The current implementation doesn't handle Homebrew packages well in a multi-user setup. Package management and sharing between users needs improvement.
- **Package Sharing**: Limited capability for sharing packages between users in the Darwin setup, especially around `sketchybar`.

## Documentation

> [!Note]
> In progress.
