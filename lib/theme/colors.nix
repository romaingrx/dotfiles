_:
let
  mkColor = hex: {
    inherit hex;
    hash = "#${hex}";
  };
in
{
  inherit mkColor;

  format = {
    hex = color: color.hash;
    hyprRgb = color: "rgb(${color.hex})";
    hyprRgba = color: alpha: "rgba(${color.hex}${alpha})";
    # 0xAARRGGBB, the macOS color-argument format (jankyborders, SketchyBar).
    argb = color: alpha: "0x${alpha}${color.hex}";
  };
}
