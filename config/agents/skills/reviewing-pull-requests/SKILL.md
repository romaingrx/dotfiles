---
name: reviewing-pull-requests
description: >-
  Reviews a pull request with multiple confidence-scored passes — project-convention
  adherence, a shallow bug scan, git history, prior-PR comments, and code-comment
  compliance — drops low-confidence findings, and posts a concise, cited comment. Use
  when asked to review a pull request or a set of changes before merge.
---

# Reviewing pull requests

Review a pull request for real, high-confidence issues and post a concise comment.
Use `gh` to interact with the host (fetch the PR, read diffs, comment) rather than web
fetch. Make a todo list first, then follow these steps precisely.

## 1. Eligibility check

Skip the review (do nothing) if the PR is closed, is a draft, obviously needs no review
(e.g. an automated or trivially simple change), or already has a review from you.

## 2. Gather convention files

List the paths (not the contents) of the project's agent-guidance / convention files
relevant to the change: a root `AGENTS.md` or `CLAUDE.md` (whichever the repo uses),
plus any such files in directories the PR modified. These encode project rules — note
that some entries are guidance for writing code and may not apply during review.

## 3. Summarize the change

Read the PR and produce a short summary of what it does.

## 4. Review across five dimensions

Review the change along the dimensions below. If your tooling can spawn sub-agents, run
them in parallel; otherwise do them sequentially. Each pass returns a list of issues
with the reason each was flagged (convention adherence, bug, git history, etc.).

1. **Conventions** — do the changes comply with the convention files from step 2?
2. **Bugs (shallow)** — read only the diff and scan for obvious, large bugs. Avoid extra
   context; ignore small issues, nitpicks, and likely false positives.
3. **History** — read the git blame/history of the modified code to spot bugs in light
   of that historical context.
4. **Prior PRs** — read previous PRs that touched these files for comments that may also
   apply here.
5. **Code comments** — ensure the changes comply with guidance in nearby code comments.

## 5. Score confidence (0–100)

For each issue, score how confident you are that it is real (vs. a false positive),
double-checking convention-flagged issues against the actual convention text. Use this
rubric verbatim:

- **0** — Not confident. A false positive that doesn't survive light scrutiny, or a pre-existing issue.
- **25** — Somewhat confident. Might be real, might be a false positive; unverified. If stylistic, not explicitly called out in the conventions.
- **50** — Moderately confident. Verified real, but possibly a nitpick or rare in practice; not very important relative to the PR.
- **75** — Highly confident. Double-checked and very likely real in practice; the PR's approach is insufficient, or it is directly named in the conventions.
- **100** — Certain. Double-checked and confirmed real, will happen frequently; the evidence directly confirms it.

## 6. Filter

Drop any issue scoring below 80.

## 7. Re-check eligibility

Repeat step 1 to confirm the PR is still eligible for review.

## 8. Post the review

Comment on the PR with `gh`, using the output format below: the list of issues found,
or the "No issues found" comment when none remain. Keep it brief, avoid emojis, and
link/cite relevant code, files, and URLs (see linking format under Notes).

## What counts as a false positive (steps 4–5)

- Pre-existing issues.
- Something that looks like a bug but is not.
- Pedantic nitpicks a senior engineer wouldn't raise.
- Anything a linter, type-checker, or compiler would catch (imports, type errors, broken
  tests, formatting, pedantic style). Assume CI runs these separately — don't run builds.
- General quality gaps (test coverage, generic security, docs) unless a convention requires them.
- Issues named in the conventions but explicitly silenced in code (e.g. a lint-ignore comment).
- Functionality changes that are likely intentional or part of the broader change.
- Real issues on lines the PR did not modify.

## Notes

- Don't build or type-check the app — CI does that separately and it is not relevant here.
- Use `gh` (not web fetch) to interact with the host.
- Cite and link every issue. Links must use a full commit SHA (not `$(git rev-parse HEAD)`
  — the comment is rendered as Markdown, so command substitution won't work):
  `https://github.com/<owner>/<repo>/blob/<full-sha>/path/to/file#L4-L7`
  - The repo must match the one under review; put `#` after the filename; use range
    `L<start>-L<end>`; include at least one line of context before and after the line.

## Output format

When issues are found (example with 3):

```text
### Code review

Found 3 issues:

1. <brief description> (AGENTS.md says "<...>")

<link to file + lines with full sha>

2. <brief description> (some/dir/CLAUDE.md says "<...>")

<link to file + lines with full sha>

3. <brief description> (bug in <file and code snippet>)

<link to file + lines with full sha>
```

When no issues are found:

```text
### Code review

No issues found. Checked for bugs and convention compliance.
```

---

> Adapted from the `code-review` plugin in `anthropics/claude-plugins-official`,
> licensed under Apache-2.0. Vendor-neutralized: model names, `CLAUDE.md`-only framing,
> tool-specific frontmatter, and product branding removed.
