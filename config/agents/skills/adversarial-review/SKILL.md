---
name: adversarial-review
description: >-
  Independent review of substantial local changes before commit, or on explicit
  request. Checks correctness, architecture, duplication, repository conventions,
  and scope; returns SHIP or ranked findings. Use when the user asks for an
  adversarial review, a hostile review, a pre-commit review, or when committing
  substantial implementation work. Complements PR-comment review and
  over-engineering review — this pass is a fresh, local adversary.
---

# Adversarial review

Use a fresh reviewer for substantial changes before the user has asked to
commit. Also use this skill when the user requests an adversarial review.
Skip mechanical edits and small documentation changes unless a specific risk
warrants review.

This pass is local and independent. It does not post a GitHub review comment
(that is `reviewing-pull-requests`) and it does not hunt over-engineering
(that is `ponytail-review`).

## Procedure

1. Give the reviewer the request, diff, relevant instructions, and existing
   verification results.
2. Launch one fresh subagent with [the reviewer prompt](references/reviewer-prompt.md),
   when delegation is available and permitted.
3. Review the findings against the actual code and requested behavior.
4. For implementation tasks, fix confirmed defects and explain declined material
   findings. For review-only requests, report findings without editing.
5. Repeat affected checks after fixes. Complete the review before committing.

If delegation is unavailable, perform a local review and disclose that
independence was unavailable.
An explicit review request can examine incomplete code; report failed or
unavailable checks as limitations.
Do not repeat passing tests without a concrete concern.

## Review criteria

- Correctness: failure paths, races, security, and data integrity.
- Architecture: responsibilities and package or module boundaries.
- Duplication: existing code that supplies the same behavior.
- Repository conventions: applicable instruction files and explicit user exceptions.
- Scope: the requested outcome without unrelated work or speculative abstractions.

Read the files and relevant callers. Use focused experiments where evidence is
missing. Run destructive experiments only in an isolated disposable workspace.
Do not revert or modify the author's working files during review.

Convention files are whatever the repo actually uses: a root `AGENTS.md` or
`CLAUDE.md`, `CONTRIBUTING.md`, nested copies in directories the change
touches, and local skills under `.agents/skills/`, `.claude/skills/`, or
`.cursor/skills/`. Read the ones relevant to the diff; do not invent project
rules that are not written down.

## Findings

Return `SHIP` when no actionable defect remains.
Otherwise, rank findings as `MUST-FIX`, `SHOULD-FIX`, or `NICE-TO-HAVE`.
Each finding needs a location, concrete failure scenario, and rationale.
Distinguish verified defects from uncertainty; uncertainty alone does not
establish a defect.
Summarize covered criteria without requiring a separate section for each one.

---

> Adapted from `.agents/skills/adversarial-review` in `operad-hq/operad`
> (`f4c87ce`). Vendor-neutralized: `AGENTS.md`-only framing and
> "authorized commit" session language replaced with repo-agnostic equivalents.
