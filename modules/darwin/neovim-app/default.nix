# Neovim.app: shows up in Finder's "Open With" for text files and opens them
# in Neovim in a new window of your terminal (lib/apps). To make it the default
# for a type, use Get Info > Open with > Change All.
{ lib, pkgs, ... }:
let
  inherit (import ../../../lib/apps) terminal;
  info = {
    CFBundleName = "Neovim";
    CFBundleDisplayName = "Neovim";
    CFBundleIdentifier = "com.romaingrx.neovim";
    CFBundleExecutable = "Neovim";
    CFBundleIconFile = "nvim";
    CFBundlePackageType = "APPL";
    # No Dock icon: the app hands off to the terminal and quits.
    LSUIElement = true;
    NSAppleEventsUsageDescription = "Neovim opens files in a new terminal window.";
    CFBundleDocumentTypes = [
      {
        CFBundleTypeName = "Text";
        CFBundleTypeRole = "Editor";
        LSHandlerRank = "Alternate";
        LSItemContentTypes = [ "public.text" ];
      }
    ];
  };

  app = pkgs.stdenv.mkDerivation {
    name = "neovim-app";
    src = lib.fileset.toSource {
      root = ./.;
      fileset = ./main.m;
    };
    nativeBuildInputs = [ pkgs.libicns ];
    buildPhase = ''
      $CC -fobjc-arc -framework Cocoa -O2 main.m -o Neovim
      png2icns nvim.icns ${pkgs.neovim-unwrapped}/share/icons/hicolor/128x128/apps/nvim.png
    '';
    installPhase = ''
      dir=$out/Applications/Neovim.app/Contents
      install -Dm755 Neovim $dir/MacOS/Neovim
      install -Dm644 nvim.icns -t $dir/Resources
      install -Dm644 ${terminal.run} $dir/Resources/run.applescript
      cp ${pkgs.writeText "Info.plist" (lib.generators.toPlist { escape = true; } info)} $dir/Info.plist
    '';
  };
in
{
  environment.systemPackages = [ app ];
}
