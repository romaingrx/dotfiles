# Neovim.app: opens a file in Neovim in a new window of your terminal
# (lib/apps). It shows up in Finder's "Open With" for any text file, and is
# the default app for the extensions in ./extensions.nix.
{ lib, pkgs, ... }:
let
  inherit (import ../../../lib/apps) terminal;
  extensions = import ./extensions.nix;
  bundleId = "com.romaingrx.neovim";
  appPath = "/Applications/Nix Apps/Neovim.app";
  lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister";

  info = {
    CFBundleName = "Neovim";
    CFBundleDisplayName = "Neovim";
    CFBundleIdentifier = bundleId;
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
      {
        CFBundleTypeName = "Source code";
        CFBundleTypeRole = "Editor";
        LSHandlerRank = "Alternate";
        CFBundleTypeExtensions = extensions;
      }
    ];
    UTImportedTypeDeclarations = [
      {
        UTTypeIdentifier = "${bundleId}.source-code";
        UTTypeDescription = "Source code";
        UTTypeConformsTo = [ "public.source-code" ];
        UTTypeTagSpecification."public.filename-extension" = extensions;
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

  # nix-darwin copies the app with the store's fixed timestamps, so
  # LaunchServices does not see a changed Info.plist until the app is
  # registered again. A handler can only be set for a declared type, and
  # macOS declares none for extensions such as rs or nix: the app imports one,
  # which gives way to a type macOS declares.
  home-manager.sharedModules = [
    (
      { lib, ... }:
      {
        home.activation.neovimDefaultApp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lsregister} -f ${lib.escapeShellArg appPath} ||
            warnEcho "Neovim.app is not registered"
          for extension in ${lib.escapeShellArgs extensions}; do
            run ${lib.getExe pkgs.duti} -s ${bundleId} ".$extension" all ||
              warnEcho "Neovim is not the default app for .$extension"
          done
        '';
      }
    )
  ];
}
