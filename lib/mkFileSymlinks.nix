# File symlink generator
# Maps every matching file in a repo folder to its own out-of-store symlink,
# producing a `home.file` attrset. Subdirectories and symlinks are ignored.
#
# Per-file rather than one link on the folder, so the destination stays a real,
# multi-source directory: hand-dropped and tool-installed files sit next to the
# managed ones instead of landing inside the repo.
#
# Discovery happens at evaluation time, so adding or removing a file needs no
# change to the caller (open/closed): drop it in and rebuild. Links point at the
# live checkout, so editing a linked file is reflected without a rebuild.
#
# Usage example:
# home.file = mkFileSymlinks {
#   repoDir = ../../config/agents/claude/output-styles;              # read at eval time
#   liveDir = "${dotfilesPath}/config/agents/claude/output-styles";  # live checkout
#   target  = ".claude/output-styles";                               # prefix in $HOME
#   suffix  = ".md";                                                 # optional
# };
{
  lib,
  config,
  ...
}:

{
  # Directory whose files become links. A Nix path, read at evaluation time.
  repoDir,

  # Root the links point at. Distinct from repoDir so links target the editable
  # working tree, not the Nix store.
  liveDir,

  # Destination prefix under $HOME, e.g. ".claude/output-styles".
  target,

  # If set, only link files ending in it. Keeps strays such as .DS_Store out.
  suffix ? null,
}:

let
  isLinkable = name: type: type == "regular" && (suffix == null || lib.hasSuffix suffix name);

  files =
    if builtins.pathExists repoDir then
      lib.attrNames (lib.filterAttrs isLinkable (builtins.readDir repoDir))
    else
      [ ];

  mkLink =
    name:
    lib.nameValuePair "${target}/${name}" {
      source = config.lib.file.mkOutOfStoreSymlink "${liveDir}/${name}";
    };
in
builtins.listToAttrs (map mkLink files)
