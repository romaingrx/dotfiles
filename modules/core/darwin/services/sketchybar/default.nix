{ pkgs, ... }:
let
  sbarLua = pkgs.lua54Packages.buildLuaPackage {
    name = "sbar";
    pname = "sbar";
    version = "1";

    src = pkgs.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SbarLua";
      rev = "main";
      sha256 = "sha256-F0UfNxHM389GhiPQ6/GFbeKQq5EvpiqQdvyf7ygzkPg=";
    };

    nativeBuildInputs =
      with pkgs;
      [
        gcc
        readline
        clang
        stdenv
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.apple-sdk ];

    installPhase = ''
      mkdir -p $out/lib/lua/5.4
      cp bin/sketchybar.so $out/lib/lua/5.4/
    '';
  };

  # Create config directory with all Lua files
  configDir = pkgs.runCommand "sketchybar-config" { } ''
    mkdir -p $out

    # Copy all Lua files preserving directory structure
    cp -r ${./config}/* $out/

    # Create lib directory and link the Lua module
    mkdir -p $out/lib
    ln -s ${sbarLua}/lib/lua/5.4/sketchybar.so $out/lib/sketchybar.so
  '';

  # Create the sketchybar config script using lua5_4
  sketchybarConfig = pkgs.writeScriptBin "sketchybarrc" ''
    #!${pkgs.lua5_4}/bin/lua
    package.path = "${configDir}/?.lua;" .. package.path
    package.cpath = "${configDir}/lib/?.so;" .. package.cpath

    ${builtins.replaceStrings [ "{{ CONFIG_DIR_DEFINITION }}" ] [ "${configDir}" ] (
      builtins.elemAt (builtins.split "#!/usr/bin/env lua\n" (builtins.readFile ./sketchybarrc)) 2
    )}
  '';
in
{
  enable = true;
  package = pkgs.sketchybar;
  config = "${sketchybarConfig}/bin/sketchybarrc";
  extraPackages = with pkgs; [
    lua5_4
    jq
    tree
  ];
}
