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

  alacrittyLatteGolden = repoRoot + "/config/alacritty/themes/catppuccin-latte.toml";
  alacrittyMochaGolden = repoRoot + "/config/alacritty/themes/catppuccin-mocha.toml";
  hyprGoldenRoot = repoRoot + "/tests/theme/golden/hypr";
  rofiGoldenRoot = repoRoot + "/tests/theme/golden/rofi";
  sketchybarGoldenRoot = repoRoot + "/tests/theme/golden/sketchybar";
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
