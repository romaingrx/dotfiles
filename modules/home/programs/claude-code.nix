{
  config,
  lib,
  dotfilesPath,
  ...
}:
let
  styles = lib.filter (lib.hasSuffix ".md") (
    lib.attrNames (builtins.readDir ../../../agents/claude/output-styles)
  );
in
{
  home.file = lib.genAttrs' styles (
    name:
    lib.nameValuePair ".claude/output-styles/${name}" {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/agents/claude/output-styles/${name}";
    }
  );
}
