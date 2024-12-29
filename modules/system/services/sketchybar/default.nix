{ pkgs, ... }:
let
  plugins = import ./plugins.nix { inherit pkgs; };
  # Create config directory with executable plugins and items
  configDir = pkgs.runCommand "sketchybar-config" {} ''
    mkdir -p $out
    # Create and make items directory executable
    cp -r ${./items} $out/items
    chmod -R +x $out/items
    # Create and make plugins directory executable
    cp -r ${./plugins} $out/plugins
    chmod -R +x $out/plugins
  '';
in
{
  enable = true;
  package = pkgs.sketchybar;
  config = builtins.replaceStrings
    [ "{{ CONFIG_DIR_DEFINITION }}" ]
    [ "${configDir}" ]
    (builtins.readFile ./sketchybarrc);
  extraPackages = [ pkgs.jq ];
}
