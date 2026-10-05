# Code Archaeology (git + gh + in-repo)

The three default lanes all live here. Each investigator gets the shared sections plus only its own lane section.

## What this source contains

- Commit history (messages, dates, authors, diffs)
- PR descriptions, review comments, and discussion threads (via `gh`)
- GitHub issues linked from PRs and commits (via `gh`)
- Inline code comments, TODOs, FIXMEs, deprecation notes
- ADRs (architectural decision records) if the repo keeps them
- Tests. Names and assertions often encode the edge cases that motivated a change
- Related files modified in the same commits (co-change signal)
- CHANGELOG entries, release notes in the repo
- Issue/ticket IDs mentioned in commit messages and PR bodies

The most trustworthy source, tied directly to the code, and the most complete. Everything that went through the repo should be here.

## Lane: code and in-repo

Look for out-of-band docs and notes near the target:

```bash
# ADRs often live in docs/adr/ or similar
rg -l -i 'architecture.decision' --glob '*.md'

# TODOs and FIXMEs near the target
rg -n -C2 '(TODO|FIXME|HACK|XXX|NOTE)' <target_file>

# Related tests. Names often encode the "why"
rg -l '<symbol>' --glob '*test*'

# CHANGELOG and docs that mention the symbol or feature
rg -n -i '<symbol_or_feature>' --glob '*.md'
```

Read the comments and tests as text someone wrote, not as the code's behavior. A comment that states a constraint is evidence. The code it sits on is not.

## Lane: git history

Expand the seed commit list:

```bash
# Full history of the file through renames
git log --follow --oneline -- <file>

# Pickaxe: commits that added or removed this exact text
git log -S '<exact_string_from_code>' -- <file>

# Or for patterns:
git log -G '<regex>' -- <file>

# Who wrote each line and when
git blame -L <start>,<end> <file>

# Blame past whitespace and moved code
git blame -w -C -C -L <start>,<end> <file>

# The full diff of a specific commit
git show <hash>

# Commits between two points affecting this file
git log <old>..<new> -p -- <file>

# Reverts and re-applies touching the file
git log --oneline -i --grep='revert' -- <file>
```

Record PR numbers and ticket IDs from commit messages under "Additional Leads" for the PR and issue discussion lane.

## Lane: PR and issue discussion

For each substantive commit, pull the PR context:

```bash
# Find the PR number from the merge commit or branch
git log -1 --format=%B <hash>

# Full PR context: body, review comments, linked issues
gh pr view <number> --json title,body,author,createdAt,mergedAt,labels,closingIssuesReferences,comments,reviews,files

# Line-level review comments (not included in `gh pr view`)
gh api repos/{owner}/{repo}/pulls/<number>/comments

# Linked or mentioned GitHub issues
gh issue view <number> --json title,body,author,createdAt,closedAt,labels,comments

# PRs and issues that mention the symbol or file but were never merged
gh search prs --repo <owner>/<repo> '<symbol_or_feature>'
gh search issues --repo <owner>/<repo> '<symbol_or_feature>'
```

The `reviews` and `comments` fields are where the real signal is. Closed-unmerged PRs often record the alternative that was rejected.

## What good evidence looks like here

- A PR description that explains the problem being solved, not just the change ("This fixes the pagination bug that caused X")
- A long review thread where alternatives were debated
- An inline comment near the target line that explains a non-obvious constraint
- A test named `test_handles_edge_case_when_X` that reveals an edge case motivating the code
- A commit message that references a ticket or incident ID
- A CHANGELOG entry that summarizes the user-visible rationale

## Common pitfalls

- **Squash-merge flatlands.** If the repo squashes PRs, individual commits in the branch history are lost. Fall back to PR body and comments.
- **Misleading commit messages.** "Small refactor" sometimes hides an intentional behavior change. Look at the diff, not the message.
- **Cargo-culted patterns.** The author may have copied a pattern without understanding why. Check if the pattern originated earlier in the codebase and investigate *that* commit.
- **Bot commits and auto-merges.** Dependabot, Renovate, and automated backports usually don't carry motivation. Skip them when trying to find intent.
- **Treating code as evidence of intent.** The code itself isn't evidence for why it exists. Evidence comes from commit messages, PRs, comments, tests, docs. Don't cite "the function is named X" as evidence of intent.
- **`gh` unavailable.** If `gh` is not installed or not authenticated, stop that lane and report the gap. Don't reconstruct PR discussion from commit messages and call it the PR.

## What to return

Every commit/PR/issue/comment that bears on the question, with:
- The exact text (quoted)
- The hash / PR number / issue number / file:line
- Author and date
- Whether it's direct (explicitly addresses the question) or circumstantial
