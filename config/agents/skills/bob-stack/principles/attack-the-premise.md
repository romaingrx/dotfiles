# Attack the Premise

Apply when two or more fixes that share one premise have failed the same gate. Write the premise down and test it directly before the next fix, instead of writing another fix that assumes it.

When two or more fixes that share one premise have failed the same gate, suspect the premise, not the fixes.

**Why:** Each failure under a shared premise is evidence about the premise.

**Pattern:**
- **Write the premise down.** The premise is the one sentence that every failed fix assumed.
- **Test the premise directly.** Write a rerunnable check that measures the premise itself, not the symptom, per [Build the Lever](build-the-lever.md). When several actors (workers, threads, callers) are involved, measure per actor: a skew shows where the cause lives.
- **Follow what the check shows.** The thing that makes the premise false is the next "why" per [Fix Root Causes](fix-root-causes.md).
- **Remove the cause instead of compensating for it**, per [Subtract Before You Add](subtract-before-you-add.md). A retry, a fallback, or a periodic rebalance leaves the cause in place and adds work on every run.

**Stop:**
- Do not start the next fix before the premise is written down and checked.
- If the check shows the premise holds, the premise is not the cause. Look elsewhere and keep the check as evidence.

This principle is distinct from redesigning around a new requirement, which rebuilds a design from first principles. It questions a fact the current design assumes.

You skipped this when you start a third fix under the same premise and there is no written premise and no check of it in the diff.
