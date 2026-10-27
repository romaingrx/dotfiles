# The Tailscale logo, a 3x3 grid of dots with a lit T, as PNGs in the theme's
# colors for waybar: `on` while connected, `off` otherwise.
pkgs:
let
  theme = import ./theme;
  p = theme.palette;
  logo =
    name: lit: dim:
    let
      dot =
        x: y: on:
        ''<circle cx="${toString x}" cy="${toString y}" r="2.7" fill="#${if on then lit else dim}"/>'';
      svg = pkgs.writeText "tailscale-${name}.svg" ''
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          ${dot 4 4 false}${dot 12 4 false}${dot 20 4 false}
          ${dot 4 12 true}${dot 12 12 true}${dot 20 12 true}
          ${dot 4 20 false}${dot 12 20 true}${dot 20 20 false}
        </svg>
      '';
    in
    pkgs.runCommand "tailscale-${name}.png" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
      rsvg-convert --width 48 --height 48 ${svg} --output $out
    '';
in
{
  on = logo "on" theme.roles.fg p.surface2;
  off = logo "off" p.surface2 p.surface1;
}
