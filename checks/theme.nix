{ pkgs, repoRoot, ... }:
let
  inherit (pkgs) lib;

  theme = import (repoRoot + "/lib/theme") { };
  renderAlacrittyTheme = import (repoRoot + "/modules/home/programs/alacritty/theme.nix") { };
  renderWaybarTheme = import (repoRoot + "/modules/home/programs/waybar/theme.nix") {
    inherit (pkgs) lib;
  };
  renderHyprTheme = import (repoRoot + "/modules/home/programs/hypr/theme.nix") {
    inherit (pkgs) lib;
  };
  renderRofiTheme = import (repoRoot + "/modules/home/programs/rofi/theme.nix") {
    inherit (pkgs) lib;
  };
  renderSketchybarTheme = import (repoRoot + "/modules/home/programs/sketchybar/theme.nix") {
    inherit (pkgs) lib;
  };
  renderTmuxTheme = import (repoRoot + "/modules/home/programs/tmux/theme.nix") {
    inherit (pkgs) lib;
  };

  alacrittyLatteGolden = repoRoot + "/config/alacritty/themes/catppuccin-latte.toml";
  alacrittyMochaGolden = repoRoot + "/config/alacritty/themes/catppuccin-mocha.toml";
  hyprGoldenRoot = repoRoot + "/tests/theme/golden/hypr";
  rofiGoldenRoot = repoRoot + "/tests/theme/golden/rofi";
  sketchybarGoldenRoot = repoRoot + "/tests/theme/golden/sketchybar";
  tmuxGoldenRoot = repoRoot + "/tests/theme/golden/tmux";
  tmuxIntegrationGolden = tmuxGoldenRoot + "/integration.conf";
  waybarGoldenRoot = repoRoot + "/tests/theme/golden/waybar";
  runtimeContractTest = repoRoot + "/tests/theme/runtime-contract.sh";
  themeLib = repoRoot + "/config/bin/romaingrx-theme-lib";
  waybarConfigPath = "/home/romaingrx/.config/waybar/config-base.jsonc";

  mkThemeGoldenCheck =
    {
      name,
      goldenRoot,
      artifacts,
    }:
    let
      diffCommands = lib.concatMapStringsSep "\n" (
        appearance:
        lib.concatMapStringsSep "\n" (
          artifact:
          let
            rendered = artifact.render theme.appearances.${appearance};
            generatedName = "generated-${name}-${appearance}-${baseNameOf artifact.path}";
          in
          ''
            diff -u \
              ${goldenRoot}/${appearance}/${artifact.path} \
              ${pkgs.writeText generatedName rendered}
          ''
        ) artifacts
      ) theme.appearanceNames;
    in
    pkgs.runCommand "theme-${name}-golden" { nativeBuildInputs = [ pkgs.diffutils ]; } ''
      ${diffCommands}
      touch "$out"
    '';
in
{
  theme-alacritty-golden =
    pkgs.runCommand "theme-alacritty-golden" { nativeBuildInputs = [ pkgs.diffutils ]; }
      ''
        diff -u \
          ${alacrittyMochaGolden} \
          ${pkgs.writeText "generated-catppuccin-mocha.toml" (renderAlacrittyTheme theme.appearances.dark)}
        diff -u \
          ${alacrittyLatteGolden} \
          ${pkgs.writeText "generated-catppuccin-latte.toml" (renderAlacrittyTheme theme.appearances.light)}
        touch "$out"
      '';

  theme-waybar-golden = mkThemeGoldenCheck {
    name = "waybar";
    goldenRoot = waybarGoldenRoot;
    artifacts = [
      {
        path = "config.jsonc";
        render =
          theme':
          renderWaybarTheme.config {
            configPath = waybarConfigPath;
            theme = theme';
          };
      }
      {
        path = "theme.css";
        render = renderWaybarTheme.themeCss;
      }
    ];
  };

  theme-hypr-golden = mkThemeGoldenCheck {
    name = "hypr";
    goldenRoot = hyprGoldenRoot;
    artifacts = [
      {
        path = "hyprland-colors.conf";
        render = renderHyprTheme.hyprland;
      }
      {
        path = "hyprlock-colors.conf";
        render = renderHyprTheme.hyprlock;
      }
    ];
  };

  theme-rofi-golden = mkThemeGoldenCheck {
    name = "rofi";
    goldenRoot = rofiGoldenRoot;
    artifacts = [
      {
        path = "config.rasi";
        render = renderRofiTheme.config;
      }
    ];
  };

  theme-sketchybar-golden = mkThemeGoldenCheck {
    name = "sketchybar";
    goldenRoot = sketchybarGoldenRoot;
    artifacts = [
      {
        path = "colors.sh";
        render = renderSketchybarTheme.colors;
      }
    ];
  };

  theme-tmux-golden = mkThemeGoldenCheck {
    name = "tmux";
    goldenRoot = tmuxGoldenRoot;
    artifacts = [
      {
        path = "flavor.conf";
        render = renderTmuxTheme.flavor;
      }
    ];
  };

  # The integration drop-in is path-dependent rather than appearance-dependent,
  # so it gets its own check: the rendered output (with fixed placeholder paths)
  # is pinned against a golden, and real tmux must accept the fragment.
  theme-tmux-integration =
    let
      rendered = renderTmuxTheme.integration {
        flavorConf = "/run/theme/current/tmux/flavor.conf";
        themeGet = "/run/bin/romaingrx-theme-get";
        themeSet = "/run/bin/romaingrx-theme-set";
      };
    in
    pkgs.runCommand "theme-tmux-integration"
      {
        nativeBuildInputs = [
          pkgs.diffutils
          pkgs.tmux
        ];
      }
      ''
        diff -u \
          ${tmuxIntegrationGolden} \
          ${pkgs.writeText "generated-tmux-integration.conf" rendered}

        # tmux must parse the fragment and register the prefix+T binding.
        export HOME="$PWD"
        export TMUX_TMPDIR="$PWD"
        tmux -f ${tmuxIntegrationGolden} new-session -d
        tmux list-keys -T prefix | grep -qE 'prefix +T ' || {
          echo "prefix+T not bound after sourcing the integration fragment" >&2
          exit 1
        }
        tmux kill-server || true

        touch "$out"
      '';

  theme-runtime-contract =
    pkgs.runCommand "theme-runtime-contract"
      {
        nativeBuildInputs = [
          pkgs.bash
          pkgs.coreutils
          pkgs.gnugrep
        ];
      }
      ''
        THEME_LIB=${themeLib} \
          ${pkgs.bash}/bin/bash ${runtimeContractTest}
        touch "$out"
      '';
}
