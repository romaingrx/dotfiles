---
name: stacking-pull-requests
description: >-
  Splits a large change into a chain of dependent GitHub pull requests with the
  `gh stack` CLI extension, reading the current GitHub documentation before
  running any command so the commands and flags used are never stale. Use when
  the user says "use stacked PRs", "stack this", "stacked pull requests",
  "split this into a stack", asks to break a big change into dependent pull
  requests, or asks to update, rebase, restructure, or merge an existing stack.
---

# Stacking pull requests

A stack is a chain of branches in one repository: the bottom branch targets the
trunk (usually `main`), and each branch above targets the branch below it. Each
pull request shows only its own layer's diff, and they merge bottom-up.

```text
   ┌── feat/frontend     → PR #3 (base: feat/api-endpoints)  ← top
  ┌── feat/api-endpoints → PR #2 (base: feat/auth-layer)
 ┌── feat/auth-layer     → PR #1 (base: main)                ← bottom
main (trunk)
```

**Layering rule:** if code in one layer depends on code in another, the
dependency must live in the same branch or a lower one. Start a new layer when
the concern changes (schema → API → UI, logic → tests) or when the current
branch is already big enough to review on its own.

## Read the docs first

The `gh stack` extension is evolving, so **do not run commands from memory.**
Fetch the pages for the task at hand, then follow their commands and flags
verbatim. Appending `.md` to any docs.github.com URL returns raw markdown.

| Read this                                                                                       | For                                                             |
| ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands.md`                  | Every `gh stack` command, flag, and exit code. The main one.    |
| `https://docs.github.com/en/pull-requests/get-started/stacked-prs-quickstart.md`                  | Install and prerequisites; creating a first stack end to end.   |
| `https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/creating-stacked-pull-requests.md` | Creating a stack; turning existing pull requests into one. |
| `https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/managing-stacked-pull-requests.md` | Editing a lower layer, rebasing, restructuring, syncing.   |
| `https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/merging-stacked-pull-requests.md` | Merge requirements, merge queues, bottom-up merging. |
| `https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-stacked-pull-requests.md` | Conflicts, interrupted sessions, stuck merges. Read on any error. |
| `https://docs.github.com/en/pull-requests/reference/stacked-pull-requests.md`                     | Trunks, branch protection, required checks, linear history.     |
| `https://docs.github.com/en/pull-requests/get-started/about-stacked-prs.md`                       | Concepts and limits. Read when explaining stacks to the user.   |
| `https://docs.github.com/en/pull-requests/reference/use-other-tools-with-stacked-pull-requests.md` | Stacking branches managed by Jujutsu, Sapling, git-town, plain git. |

If a page contradicts anything below, the page wins — except for the
[working rules](#working-rules), which are about this environment, not about
the feature.

## Workflow

```text
Stack progress:
- [ ] Step 1: Read the CLI reference (plus the how-to for this task)
- [ ] Step 2: Preflight — extension installed, clean tree, trunk up to date
- [ ] Step 3: Plan the layers and confirm them with the user
- [ ] Step 4: Build each layer bottom-up — create branch, change, commit
- [ ] Step 5: Push and submit the stack
- [ ] Step 6: Report each layer's pull request number, title, and base
```

Preflight is `gh extension list | grep -q gh-stack || gh extension install
github/gh-stack`, plus a clean `git status --porcelain` and an up-to-date trunk.
The quickstart page lists the required `gh` and Git versions.

Plan the layers before creating anything and state them for the user — branch
name and one-line scope per layer, bottom to top. Reordering a stack afterwards
is expensive. Follow the repository's existing branch naming convention.

## Working rules

These are constraints of this environment and of acting on someone's behalf, so
they hold regardless of what the docs show.

**No terminal is attached.** Commands that open a full-screen interface
(`gh stack modify`, `gh stack switch`) or that page their output
(`gh stack view`) will hang. Before running a command, check its entry in the
CLI reference for the flag that makes it non-interactive — a JSON or short
output mode, an auto or assume-yes mode, or passing the branch, stack, or pull
request as an argument instead of being prompted for it. Prefer machine-readable
output when reporting state back to the user.

Restructuring is interactive-only. Do it by unstacking locally and re-creating
the stack with the branches in the order you want; the managing page covers this.

**Do not force-push a stack branch by hand.** The extension's own push, sync,
and rebase commands already use `--force-with-lease` per branch and keep the
pull requests linked. A manual `git push --force` breaks that.

**Commit each change to the layer it belongs to**, then re-sync the chain, so
the layer boundaries stay meaningful. When a rebase conflicts, never resolve it
by discarding the lower layer's changes — the lower layer is the dependency.

**Confirm before merging.** Merging a stack is shared and hard to reverse, and
it merges every layer below the target too. Only merge when the user asked for
it in this session.

**Report blocked states rather than retrying.** A non-zero exit from `gh stack`
is meaningful — the reference lists what each code means, including the case
where stacked pull requests are not enabled for the repository. Look the code up
and tell the user; do not retry the command or work around it.

## Limits

Worth knowing before proposing a stack; confirm details against the docs.

- All branches must be in the same repository — no cross-fork stacks.
- Branch protection and CI apply to every layer, not just the bottom one.
- Pull requests merge bottom-up; merging mid-stack merges everything below it.
