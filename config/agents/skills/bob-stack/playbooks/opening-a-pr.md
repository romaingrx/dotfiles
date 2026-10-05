# Opening a PR

Apply when the user asks to commit or open a pull request for finished work.

If the repo's own `CLAUDE.md` or `AGENTS.md` has PR, branch, or commit rules, those win over the steps below.

1. Work on a branch named `<user>/<kebab-topic>`, ideally in a git worktree off main. Dirty branch with unrelated work: move the patch out, make a fresh worktree, apply it there. Snarled worktree: reset from main, redo minimally.
2. Clean the diff. Run the **ponytail-review** skill over it and cut what it flags. Keep a comment only for a non-obvious why.
3. For substantial work (a new design, a cross-cutting change, a risky fix), run the **adversarial-review** skill before committing. Fix or answer each finding.
4. Commit with the **creating-commits** skill: Conventional Commits `type(scope): subject`, imperative, no trailing period, no Co-Authored-By or AI-assistance trailers. Commit liberally, then rebase into small, ordered commits. Each commit is landable and ordered to tell the story. Amend when the fix belongs in a just-made commit. New commit when separable.
5. Size the PR. Prefer five narrow PRs to one large PR. A chain of dependent PRs goes through the **stacking-pull-requests** skill. Branch from trunk only for independent work.
6. Write the PR body with the **simple-english** skill. It is a briefing, not the lab notebook. A reviewer who has the diff should learn why the change exists, what it leaves out, what it could break, and how you proved it works, in under a minute. Use this shape and drop a section with nothing to say:
   - `## <short heading>` then one to three sentences on the problem and the approach.
   - `### Design` names the shape you chose and only the rejected alternatives a reviewer would ask about.
   - `### Verification` has one to three bullets, each a real run path and its outcome. For a perf change, one primary number with its unit in `before -> after` form. Link screenshots or logs when they prove a claim.
   - `### Notes` covers scope left out, follow-ups, and blast radius.
   Do not paste full SHAs, file-by-file checklists, or "CLEAN" verdicts.
7. Push and open the PR as a draft: `gh pr create --draft --title "<type(scope): subject>" --body-file <file>`. Run `gh pr view <number>` before you refer to PR status.
8. Treat every review verdict as tied to the head SHA it reviewed. A new push voids it. Re-run the review on the new head before you call the PR verified.
9. Post the URL and keep building. Opening a PR does not start a babysit. Watch CI or review threads only when the user asks, after the whole stack exists. Push back when feedback drifts from intent.

**Reply:** the PR URL as `https://github.com/<owner>/<repo>/pull/<number>`, the commits in it, the verification evidence, and the head SHA any review verdict covers.
