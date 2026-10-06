# Refactoring

Apply when the task is a behavior-preserving change to structure or shape (rename, extract, inline, dedupe, move).

**You own the contract. The structure changes. The behavior does not.** Distinct from Feature, which adds behavior, and Bug fix, which corrects it.

If the cleanup reveals a missing feature or a real bug, split it out and ship the structural change first against the pinned contract. A redesign is allowed, but name it and route to `playbooks/feature.md`. Large or cross-cutting structural work gets split into a sequence of verifiable units first (`principles/sequence-verifiable-units.md`).

1. Pin the behavior contract first. Run the **how** skill over the affected subsystem to learn the contract, then write a characterization test, snapshot, or equivalence harness that captures current behavior before any structure moves (`principles/test-behavior-not-implementation.md`). If the area has no coverage, write the pin before touching structure. Type check and lint are not a pin.
2. Name the structure the code is missing (`principles/model-the-domain.md`). Boring code stays when the shape is already clear and local. The reshape must delete branches or invalid states, not add indirection.
3. Name the target shape. State what the module layout, types, and call graph should be if built today, as if the current requirements had been foundational from day one (`principles/foundational-thinking.md`). If the target crosses a function boundary, sketch two or three candidate shapes and compare them before the move.
4. Subtract before you add. Delete dead code, collapse one-caller wrappers, drop redundant validators, and remove orphan references before introducing the new shape (`principles/subtract-before-you-add.md`). The smallest change that reaches the target shape ships. A speculative cleanup that "might help" gets reverted.
5. Move in small behavior-preserving steps, each keeping the pin green. For API reshapes, migrate every caller and delete the old API in the same wave. No compatibility shims, no parallel old-and-new paths. Spot-check every rename against the actual files. Renames silently miss usages in strings, prose, and back-references. Delegate the mechanical edits to a fresh subagent with a specific scope (file paths, the names being moved, the behavior to hold), or build a codemod (`principles/build-the-lever.md`).
6. Prove behavior is unchanged on the real artifact, not "it compiles" (`principles/prove-it-works.md`). For larger reshapes, run an equivalence check: a script that diffs old-vs-new outputs, a recorded baseline replayed against the new code, or a smoke run on the real surface.
7. Confirm the change is worth keeping. The success measure is reduced reader load (`principles/minimize-reader-load.md`). If the diff does not lower reader load somewhere, revert it.
8. Rebase into small ordered commits. A subtraction commit, then the reshape, then any follow-on cleanup, each green before the next (`principles/sequence-verifiable-units.md`).
9. If the user asked for a commit or PR, use the **opening-pull-requests** skill. Otherwise stop at the verified diff and say it is ready to commit.

**Reply:** the structure that changed, the pin you held it against, the equivalence proof, the reader-load delta, what shipped and what got reverted. No new behavior.
