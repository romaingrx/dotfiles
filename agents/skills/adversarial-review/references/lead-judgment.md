# Lead judgment

The reviewer was aggressive on purpose. It saw a diff and a short intent statement. You hold the full
conversation: what was tried and rejected, constraints outside the code, which parts are scaffolding, and
what the next change will address. Filter the findings with that context. Do not aggregate them.

## Dismiss

- **Nitpick gravity.** Reviewers fill the space. When every finding is a nit or a style preference, the
  change is probably fine. Say so.
- **Hypothetical vs. actual.** "What if this is null?" is a finding only if a caller can pass null. Trace the
  call site. Dismiss it when upstream validation or the type system rules it out.
- **Premature abstraction.** An extracted helper or new interface earns its place only if the code must change
  in a second way. If not, inline code that works wins.
- **"I would have done it differently."** A preference is not actionable unless it names a concrete problem
  with the current approach.
- **Missing context.** Findings on code the change did not touch, on patterns consistent with the rest of the
  codebase, or that conflict with constraints you know about.

## Keep

- Two reviewers raised it independently (consensus signal).
- It names a concrete execution path, not a hypothetical.
- It exposes a gap in your own model of the code. You read it and think "...yeah, actually".

Scrutinize a correctness or security finding harder before dismissing it, even from a single reviewer.

## Verdict

Report the survivors in the skill's format (`SHIP`, or `MUST-FIX` / `SHOULD-FIX` / `NICE-TO-HAVE`).
Keep MUST-FIX and SHOULD-FIX to about five items together. A longer list means you are not filtering hard enough.
Then list what you dismissed, one line each with the reason. It lets the user override your judgment.
