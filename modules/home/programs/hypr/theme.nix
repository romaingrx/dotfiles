{ lib }:
let
  renderHyprland =
    theme:
    let
      f = theme.format;
      t = theme.roles.ui;
    in
    ''
      general {
          col.active_border = ${f.hyprRgba t.border "ee"} ${f.hyprRgba t.borderSecondary "ee"} 45deg
          col.inactive_border = ${f.hyprRgba t.borderInactive "aa"}
      }
    '';

  renderHyprlock =
    theme:
    let
      f = theme.format;
      t = theme.roles.ui;
    in
    ''
      $color = ${f.hyprRgb t.background}
      $inner_color = ${f.hyprRgb t.backgroundStrong}
      $outer_color = ${f.hyprRgb t.border}
      $font_color = ${f.hyprRgb t.foreground}
      $check_color = ${f.hyprRgb t.borderSecondary}
    '';
in
{
  hyprland = theme: lib.trim (renderHyprland theme) + "\n";
  hyprlock = theme: lib.trim (renderHyprlock theme) + "\n";
}
