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
        mods = tracked + "/mods";
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
        # A mod that rewrites its layout while it runs ships the tree as
        # mods/<name>/layout.json. Herdr shows layouts/<name>.json, which the
        # mod then keeps up to date: that file is made once, as a copy the app owns.
        ownLayouts = lib.filter (name: builtins.pathExists (mods + "/${name}/layout.json")) (
          lib.optionals (builtins.pathExists mods) (names mods)
        );
      in
      {
        home.file = lib.genAttrs' paths (
          path:
          lib.nameValuePair ".config/herdr-app/${path}" {
            source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/herdr-app/${path}";
          }
        );

        home.activation.herdrLayouts = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          for name in ${lib.escapeShellArgs ownLayouts}; do
            layout="$HOME/.config/herdr-app/layouts/$name.json"
            if [ ! -e "$layout" ]; then
              run mkdir -p "$(dirname "$layout")"
              run cp "$HOME/.config/herdr-app/mods/$name/layout.json" "$layout"
            fi
          done
        '';
      }
    )
  ];
}
