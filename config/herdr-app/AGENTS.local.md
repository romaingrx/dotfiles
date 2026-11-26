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
