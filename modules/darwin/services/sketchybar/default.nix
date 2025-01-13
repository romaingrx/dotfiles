{pkgs, ...}: 
let
  customPackages = import ../../packages { inherit pkgs; };
  sbarLua = customPackages.sbarLua;

  # Create config directory with all Lua files
  configDir = pkgs.runCommand "sketchybar-config" { } ''
    mkdir -p $out
    
    # Copy all Lua files preserving directory structure
    cp -r ${./config}/* $out/
  '';

  # Create wrapper script to set LUA_CPATH
  wrappedSketchybarrc = pkgs.writeScript "sketchybarrc" ''
    #!${pkgs.lua5_2}/bin/lua
    package.cpath = package.cpath .. ";${sbarLua}/lib/lua/${pkgs.lua5_2.luaversion}/?.so"
    dofile("${configDir}/init.lua")
  '';
in {
  enable = true;
  package = pkgs.sketchybar;
  config = builtins.readFile wrappedSketchybarrc;
  extraPackages = with pkgs; [
    lua5_2
    sbarLua
    jq
    tree
  ];
} 