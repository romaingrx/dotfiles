# `gh stack` CLI reference

Full command, flag, and exit-code reference for the `github/gh-stack` extension.
See [SKILL.md](SKILL.md) for the workflow and the non-interactive command forms.

## Contents

- Installation
- Command summary
- Stack management — `init`, `add`, `view`, `checkout`, `modify`, `unstack`
- Remote operations — `submit`, `sync`, `rebase`, `push`, `link`, `merge`
- Navigation — `switch`, `up`, `down`, `top`, `bottom`, `trunk`
- Utilities — `alias`, `feedback`
- Environment variables
- Exit codes

## Installation

```bash
gh extension install github/gh-stack
```

Requires `gh` 2.90.0+, Git 2.20+, and `gh auth login`. The extension uses the
GitHub CLI's own authentication.

## Command summary

| Command             | Purpose                                                             |
| ------------------- | ------------------------------------------------------------------- |
| `gh stack init`     | Initialize a new stack in the current repository.                   |
| `gh stack add`      | Add a new branch on top of the current stack.                       |
| `gh stack view`     | View the current stack.                                             |
| `gh stack checkout` | Check out a stack by stack number, PR number, PR URL, or branch.    |
| `gh stack modify`   | Interactively restructure the current stack.                        |
| `gh stack unstack`  | Remove a stack from local tracking and unstack it on GitHub.        |
| `gh stack submit`   | Push all branches, then create/update pull requests and the stack.  |
| `gh stack sync`     | Fetch, rebase, push, and sync pull request state in one command.    |
| `gh stack rebase`   | Pull from the remote and run a cascading rebase across the stack.   |
| `gh stack push`     | Push the active branches in the current stack to the remote.        |
| `gh stack link`     | Link pull requests into a stack on GitHub without local tracking.   |
| `gh stack merge`    | Merge one or more stacked pull requests at once.                    |
| `gh stack switch`   | Interactively switch to another branch in the stack.                |
| `gh stack up`       | Move up toward the top of the stack, away from the trunk.           |
| `gh stack down`     | Move down toward the bottom of the stack, toward the trunk.         |
| `gh stack top`      | Jump to the top of the stack.                                       |
| `gh stack bottom`   | Jump to the bottom of the stack.                                    |
| `gh stack trunk`    | Jump to the trunk branch.                                           |
| `gh stack alias`    | Create a short command alias.                                       |
| `gh stack feedback` | Open a feedback discussion in the gh-stack repository.              |

## Stack management

### `gh stack init`

```bash
gh stack init [flags] [branches...]
```

Initializes a stack locally. With no arguments it prompts interactively. With
explicit branch names, existing branches are adopted and missing ones created.
The trunk defaults to the repository's default branch. Enables `git rerere`
automatically so conflict resolutions are remembered across rebases.

| Flag                  | Description                                     |
| --------------------- | ----------------------------------------------- |
| `-b, --base <branch>` | Trunk branch for the stack (default: repo default) |

```bash
gh stack init feature-auth
gh stack init --base develop feature-auth
gh stack init feature-auth feature-api feature-ui   # adopt or create several
```

### `gh stack add`

```bash
gh stack add [flags] [branch]
```

Creates a branch at the current HEAD, adds it to the top of the stack, and checks
it out. Must be run from the topmost branch. With `-m` and no branch name, the
name is auto-generated in date-and-slug form (`03-24-add_login`).

| Flag                     | Description                                            |
| ------------------------ | ------------------------------------------------------ |
| `-A, --all`              | Stage all changes, including untracked. Requires `-m`. |
| `-u, --update`           | Stage tracked files only. Requires `-m`.               |
| `-m, --message <string>` | Commit with this message before creating the branch.   |

`-A` and `-u` are mutually exclusive.

```bash
gh stack add api-routes
gh stack add -Am "Add login endpoint"           # auto-named branch
gh stack add -Am "Add tests" test-layer         # explicit branch
gh stack add -m "Add user model"                # commit already-staged changes
```

### `gh stack view`

```bash
gh stack view [flags]
```

Shows all branches, ordering, PR links, and the latest commit per branch. Output
is piped through a pager (`GIT_PAGER`/`PAGER`, default `less -R`) — use `--json`
or `--short` when not on a TTY.

| Flag          | Description                        |
| ------------- | ---------------------------------- |
| `-s, --short` | Compact output (branch names only) |
| `--json`      | Output stack data as JSON          |

### `gh stack checkout`

```bash
gh stack checkout [<stack-number> | <pr-number> | <pr-url> | <branch>]
```

A bare number is read first as a stack or PR number, then as a branch name.
Referencing a remote stack fetches it, pulls the branches, and sets up local
tracking. Branch names resolve against locally tracked stacks only. With no
argument on a TTY it opens a searchable picker over local and remote stacks.

```bash
gh stack checkout 7
gh stack checkout 42
gh stack checkout https://github.com/owner/repo/pull/42
gh stack checkout feature-auth
```

### `gh stack modify`

```bash
gh stack modify [flags]
```

Interactive TUI only — no non-interactive equivalent. Changes are staged in the
interface and applied together with <kbd>Ctrl</kbd>+<kbd>S</kbd>. Branches from
merged pull requests cannot be modified.

| Flag         | Description                                       |
| ------------ | ------------------------------------------------- |
| `--continue` | Continue after resolving conflicts                |
| `--abort`    | Abort and restore the stack to its previous state |

Preconditions: an active stack checked out, a clean working tree, no rebase in
progress, no PR queued for merge, and linear history (no merge commits, no
diverged branches).

Operations: drop <kbd>x</kbd>, fold down <kbd>d</kbd>, fold up <kbd>u</kbd>,
insert below <kbd>i</kbd>, insert above <kbd>I</kbd>, move down
<kbd>Shift</kbd>+<kbd>↓</kbd>, move up <kbd>Shift</kbd>+<kbd>↑</kbd>, rename
<kbd>r</kbd>, undo <kbd>z</kbd>.

After modifying a submitted stack, run `gh stack submit` to push the updated
branches and recreate the stack; the old one is replaced automatically.

### `gh stack unstack`

```bash
gh stack unstack [<stack-number>] [flags]
```

Also available as `gh stack delete`. With no argument it targets the active
stack. A stack number works from anywhere in the repository, via the API, even
when the stack is not checked out locally.

Merged, merging, or queued pull requests cannot be removed and stay in the
stack. When every PR is removed the stack is dissolved; when some remain, the
stack and any local tracking are kept.

| Flag      | Description                                          |
| --------- | ---------------------------------------------------- |
| `--local` | Only remove the stack locally, keeping it on GitHub  |

This is the supported way to restructure without the TUI: `unstack`, then
`gh stack init` with the branches in the order you want.

## Remote operations

### `gh stack submit`

```bash
gh stack submit [flags]
```

Pushes branches and creates a pull request for each one, then links them into a
stack on GitHub. If a stack already exists, new PRs are added to it. If every PR
in the stack is merged, a new stack rooted at the trunk is started for the
unmerged branches.

On a TTY it opens a full-screen editor for selecting branches and drafting
titles and descriptions. `--auto`, or a non-interactive terminal, skips the
editor and uses generated titles. In the editor new PRs default to ready for
review; with `--auto` they are created as drafts unless `--open` is passed.

| Flag              | Description                                                         |
| ----------------- | ------------------------------------------------------------------- |
| `--auto`          | Skip the editor and use automatically generated titles              |
| `--open`          | Create new PRs ready for review, and mark existing PRs ready        |
| `--remote <name>` | Remote to push to (default: auto-detected)                          |

### `gh stack sync`

```bash
gh stack sync [flags]
```

Runs the whole synchronization sequence: fetch from `origin`; reconcile the
remote stack (PRs added on GitHub are pulled down and appended automatically);
fast-forward the trunk; cascade-rebase every branch onto its updated parent, but
only if the trunk moved; push all branches with `--force-with-lease` if a rebase
occurred; sync PR state; relink the stack's open PRs on GitHub (only with two or
more PRs — sync never opens PRs, use `submit`); prompt to prune merged branches.

If a conflict is detected during the cascade, all branches are restored and you
are directed to `gh stack rebase` to resolve it interactively.

| Flag              | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `--remote <name>` | Remote to fetch from and push to (default: auto-detected)|
| `--prune`         | Delete local branches for merged pull requests          |

**Diverged stacks** — when neither stack is a clean prefix of the other, a TTY
offers three choices: take the remote as source of truth (replaces the local
composition, needs a clean working tree); delete the stack on GitHub and stop
(PRs and local branches untouched — recreate with `submit`); or cancel. Without
a TTY, divergence aborts the sync, exiting successfully, with nothing pushed or
updated. Resolve it by unstacking and recreating the stack.

### `gh stack rebase`

```bash
gh stack rebase [flags] [branch]
```

Fetches from `origin`, then rebases branches in order from the trunk upward so
each has the tip of the previous layer in its history. Switches to `--onto` mode
automatically for branches whose PR has merged. On conflict it pauses and prints
the conflicted files with line numbers.

| Flag                              | Description                                                  |
| --------------------------------- | ------------------------------------------------------------ |
| `--downstack`                     | Only rebase branches from the trunk to the current branch    |
| `--upstack`                       | Only rebase branches from the current branch to the top      |
| `--no-trunk`                      | Skip the trunk — no fetch, no trunk rebase                   |
| `--continue`                      | Continue after resolving conflicts                           |
| `--abort`                         | Abort and restore all branches to their pre-rebase state     |
| `--remote <name>`                 | Remote to fetch from (default: auto-detected)                |
| `--committer-date-is-author-date` | Keep committer date as author date. Alias: `--preserve-dates`|

`[branch]` defaults to the current branch.

### `gh stack push`

```bash
gh stack push [flags]
```

Pushes every active branch — excluding merged and queued ones — in a single
`git push` with a per-branch `--force-with-lease` check. Not atomic: branches
whose leases pass are updated even if another is rejected. Does not create or
update pull requests.

| Flag              | Description                                |
| ----------------- | ------------------------------------------ |
| `--remote <name>` | Remote to push to (default: auto-detected) |

### `gh stack link`

```bash
gh stack link [flags] <stack-number | branch-or-pr> <branch-or-pr> [...]
```

Creates or updates a stack on GitHub from branch names, PR numbers, or PR URLs,
with no local tracking state — for people managing branches with Jujutsu,
Sapling, git-town, or plain `git`. Arguments go bottom to top. Branch arguments
are pushed automatically; branches without a PR get one with the correct base
chaining, and existing PRs with a wrong base are corrected. Updates are additive
— existing PRs are never removed from a stack.

Passing a stack number as the first argument appends the rest to the top of that
stack. A numeric first argument is treated as a stack only when it matches an
existing stack, since stack and PR numbers never overlap.

| Flag              | Description                                                          |
| ----------------- | -------------------------------------------------------------------- |
| `--base <branch>` | Base for the bottom of the stack. Ignored when adding to an existing stack. |
| `--open`          | Mark new and existing pull requests as ready for review              |
| `--remote <name>` | Remote to push to (default: auto-detected)                           |

```bash
gh stack link feature-auth feature-api feature-ui
gh stack link 10 20 30
gh stack link 7 48 feature-ui        # append to stack 7
```

### `gh stack merge`

```bash
gh stack merge [<stack-number> | <pr-number>] [flags]
```

Merges every pull request in the stack up to and including the one chosen, as a
single all-or-nothing operation. With no argument it uses the active local
stack. Only basic state is checked before merging — each PR must be open and not
a draft; GitHub evaluates branch protection and rules when the merge runs.
Merge requirements cannot be bypassed.

Without a TTY, or with `--yes`, everything up to the target merges without
prompting, using the last-used merge method unless one is specified. With a
merge queue on the base branch, the stack is queued instead and the merge-method
flags are ignored with a warning; queued PRs can land in separate groups.

| Flag                              | Description                                         |
| --------------------------------- | --------------------------------------------------- |
| `--merge-method <method>`         | Merge method: `merge`, `squash`, or `rebase`        |
| `--merge`, `--squash`, `--rebase` | Shorthands for the corresponding merge method       |
| `-y, --yes`                       | Merge without prompting for confirmation            |

## Navigation

`up` moves away from the trunk, `down` moves toward it. All navigation commands
clamp to the bounds of the stack.

| Command             | Behavior                                                        |
| ------------------- | --------------------------------------------------------------- |
| `gh stack switch`   | Interactive picker over the stack's branches. Requires a TTY.   |
| `gh stack up [n]`   | Move up `n` branches (default 1). From the trunk, to layer one. |
| `gh stack down [n]` | Move down `n` branches (default 1).                             |
| `gh stack top`      | Check out the branch furthest from the trunk.                   |
| `gh stack bottom`   | Check out the branch closest to the trunk.                      |
| `gh stack trunk`    | Check out the trunk branch of the current stack.                |

## Utilities

### `gh stack alias`

```bash
gh stack alias [flags] [name]
```

Installs a wrapper script into `~/.local/bin/` forwarding all arguments to
`gh stack`. Default name `gs`. Not supported on Windows, which prints manual
instructions instead.

| Flag       | Description                            |
| ---------- | -------------------------------------- |
| `--remove` | Remove an alias created previously     |

### `gh stack feedback`

```bash
gh stack feedback [title]
```

Opens a discussion in the [gh-stack repository](https://github.com/github/gh-stack).

## Environment variables

| Variable         | Values                            | Description                                                                 |
| ---------------- | --------------------------------- | --------------------------------------------------------------------------- |
| `GH_STACK_THEME` | `auto` (default), `light`, `dark` | Color palette for interactive screens and colored output. Set explicitly when the terminal does not report its background (some SSH or tmux setups). |

## Exit codes

| Code | Meaning                                                    |
| ---- | ---------------------------------------------------------- |
| 0    | Success                                                    |
| 1    | Generic error                                              |
| 2    | Not in a stack, or stack not found                         |
| 3    | Rebase conflict                                            |
| 4    | GitHub API failure                                         |
| 5    | Invalid arguments or flags                                 |
| 6    | Disambiguation required — the branch belongs to multiple stacks |
| 7    | Rebase already in progress                                 |
| 8    | Stack is locked by another process                         |
| 9    | Stacked pull requests are not enabled for this repository  |
| 10   | Modify session interrupted, recovery required              |

## Limits

- All branches must be in the same repository — cross-fork stacks are not supported.
- Not supported in GitHub Desktop.
- Branch protection rules and CI checks are enforced on every layer, not only the
  bottom one; merge requirements come from the bottom PR's base branch.
- Pull requests must merge bottom-up. Merging a mid-stack PR merges everything
  below it and re-targets the PRs above onto the stack's base branch.
- Merging via the REST API requires the async merge endpoint for stacks.
