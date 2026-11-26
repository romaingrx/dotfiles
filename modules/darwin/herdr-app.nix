# The Herdr app and the parts of its interface kept in config/herdr-app.
# Herdr writes its own files into ~/.config/herdr-app and into the layouts,
# mods and themes folders there, so each tracked entry is linked on its own.
{
  homebrew.casks = [ "herdr-app" ];

  home-manager.sharedModules = [
    (
      {
        lib,
        config,
        dotfilesPath,
        ...
      }:
      let
        tracked = ../../config/herdr-app;
        shared = [
          "layouts"
          "mods"
          "themes"
        ];
        names = dir: lib.attrNames (builtins.readDir dir);
        paths = lib.concatMap (
          name:
          if lib.elem name shared then
            map (child: "${name}/${child}") (names (tracked + "/${name}"))
          else
            [ name ]
        ) (names tracked);
      in
      {
        home.file = lib.genAttrs' paths (
          path:
          lib.nameValuePair ".config/herdr-app/${path}" {
            source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/herdr-app/${path}";
          }
        );
      }
    )
  ];
}
