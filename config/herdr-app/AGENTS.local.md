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

The layout and the mod are Baton, a repository of its own
(`romaingrx/baton`), cloned at `~/dev/baton`. The app loads the mod from that
clone through a link. Home Manager keeps the clone and runs Baton's own
`install.sh`, which makes the link and the first copy of the layout
(`modules/home/baton-app.nix`).

- Read `README.md` there for what the layout does, and `DESIGN.md` for how it
  works and how its code is kept.
- Change the mod in the clone, not here. Then build it and reload it:
  ```sh
  cd ~/dev/baton
  bun run build && bun run reload
  ```
- The file the app shows, `~/.config/herdr-app/layouts/projects.json`, is a
  copy that the app owns. The mod rewrites it as it runs.
- The settings of this setup are in `~/.dotfiles/config/baton`, one file for
  each concern: the memory guard in `config.d`, and what this setup adds to
  each role in `orchestrator.d` and `thread.d`. Home Manager links each file
  into `~/.config/baton` on each machine where sessions run
  (`modules/home/baton-settings.nix`). The module of another concern adds its
  own file there, as `modules/home/claude-gateway.nix` does. For a new
  setting, add a file: do not edit one that is there. A change applies after
  the next rebuild of that machine.
- `keys.json` is not in the repository. Its `layout:projects` section binds
  `cmd-1` to `cmd-9` to `projects.select-1` to `projects.select-9`.
