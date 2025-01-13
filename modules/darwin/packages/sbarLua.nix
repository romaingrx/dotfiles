{ pkgs }:

pkgs.lua52Packages.buildLuaPackage rec {
  pname = "sketchybar";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "FelixKratz";
    repo = "SbarLua";
    rev = "main";
    sha256 = "sha256-F0UfNxHM389GhiPQ6/GFbeKQq5EvpiqQdvyf7ygzkPg=";
  };

  buildInputs = with pkgs; [
    lua5_2
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
    $CC -shared -o sketchybar.so src/*.c \
      -I${pkgs.lua5_2}/include \
      -L${pkgs.lua5_2}/lib \
      -llua \
      -framework CoreFoundation
  '';

  installPhase = ''
    mkdir -p $out/lib/lua/${pkgs.lua5_2.luaversion}
    install -Dm755 sketchybar.so $out/lib/lua/${pkgs.lua5_2.luaversion}/sketchybar.so

    # Create a symlink in the Lua cpath
    mkdir -p $out/lib
    ln -s $out/lib/lua/${pkgs.lua5_2.luaversion}/sketchybar.so $out/lib/sketchybar.so
  '';

  # Make sure the module is found in the Lua cpath
  LUA_CPATH = "${placeholder "out"}/lib/lua/${pkgs.lua5_2.luaversion}/?.so";

  meta = {
    description = "Lua bindings for sketchybar";
    homepage = "https://github.com/FelixKratz/SbarLua";
    platforms = pkgs.lib.platforms.darwin;
    license = pkgs.lib.licenses.mit;
  };
}
