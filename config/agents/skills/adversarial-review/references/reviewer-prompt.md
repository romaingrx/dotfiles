# Reviewer prompt

Replace the placeholders with the request, relevant files, and available evidence.
Use one fresh reviewer for a coherent change.

```text
Review this change for actionable defects in its approach and implementation.

Request: <user's intended outcome and constraints>
Diff: <diff source or paths>
Instructions: <applicable convention files and local skill paths>
Verification: <executed commands and results, including limitations>

Check correctness, architecture, duplication, repository conventions, and scope.
Read the actual files and relevant callers.
Use focused checks when needed to establish a finding.
Do not repeat passing checks without a concrete concern.
Keep the author's workspace read-only. Use an isolated copy for experiments requiring edits.

Report concrete findings in severity order, with file:line, failure scenario, and rationale.
Use MUST-FIX, SHOULD-FIX, or NICE-TO-HAVE.
Distinguish uncertainty from a verified defect.
Return SHIP when no actionable defect remains.
Summarize review coverage and material verification limits.
```
