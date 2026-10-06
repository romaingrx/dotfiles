# Feature

Apply when the task adds or changes behavior, built from a named data shape.

**You own the design. Plan, review, verify.** Delegate implementation. Stay in the lead.

1. Run the **how** skill over the affected subsystem.
2. Name the data shape and its organizing structure before any logic (`principles/model-the-domain.md`, `principles/foundational-thinking.md`): a state machine over scattered booleans, a table or registry over branching, a typed model over repeated shape assumptions. If the shape crosses a function boundary, sketch two or three candidate shapes and compare them before you pick one.
3. Write the throughput checkpoint as four todo items. A dimension that genuinely does not apply (single file, no fan-out) keeps its item with `n/a: <reason>` rather than being dropped:
   - **Blocking first steps.** Gates run before fan-out.
   - **Independent workstreams.** Disjoint files, services, or layers parallelize. Shared writes serialize.
   - **Shared mutable state.** Default to splitting the target (`principles/separate-before-serializing-shared-state.md`). Serialize only for real invariants.
   - **Smallest safe decomposition.** If one worker is best, name why.
4. Delegate code-writing to a fresh subagent with a specific scope: file paths, the named data shape, and success criteria. The gain is review separation, so do not skip it to save lines. Keep a comment only for a non-obvious why. Port shared-primitive improvements to all consumers and verify each. Commit liberally.
5. Verify on the real surface yourself (`principles/prove-it-works.md`). Drive it yourself (browser, simulator, or CLI, with whatever tools your harness provides). "Inconclusive" or wrong-surface is not a pass. Flag it.
6. Rebase into small, ordered commits (`principles/sequence-verifiable-units.md`), building, verifying, and committing each unit before the next. Stack follow-ups.
7. If the design is contested, run the **adversarial-review** skill before shipping.
8. If the user asked for a commit or PR, use the **opening-pull-requests** skill. Otherwise stop at the verified diff and say it is ready to commit.

Code-coupled work (one feature, one migration) goes to a single owner with the checkpoint inline. Parent-level fan-out is for slices that produce independent artifacts (audits, cross-subsystem investigations, competing experiments). Rewrite the checkpoint at phase boundaries. Spawn a fresh owner rather than chaining interrupts.

**Reply:** what you built, what you chose and why, the throughput checkpoint, open decisions. Tables for design alternatives.
