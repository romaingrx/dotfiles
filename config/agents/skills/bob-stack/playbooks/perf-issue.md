# Perf issue

Apply when a measured slowness must be traced and improved against a baseline.

**You own the measurement story. Plan, review, verify the numbers.** Tie every fix to a measurement, don't read source instead of measuring.

1. Capture a baseline trace on the real surface. Vet the baseline, and every later number, with the **benchmark-checklist** skill before you report or act on it.
2. Find what limits the number (`principles/explain-the-number.md`). Run the **how** skill to ground hypotheses. Don't claim a perf ceiling without running it first.
3. Try the performance mantras in order, cheapest first. When an earlier mantra meets the target, stop.
   1. Don't do it. Stop work whose result nothing uses rather than cheapening it.
   2. Do it, but don't do it again.
   3. Do it less.
   4. Do it later.
   5. Do it when they're not looking.
   6. Do it concurrently.
   7. Do it cheaper.
4. Plan the fix from the trace. Delegate implementation to a fresh subagent with a specific scope. Review the diff. Verify each attempt before trying the next (`principles/sequence-verifiable-units.md`).
5. Capture a post-fix trace under the same conditions as the baseline.
6. Parse and compare the artifacts (JSON to sqlite, diff). "Inconclusive" or wrong-surface is not a pass. Flag it.
7. Cite the measurement in the PR, in `before -> after` form with its unit.
8. If the user asked for a commit or PR, run `playbooks/opening-a-pr.md`. Otherwise stop at the verified diff and say it is ready to commit.

**Reply:** baseline number, post-fix number, delta, artifact path.
