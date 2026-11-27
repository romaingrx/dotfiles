# This setup

The personal parts of this Herdr setup are kept in the dotfiles repository, in
`~/.dotfiles/config/herdr-app`. Home Manager links each entry of that folder to
the same path in `~/.config/herdr-app` (`modules/darwin/herdr-app.nix`).

- Make a personal layout, mod or theme in the repository folder
  (`layouts/<name>.json`, `mods/<name>/`, `themes/<name>.json`), not in
  `~/.config/herdr-app`.
- A change to a linked file applies at once.
- A new file or folder is linked only after `git add` and the next system
  rebuild.
- `settings.json` and all that Herdr ships are not kept in the repository,
  because the app writes them.
- Herdr does not see a change behind a linked mod folder until the link itself
  changes: run `touch -h` on the link. A linked layout file needs no such
  step, because Herdr applies its changes in a few seconds.

## Projects

`projects` is the personal layout, drawn by the `projects` mod: the project
list on the left, a project's orchestrator in the middle, and a panel with
Threads, Files and Changes on the right.

The layout and the mod are kept in a repository of their own, cloned at
`~/dev/herdr-projects`. The app loads the mod from that clone through a link
(`modules/darwin/herdr-projects.nix`).

- Read `README.md` there for what the layout does, and `DESIGN.md` for how it
  works and how its code is kept.
- Change the mod in the clone, not here. Then build it and reload it:
  ```sh
  cd ~/dev/herdr-projects
  bun run build && bun run reload
  ```
- The file the app shows, `~/.config/herdr-app/layouts/projects.json`, is a
  copy that the app owns. The mod rewrites it as it runs, and Home Manager
  makes it once on a new machine.
- The settings of this setup are in `~/.dotfiles/config/herdr-projects`: the
  memory guard and the Claude gateway in `config.sh`, and what this setup adds
  to each role in `orchestrator.md` and `thread.md`. Home Manager links the
  folder to `~/.config/herdr-projects` on each machine where sessions run
  (`modules/home/herdr-projects.nix`). A change applies after the next rebuild
  of that machine.
- `keys.json` is not in the repository. Its `layout:projects` section binds
  `cmd-1` to `cmd-9` to `projects.select-1` to `projects.select-9`.
