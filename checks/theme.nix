{ pkgs, repoRoot, ... }:
let
  theme = import (repoRoot + "/lib/theme") { };
  renderAlacrittyTheme = import (repoRoot + "/modules/home/programs/alacritty/theme.nix") { };
  renderWaybarTheme = import (repoRoot + "/modules/home/programs/waybar/theme.nix") {
    inherit (pkgs) lib;
  };

  alacrittyLatteGolden = repoRoot + "/config/alacritty/themes/catppuccin-latte.toml";
  alacrittyMochaGolden = repoRoot + "/config/alacritty/themes/catppuccin-mocha.toml";
  waybarGoldenRoot = repoRoot + "/tests/theme/golden/waybar";
  runtimeContractTest = repoRoot + "/tests/theme/runtime-contract.sh";
  themeLib = repoRoot + "/config/bin/romaingrx-theme-lib";
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

  theme-waybar-golden =
    pkgs.runCommand "theme-waybar-golden" { nativeBuildInputs = [ pkgs.diffutils ]; }
      ''
        diff -u \
          ${waybarGoldenRoot}/dark/config.jsonc \
          ${pkgs.writeText "generated-waybar-dark-config.jsonc" (
            renderWaybarTheme.config theme.appearances.dark
          )}
        diff -u \
          ${waybarGoldenRoot}/dark/style.css \
          ${pkgs.writeText "generated-waybar-dark-style.css" (
            renderWaybarTheme.style theme.appearances.dark
          )}
        diff -u \
          ${waybarGoldenRoot}/light/config.jsonc \
          ${pkgs.writeText "generated-waybar-light-config.jsonc" (
            renderWaybarTheme.config theme.appearances.light
          )}
        diff -u \
          ${waybarGoldenRoot}/light/style.css \
          ${pkgs.writeText "generated-waybar-light-style.css" (
            renderWaybarTheme.style theme.appearances.light
          )}
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
