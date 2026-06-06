# Theme Inventory

This document tracks places where this repository currently defines theme,
style, color, appearance, font, wallpaper, or cursor decisions. It is the
baseline for the incremental centralized theme migration.

## Current Source Of Truth

- Home Manager writes the runtime path contract to
  `~/.config/romaingrx/theme/paths.env`; the theme scripts source this file when
  present and fall back to XDG defaults for standalone use.
- Consumer modules extend this contract through `romaingrx.theme.runtimeEnv`
  instead of hardcoding consumer-specific paths in the base theme module.
- Runtime bootstrapping and atomic symlink updates live in
  `config/bin/romaingrx-theme-lib`; activation snippets call those shared
  helpers instead of reimplementing link logic.
- By default, runtime appearance state lives in
  `XDG_STATE_HOME/theme/appearance`, managed by
  `config/bin/romaingrx-theme-lib`.
- Darwin detects the macOS system appearance through `defaults`.
- Linux treats the state file as the source of truth.
- Alacritty already imports a runtime symlink at
  `~/.local/share/alacritty/active-theme.toml`.
- Neovim watches the same appearance state and maps `light` to Catppuccin Latte
  and `dark` to Catppuccin Mocha.

## Palette Drift To Preserve Or Migrate Intentionally

- Alacritty and Neovim use Catppuccin Latte/Mocha.
- tmux uses the Catppuccin plugin, defaults to Mocha, and has a manual Latte
  toggle.
- SketchyBar is migrated to generated Latte/Mocha shell color fragments. The
  committed `config/sketchybar` files remain editable; `colors.sh` loads the
  active runtime fragment from the shared `current` theme contract.
- Waybar is migrated to generated Latte/Mocha theme fragments. The committed
  `config/waybar` files remain editable base config/style files; Home Manager
  links them out-of-store and adds runtime `current` theme symlinks beside them.
- Hyprland and Hyprlock are migrated to generated Latte/Mocha color fragments.
  The committed `config/hypr` files remain editable base config files; Home
  Manager links them out-of-store and adds runtime `current` theme symlinks
  under `~/.config/hypr/theme/`.
- Rofi is migrated to generated Latte/Mocha config, linked through the runtime
  `current` theme contract.
- jankyborders uses hardcoded nix-darwin service colors.

Migrating all surfaces to Latte/Mocha is a visible theme change, not just a
deduplication pass.

## Inventory

### Runtime Theme Scripts

- `config/bin/romaingrx-theme-lib`
- `config/bin/romaingrx-theme-apply`
- `config/bin/romaingrx-theme-get`
- `config/bin/romaingrx-theme-set`
- `config/bin/romaingrx-theme-watch`
- `config/alacritty/theme-switcher.sh`

### Alacritty

- `config/alacritty/alacritty.toml`
- `config/alacritty/themes/catppuccin-latte.toml`
- `config/alacritty/themes/catppuccin-mocha.toml`
- `modules/home/programs/alacritty.nix`

### Neovim

- `config/nvim/init.lua`
- `config/nvim/lua/config/theme.lua`
- `config/nvim/lua/plugins/theme.lua`
- `modules/nvim.nix`

### tmux

- `config/tmux/tmux.conf`
- `modules/home/programs/tmux.nix`

### Linux Desktop

- `users/romaingrx/home-manager-nixos.nix`
- `users/romaingrx/nixos.nix`
- `config/waybar/style.css`
- `config/waybar/config.jsonc`
- `modules/home/programs/waybar.nix`
- `modules/home/programs/waybar/theme.nix`
- `modules/home/programs/hypr.nix`
- `modules/home/programs/hypr/theme.nix`
- `modules/home/programs/rofi.nix`
- `modules/home/programs/rofi/theme.nix`
- `config/hypr/hyprland-core.conf`
- `config/hypr/hyprlock.conf`
- `config/hypr/hyprpaper.conf`
- `config/hypr/autostart.conf`
- `config/bin/romaingrx-clipboard-history`
- `config/bin/romaingrx-lock-screen`

### Darwin Desktop

- `users/romaingrx/home-manager-darwin.nix`
- `users/romaingrx/darwin.nix`
- `modules/darwin/homebrew.nix`
- `modules/darwin/services/jankyborders.nix`
- `modules/darwin/services/sketchybar/default.nix`
- `modules/home/programs/sketchybar.nix`
- `modules/home/programs/sketchybar/theme.nix`
- `config/sketchybar/colors.sh`
- `config/sketchybar/sketchybarrc`
- `config/sketchybar/helpers/env.sh`
- `config/sketchybar/helpers/components.sh`
- `config/sketchybar/items/spaces.sh`
- `config/sketchybar/items/wifi.sh`
- `config/sketchybar/items/cpu.sh`
- `config/sketchybar/items/battery.sh`
- `config/sketchybar/items/mode.sh`
- `config/sketchybar/plugins/space.sh`
- `config/sketchybar/plugins/spaces_update.sh`
- `config/sketchybar/plugins/spaces_reconcile.sh`
- `config/sketchybar/plugins/wifi.sh`
- `config/sketchybar/plugins/battery.sh`
- `config/sketchybar/plugins/cpu.sh`
- `config/sketchybar/plugins/mode.sh`
- `config/sketchybar/plugins/darkmode.sh`
- `config/sketchybar/plugins/darkmode_click.sh`

## Future Literal Whitelist

After consumers are migrated, raw color literals should be limited to:

- Shared theme data in `lib/theme`.
- Generated theme artifacts owned by Home Manager.
- Intentional transparent state aliases in generated shell/CSS fragments.
- Third-party vendored config under `config/tmux/plugins`.
- Documentation and tests.

Any new literal in normal app config should either move into the shared theme
library or be documented as an intentional non-theme value.
