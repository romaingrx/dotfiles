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

## Mods

Personal mods are written in TypeScript, in `mods/<name>/src`. Herdr loads only
`main.js`, so build after each change:

```sh
cd ~/.dotfiles/config/herdr-app/mods/<name>
bun run build
```

`build` runs the type check, the tests and the bundler, then touches the link
and runs `herdr-app check`. The touch is needed: Herdr does not see a change
behind a linked mod folder until the link itself changes. A linked layout file
needs no such step, because Herdr applies its changes in a few seconds.

Keep the code in small modules: data logic with no Herdr import and with tests,
view functions that take a props object, and one `View` class that wires them.

## Layout

`projects` is the personal layout: the project list on the left, a project's
orchestrator in the middle, and a panel with Threads, Files and Changes on the
right. The `projects` mod draws the list, the panel's tabs, its Threads tab and
the dialogs; a block or an overlay picks one of them with `props.part`.

The layout's tree is `mods/projects/layout.json`. The file the app shows,
`~/.config/herdr-app/layouts/projects.json`, is a copy that is not in the
repository: a click on a thread opens its terminal in the panel, and a layout
names the terminal of a block, so the mod changes that copy each time. The mod
makes the copy again when the tree changes, and Home Manager makes it once on a
new machine.

Herdr's `agent` block would need no such copy, but it follows the keyboard:
it shows the orchestrator as soon as the person types there. And a mod may not
send an app command an argument nested more than 16 levels deep, so the tree
stays flat; a test checks it.

## Projects

A project is every live terminal with the same `project` label. It lives on
one machine, so it runs while this computer is off.

- **Start:** the `+` next to Projects asks for a name, a machine and a folder,
  and runs `mods/projects/agent/start.sh orchestrator`. The orchestrator gets
  a space of its own, and the instructions of its role (`orchestrator.md`) as
  an appended system prompt. No skill is installed for it.
- **Threads:** a thread is one task with an end, such as a feature or a pull
  request to merge. It does its own checks and reviews with sub-agents; the
  orchestrator starts a thread only for a task that no open thread owns. Each
  one starts with `start.sh thread`, as a tab in the project's space with the
  instructions in `thread.md`. A click opens the thread in the right panel;
  its header has its state, rename, resolve, and a drawer with the Files and
  Changes of that thread's folder.
- **Pull requests:** every two minutes, while the window is on show, the mod
  reads the pull request of each open thread with `gh pr view` in the thread's
  folder, on its machine. A thread that rests with a pull request open for
  review is listed under Ready for review, and one that is approved or set to
  merge under Landing. The row shows the number and the state, and the
  thread's header opens it in the browser. Sessions that share a folder get
  none: the branch there belongs to none of them.
- **Review:** the thread's header opens a review of its branch: the files it
  changed against its base, as a tree of folders, and the diff of one of
  them. A Shift-click on a second line puts a comment on all the lines from
  the first one to it. The base is the one
  of its pull request, else the repository's main branch. The diff is of the
  thread's folder, so it has what is not committed yet. A click on a line
  takes a comment. The comments are a draft that stays until it is sent; Send
  types them into the thread as one message, each with its file, its line and
  the line's text. They do not go to GitHub.
- **Waits:** a session waits on the person when its agent is blocked, or when
  its thread reported `needs-you`. The mod puts the number of waits on the
  app's icon, and the project row says who waits and who works. It posts no
  notice.
- **Reports:** a thread reports with `report.sh`. The report is a file, the
  thread's terminal carries `state` and `report` labels, and a short `hc send`
  wakes the orchestrator. `threads.sh` lists every thread with its report.
- **Memory:** `~/.claude/projects-memory/<project>/MEMORY.md` on the project's
  machine. Only the orchestrator writes it.
- **Names:** Herdr's own names win. A thread shows its pane's name, then its
  tab's name, then the title its orchestrator gave it. Rename and close are
  Herdr's own commands on the thread's tab.
- **Resolved:** the `resolved` label on the thread's terminal, set from the
  panel or by the orchestrator. A new report from the thread clears it.
- **View:** each project remembers the thread it had open in the panel, and
  the projects keep the order the person drags them into.
- **Rename and end a project:** right-click it. Close project ends every
  session of it: it closes the project's own space and ends its sessions
  elsewhere with `hc kill`. Ungroup removes the labels and keeps the sessions
  running. Each asks once more in the menu and says what it does. The memory
  folder stays.
- **Commands:** `projects.new`, `projects.next`, `projects.prev`,
  `projects.next-waiting`, `projects.threads` and `projects.review` (the
  review of the thread that is open in the panel) are in the command palette.
  `projects.select-1` to `projects.select-9` show the project at that place in
  the list. The copy of the mod in the sidebar runs them, and watches the
  waits, so they need the sidebar on show.
- **Keys:** `keys.json` is not in the repository. Its `layout:projects`
  section binds `cmd-1` to `cmd-9` to `projects.select-1` to
  `projects.select-9`, in place of the tab keys that the layout has no use for.
