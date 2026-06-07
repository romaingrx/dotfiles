# Subdirectory symlink generator
# Maps every immediate subdirectory of a repo folder to its own out-of-store
# symlink, producing a `home.file` attrset. Plain files in the folder (README,
# .gitkeep, ...) are ignored, so only sub-folders are linked. With `requireFile`
# set, only sub-folders that contain that file are linked.
#
# Discovery happens at evaluation time, so adding or removing a subfolder needs
# no change to the caller (open/closed): drop it in and rebuild. Links point at
# the live checkout, so editing a linked folder is reflected without a rebuild.
#
# Usage example:
# home.file = mkSubdirSymlinks {
#   repoDir     = ../../config/agents/skills;              # read at eval time
#   liveDir     = "${dotfilesPath}/config/agents/skills";  # live checkout (link target)
#   target      = ".agents/skills";                        # destination prefix in $HOME
#   requireFile = "SKILL.md";                              # optional: skip folders without it
# };
{
  lib,
  config,
  ...
}:

{
  # Directory whose immediate subdirectories become links. A Nix path, read at
  # evaluation time to discover the set of subfolders.
  repoDir,

  # Root the links point at, e.g. "${dotfilesPath}/config/...". Kept distinct
  # from repoDir so links target the editable working tree, not the Nix store.
  liveDir,

  # Destination prefix under $HOME, e.g. ".claude/skills".
  target,

  # If set, only link subdirectories that contain this file (e.g. "SKILL.md"),
  # so empty or malformed entries are skipped. null links every subdirectory.
  requireFile ? null,
}:

let
  isLinkable =
    name: type:
    type == "directory"
    && (requireFile == null || builtins.pathExists (repoDir + "/${name}/${requireFile}"));

  subdirs =
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
builtins.listToAttrs (map mkLink subdirs)
