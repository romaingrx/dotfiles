---
name: stacking-pull-requests
description: >-
  Splits a large change into a chain of dependent GitHub pull requests using the
  `gh stack` CLI extension: plans the layers, creates and pushes the branches,
  submits linked pull requests, rebases the stack, and merges bottom-up. Use
  when the user says "use stacked PRs", "stack this", "stacked pull requests",
  "split this into a stack", asks to break a big change into dependent PRs, or
  asks to update, rebase, or merge an existing stack.
---

# Stacking pull requests

A stack is a chain of branches in one repository: the bottom branch targets the
trunk (usually `main`), and each branch above targets the branch below it. Each
pull request shows only its own layer's diff.

```text
   ┌── feat/frontend     → PR #3 (base: feat/api-endpoints)  ← top
  ┌── feat/api-endpoints → PR #2 (base: feat/auth-layer)
 ┌── feat/auth-layer     → PR #1 (base: main)                ← bottom
main (trunk)
```

**Layering rule:** if code in one layer depends on code in another, the
dependency must live in the same branch or a lower one. Start a new layer when
the concern changes (schema → API → UI, logic → tests) or the current branch is
already big enough to review on its own.

## Non-interactive use

Commands run without a TTY here, so **always** use the non-interactive forms
below. The interactive ones open a full-screen TUI or a pager and will hang:

| Never run bare        | Use instead                                          |
| --------------------- | ---------------------------------------------------- |
| `gh stack init`       | `gh stack init BRANCH` (name the branch)             |
| `gh stack add`        | `gh stack add BRANCH`                                |
| `gh stack submit`     | `gh stack submit --auto` (add `--open` for non-draft)|
| `gh stack view`       | `gh stack view --json` or `gh stack view --short`    |
| `gh stack merge`      | `gh stack merge --yes` (plus a merge-method flag)    |
| `gh stack checkout`   | `gh stack checkout <stack-no \| pr-no \| branch>`    |
| `gh stack modify`     | `gh stack unstack --local` + `gh stack init A B C`   |
| `gh stack switch`     | `gh stack up` / `down` / `top` / `bottom` / `trunk`  |

Restructuring a stack has no non-interactive path: `gh stack modify` is TUI-only.
Rebuild instead — `gh stack unstack --local`, then `gh stack init` with the
branches in the order you want (existing branches are adopted).

## Workflow

Copy this checklist and check items off as you go:

```text
Stack progress:
- [ ] Step 1: Preflight (extension installed, clean tree, on trunk)
- [ ] Step 2: Plan the layers and confirm with the user
- [ ] Step 3: Create the bottom branch and commit
- [ ] Step 4: Add each further layer and commit
- [ ] Step 5: Submit the stack
- [ ] Step 6: Report the stack back to the user
```

**Step 1: Preflight**

```bash
gh extension list | grep -q gh-stack || gh extension install github/gh-stack
git status --porcelain          # must be clean before init
```

Requires `gh` 2.90.0+ and an authenticated `gh auth login`. Start from an
up-to-date trunk (`git switch main && git pull`) unless the user wants a
different base, which goes in `--base`.

**Step 2: Plan the layers**

Decide the layers before creating anything, and state the plan (branch name +
one-line scope per layer, bottom to top) for the user to confirm. Reordering
later means rebuilding the stack. Follow the repository's existing branch naming
convention.

**Step 3: Create the bottom branch**

```bash
gh stack init feat/auth-layer          # --base develop to target another trunk
# ... make the changes ...
git add -A && git commit -m "feat(auth): add token middleware"
```

**Step 4: Add each further layer**

Run from the topmost branch. One layer at a time: create, change, commit.

```bash
gh stack add feat/api-endpoints
# ... make the changes ...
git add -A && git commit -m "feat(api): add session routes"
```

`gh stack add -Am "MESSAGE" BRANCH` stages everything and commits in one step —
but only when the message and branch name are both explicit.

**Step 5: Submit**

```bash
gh stack submit --auto          # pushes every branch, opens linked draft PRs
gh stack submit --auto --open   # same, but ready for review
```

`--auto` generates PR titles from the commits. To control the title and body,
create the PRs yourself with `gh pr create --base <branch below>` per layer, then
link them: `gh stack link PR1 PR2 PR3`.

**Step 6: Report**

```bash
gh stack view --json
```

Give the user the PR number, title, and base branch of each layer, bottom to top.

## Updating an existing stack

After trunk moves or after editing a lower layer, re-sync the whole chain:

```bash
gh stack sync          # fetch, rebase the cascade, force-push, relink PRs
gh stack sync --prune  # same, and delete local branches for merged PRs
```

Commit the change on the layer it belongs to (`gh stack down`/`up` to move
between them), then `gh stack sync`. Never `git push --force` a stack branch by
hand; `sync` and `push` use `--force-with-lease` per branch.

Use `gh stack rebase` when you only want the cascading rebase without pushing,
or `gh stack push` to push branches without touching PRs.

**On conflict** the rebase pauses and lists the conflicted files:

1. Resolve the files, then `git add` them.
2. `gh stack rebase --continue`.
3. Repeat until it finishes; `gh stack rebase --abort` restores every branch.

Never resolve a conflict by dropping the lower layer's changes — the lower layer
is the dependency.

## Merging

Pull requests merge bottom-up; a stack cannot merge out of order.

```bash
gh stack merge --yes --squash      # whole stack, all-or-nothing
gh stack merge 42 --yes --squash   # everything up to and including PR 42
```

Merging a mid-stack PR merges everything below it and re-targets the PRs above
onto the trunk. Merging is all-or-nothing: if one layer cannot merge, none do.
Match the repository's usual merge method (`--squash`, `--merge`, `--rebase`);
with a merge queue the method flags are ignored and the stack is queued instead.

Merging is a shared, hard-to-reverse action: confirm with the user before running
it unless they explicitly asked to merge.

## Constraints

- All branches must live in the same repository — no cross-fork stacks.
- Branch protection and CI apply to **every** layer, not just the bottom one.
- Exit code `9` means stacked pull requests are not enabled for the repository;
  report that instead of retrying. Other codes: `2` not in a stack, `3` rebase
  conflict, `6` branch is in multiple stacks, `7` rebase already in progress.

**Full CLI reference** — every command, flag, and exit code: see
[reference.md](reference.md).
