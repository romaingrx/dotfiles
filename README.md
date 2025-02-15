[![nixfmt](https://github.com/romaingrx/dotfiles/actions/workflows/nixfmt.yml/badge.svg)](https://github.com/romaingrx/dotfiles/actions/workflows/nixfmt.yml)
[![build](https://github.com/romaingrx/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/romaingrx/dotfiles/actions/workflows/build.yml)

> My dotfiles for MacOS and Linux using Nix, home-manager, and nix-darwin.

>[!Warning]
> Note that this configuration is actively evolving. While functional, some components are still being refined and optimized to ensure the best possible implementation.

## Overview

This repository contains my system configurations managed through Nix. It supports both MacOS (via nix-darwin) and Linux (NixOS) systems, with a focus on maintaining a consistent development environment across different machines.

## Repository Structure

```
.
├── assets/          # Assets like wallpapers and images
├── hosts/           # Host-specific configurations (e.g. nixos, darwin)
├── lib/             # Helper functions and utilities
├── modules/         # Shared configuration modules
│   └── core/        # Core configuration shared across systems
├── overlays/        # Nix package overlays
└── users/           # User-specific configurations
```

## Key Components

- **Flake-based**: Uses Nix flakes for reproducible builds and dependencies
- **Multi-user**: Supports different user configurations on the same machine
- **Cross-platform**: Works on both MacOS (via nix-darwin) and Linux (NixOS)
- **Modular**: Configurations are split into reusable modules

## Supported Systems

- **MacOS (aarch64-darwin)**
  - Primary configuration for `goddard` machine
  - Supports multiple users (romaingrx, lcmd)
  
- **Linux (x86_64-linux)**
  - NixOS configuration for `carl` machine

## Known Issues and Limitations

### MacOS (Darwin)
- **Homebrew Multi-user Support**: The current implementation doesn't handle Homebrew packages well in a multi-user setup. Package management and sharing between users needs improvement.
- **Package Sharing**: Limited capability for sharing packages between users in the Darwin setup, especially around `sketchybar`.

## Documentation

>[!Note]
> In progress.