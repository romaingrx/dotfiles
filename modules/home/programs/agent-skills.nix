{
  config,
  lib,
  dotfilesPath,
  ...
}:
let
  # Each agents/skills/<name>/SKILL.md is linked into ~/.agents/skills, the hub
  # most agents read. Agents that ignore the hub are listed in agents/mirrors;
  # their dirs link back to the hub. Links are per skill, so tool-installed and
  # machine-local skills can live next to them.
  skills = lib.attrNames (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists ../../../agents/skills/${name}/SKILL.md
    ) (builtins.readDir ../../../agents/skills)
  );
  hub = ".agents/skills";
  mirrors = lib.filter (line: line != "" && !lib.hasPrefix "#" line) (
    lib.splitString "\n" (builtins.readFile ../../../agents/mirrors)
  );

  linkSkills =
    dir: root:
    lib.genAttrs' skills (
      name:
      lib.nameValuePair "${dir}/${name}" {
        source = config.lib.file.mkOutOfStoreSymlink "${root}/${name}";
      }
    );
in
{
  home.file = lib.mergeAttrsList (
    [ (linkSkills hub "${dotfilesPath}/agents/skills") ]
    ++ map (dir: linkSkills dir "${config.home.homeDirectory}/${hub}") mirrors
  );
}
