# Bug fix

Apply when a reported defect must be reproduced, root-caused, and fixed with runtime evidence.

**You own this task. Plan, review, verify.** Delegate bulky investigation or a multi-file fix to subagents. Do small fixes yourself.

Be scientific. Every shipped line traces to runtime evidence. Belt-and-suspenders that "might help" is a hypothesis, not a fix. It does not ship. When evidence refutes a hypothesis, revert what it motivated. The smallest change the evidence justifies ships, nothing more.

1. Reproduce it yourself on the real surface. Drive the browser, simulator, or CLI yourself (Claude Code: the built-in browser / iOS simulator tools / Bash), even when a debug or instrumentation protocol says to ask the user to reproduce. Ask the user only with a stated, specific reason you cannot reach the target, and only after driving it as far as it goes. If it won't reproduce directly, synthesize the trigger, tighten conditions, or instrument until it fires.
2. Binary-search the cause (`principles/fix-root-causes.md`). Form the candidate hypotheses, then rule them out until one survives. When the subsystem is unfamiliar, seed them with the **how** skill. When it worked before, use the **why** skill for regression history. Each pass, take the split that cuts the most remaining problem space, get runtime evidence, eliminate. When program state is unclear, add instrumentation or logging and read it as the code runs. Don't guess. Confirm the surviving *mechanism* with runtime evidence before planning the fix.
3. If two fixes that share one premise have already failed, stop and question the premise (`principles/attack-the-premise.md`) instead of writing a third.
4. Write the failing test with the **tdd** skill when the bug has a cheap local test path. Skip it when the test would be expensive, integration-heavy, or unclear.
5. Plan the fix. For a multi-file fix, delegate to a fresh subagent with a specific scope (file paths, the mechanism, the repro).
6. For a risky fix (shared code, a hot path, a public API), run the **blast-radius** skill before landing it.
7. Verify on the same surface (`principles/prove-it-works.md`). The original repro now passes. "Inconclusive" or wrong-surface is not a pass. Flag it. Unit tests show branch behavior, not bug absence.
8. Stage the commits so the failing repro lands before the fix in git history (`principles/sequence-verifiable-units.md`).
9. If the user asked for a commit or PR, run `playbooks/opening-a-pr.md`. Otherwise stop at the verified diff and say it is ready to commit.

**Reply:** what was broken, root cause, fix, how you verified. Paste failing-then-passing repro output verbatim.
