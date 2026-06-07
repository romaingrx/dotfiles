_:
let
  inherit (builtins)
    concatStringsSep
    map
    match
    stringLength
    substring
    toString
    ;

  digits = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    a = 10;
    b = 11;
    c = 12;
    d = 13;
    e = 14;
    f = 15;
    A = 10;
    B = 11;
    C = 12;
    D = 13;
    E = 14;
    F = 15;
  };

  hexToRgbList =
    hex:
    let
      normalized = if substring 0 1 hex == "#" then substring 1 6 hex else hex;
      pairs = [
        (substring 0 2 normalized)
        (substring 2 2 normalized)
        (substring 4 2 normalized)
      ];
      fromPair =
        pair:
        let
          hi = substring 0 1 pair;
          lo = substring 1 1 pair;
        in
        digits.${hi} * 16 + digits.${lo};
    in
    assert stringLength normalized == 6;
    assert match "[0-9A-Fa-f]{6}" normalized != null;
    map fromPair pairs;

  mkColor = hex: {
    inherit hex;
    hash = "#${hex}";
    rgb = hexToRgbList hex;
  };
in
{
  inherit mkColor;

  format = {
    hex = color: color.hash;
    hexRaw = color: color.hex;
    rgbTuple = color: concatStringsSep ", " (map toString color.rgb);
    hyprRgb = color: "rgb(${color.hex})";
    hyprRgba = color: alpha: "rgba(${color.hex}${alpha})";
    # 0xAARRGGBB, the macOS color-argument format (jankyborders, SketchyBar).
    argb = color: alpha: "0x${alpha}${color.hex}";
  };
}
