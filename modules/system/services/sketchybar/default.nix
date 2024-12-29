{ pkgs, ... }:
let
  sbarLua = pkgs.stdenv.mkDerivation rec {
    pname = "sketchybar-lua";
    version = "0.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SbarLua";
      rev = "main";
      sha256 = "sha256-F0UfNxHM389GhiPQ6/GFbeKQq5EvpiqQdvyf7ygzkPg=";
    };

    nativeBuildInputs = [ pkgs.gcc ];
    buildInputs = with pkgs; [
      lua
      readline
      darwin.apple_sdk.frameworks.CoreFoundation
    ];

    preBuildPhase = ''
      substituteInPlace makefile \
        --replace "cd lua-5.4.7 && make" "echo 'Skipping lua build...'" \
        --replace "bin/liblua.a" ""
    '';

    buildPhase = ''
      mkdir -p bin
      $CC -shared -o libsketchybar.so src/*.c \
        -I${pkgs.lua}/include \
        -L${pkgs.lua}/lib \
        -llua \
        -framework CoreFoundation
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp libsketchybar.so $out/lib/
    '';

    meta = with pkgs.lib; {
      description = "Lua API for SketchyBar";
      homepage = "https://github.com/FelixKratz/SbarLua";
      license = licenses.gpl3;
      platforms = platforms.darwin;
    };
  };

  # Create config directory with all Lua files
  configDir = pkgs.runCommand "sketchybar-config" { } ''
    mkdir -p $out
    
    # Copy all Lua files preserving directory structure
    cp -r ${./config}/* $out/
    
    # Create lib directory and link the Lua module
    mkdir -p $out/lib
    ln -s ${sbarLua}/lib/libsketchybar.so $out/lib/sketchybar.so
  '';
in
{
  enable = true;
  package = pkgs.sketchybar;
  config = builtins.replaceStrings
    [ "{{ CONFIG_DIR_DEFINITION }}" ]
    [ "${configDir}" ]
    (builtins.readFile ./sketchybarrc);
  extraPackages = with pkgs; [
    lua
    jq
    tree
  ];
}
