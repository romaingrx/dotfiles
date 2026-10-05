# Session pickup

Apply when resuming or taking over a prior agent's in-flight work from a transcript, a resume note, or a pushed branch. The complement to `playbooks/pause-safely.md`.

**You own the resume point. Read the prior trail, don't redo it.**

1. Locate the prior trail. Use the **recall** skill to find the prior session. Check for a resume note, a **show-me-your-work** decision log, a `wip:` commit, or a pushed branch. Transcripts live in `~/.claude/projects/<cwd-slug>/*.jsonl` (Claude Code) or `~/.codex/sessions/**/*.jsonl` (Codex). Stay inside the current project's transcripts. Do not read across unrelated projects.
2. Read the last messages first, then scan back for the decision points. Parse a long transcript in a fresh subagent and keep the reduced timeline in the main thread (`principles/guard-the-context-window.md`).
3. Reconstruct operational state. The branch and worktree, what already landed (`git log`, `git diff` against the base), the open todos, the exit predicate, the decisions made. The prior trail is authoritative input. Resist the bias to re-derive it.
4. Diff done vs pending. Compare what shipped against what was planned, name the resume point, and do not redo completed work. Step 6 checks the outcome once; it is not a redo.
5. Route the remaining work to the matching playbook and pick the verdict: continue the execution, ship a finished recommendation, ratify or override a prior conclusion, or postmortem a failed run. The routed playbook owns the rest.
6. Verify the inherited claims against the original goal on the real artifact (`principles/prove-it-works.md`). A passing prior self-report is not the proof.

**Reply:** where the prior agent stopped, what you inherited vs redid (ideally nothing redone), the resume point, and the outcome.
