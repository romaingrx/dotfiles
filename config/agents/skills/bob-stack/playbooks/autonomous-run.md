# Autonomous run

Apply when a long task must be driven to completion without stopping ("run until done", "going to bed, keep going", "loop until X").

**You own the exit condition. Define done, then drive to it without stopping.**

1. State the exit condition as a checkable predicate before the first iteration (tests green, repro fixed, all N PRs merged, pixel-diff zero). "Looks good" is not a predicate.
2. Pick the wake mechanism. An event to watch (CI, a merge, a ref advancing) gets a background watcher that wakes you on the event, with a long time-based heartbeat as fallback. No event gets a fixed-interval heartbeat sized to when the result is worth re-checking. Without background processes, poll at that interval yourself.
3. Each iteration makes the smallest change the evidence justifies, verifies it against the predicate, commits if it advanced, discards changes that didn't help. Belt-and-suspenders that "might help" gets reverted, not left to ride. Verify each unit before the next instead of batching checks at the end (`principles/sequence-verifiable-units.md`).
4. Mid-run discoveries are yours. Address broken skills, related bugs, flaky verifiers, tooling failures, and fixable drift yourself. Put out-of-band fixes in their own commit. Do not park reversible work for the user. Surface only irreversible actions, genuine product or preference calls no experiment can settle, or a real dead end. Keep the predicate as the main drive, and return to it after each side fix.
5. Checkpoint every iteration with one line in the resume note (`"$(git rev-parse --git-dir)/resume.md"`): what changed, whether the predicate moved, and a pointer to the evidence.
6. Keep the main context lean. Route bulk output and long reads to subagents and keep summaries in the main thread (`principles/guard-the-context-window.md`).
7. Stop when the predicate is met. A plateau means pivot, not stop: change the approach to push past it. Surface a genuine dead end rather than spinning, and never relax the predicate to declare victory.

**Reply:** the exit condition, iterations run, what landed, what was discarded, final predicate state, and the path to the resume note.
