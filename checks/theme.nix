{ pkgs, repoRoot, ... }:
let
  theme = import (repoRoot + "/lib/theme") { };
  renderAlacrittyTheme = import (repoRoot + "/modules/home/programs/alacritty/theme.nix") { };

  alacrittyLatteGolden = repoRoot + "/config/alacritty/themes/catppuccin-latte.toml";
  alacrittyMochaGolden = repoRoot + "/config/alacritty/themes/catppuccin-mocha.toml";
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
