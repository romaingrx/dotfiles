# Colors live in lib/theme, plus the vendored Catppuccin Alacritty ports. Fail on
# a hex color literal anywhere else, so new config reads the palette instead.
{ pkgs, repoRoot, ... }:
{
  theme-no-color-literals =
    pkgs.runCommand "theme-no-color-literals" { nativeBuildInputs = [ pkgs.ripgrep ]; }
      ''
        cd ${repoRoot}
        if rg --line-number \
          --glob '!lib/theme/**' --glob '!config/alacritty/themes/**' --glob '!*.md' --glob '!*.lock' \
          --regexp '#[0-9a-fA-F]{6}\b' --regexp '0x[0-9a-fA-F]{8}\b'; then
          echo "Use lib/theme instead of the color literals above." >&2
          exit 1
        fi
        touch "$out"
      '';
}
