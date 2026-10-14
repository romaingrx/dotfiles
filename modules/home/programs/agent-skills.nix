{
  config,
  lib,
  dotfilesPath,
  ...
}:
let
  # Each config/agents/skills/<name>/SKILL.md is linked into every agent's
  # skills dir. Links are per skill, so tool-installed and machine-local
  # skills can live next to them.
  skills = lib.attrNames (
    lib.filterAttrs (
      name: type:
      type == "directory" && builtins.pathExists ../../../config/agents/skills/${name}/SKILL.md
    ) (builtins.readDir ../../../config/agents/skills)
  );
  link = name: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/agents/skills/${name}";
in
{
  home.file = lib.mergeAttrsList (
    map (dir: lib.genAttrs' skills (name: lib.nameValuePair "${dir}/${name}" { source = link name; })) [
      ".agents/skills" # shared convention (Pi, Cline)
      ".claude/skills" # Claude Code only reads its own dir
    ]
  );
}
