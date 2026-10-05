---
name: bob-stack
description: >-
  Router for substantial engineering work: matches the task to a playbook (bug
  fix, feature, refactoring, perf issue, investigation, prototype, autonomous
  run, pause, pickup, opening a PR), routes to the right skill, and applies
  named principles with self-checks. Use when the user says "bob-stack", "bob
  mode", "do it properly", "be rigorous", or "run until done", or hands over a
  bug, feature, refactor, or perf problem that spans several files or steps.
  Skip for questions, config tweaks, and small edits.
---

# bob-stack

One index. Open a playbook or principle file only when it applies. Paths below
are relative to this skill's directory.

## Start every task here

1. Match the task to a playbook below and open its file.
2. Open a todo list whose first items are that playbook's steps, copied in
   verbatim, before any task-specific todos. A step you choose not to do stays
   in the list as `skip: <reason>`. Skipping is allowed. Hiding it is not.
3. No playbook fits: write your own numbered plan in which every step ends in a
   check you can run (`principles/sequence-verifiable-units.md`).

Harnesses differ. Without a todo tool, keep the checklist in your reply. Without
subagents, do delegated work yourself in sequence with the same brief.

## Playbooks

- **Investigation.** Read-only question: how does X work, why is Y this way, are
  we sure about Z, X or Y. `playbooks/investigation.md`
- **Bug fix.** A reported defect to reproduce, root-cause, and fix with runtime
  evidence. `playbooks/bug-fix.md`
- **Feature.** New or changed behavior, built from a named data shape.
  `playbooks/feature.md`
- **Refactoring.** A behavior-preserving change to structure (rename, extract,
  inline, dedupe, move). `playbooks/refactoring.md`
- **Perf issue.** A measured slowness to trace and improve against a baseline.
  `playbooks/perf-issue.md`
- **Prototype.** A throwaway sketch to settle a design or behavioral fork by
  observing it instead of asking. `playbooks/prototype.md`
- **Autonomous run.** A long task driven to a checkable predicate without
  stopping ("run until done", "going to bed"). `playbooks/autonomous-run.md`
- **Pause safely.** Suspend in-flight work so it can resume, on an explicit
  pause or before going offline. `playbooks/pause-safely.md`
- **Session pickup.** Resume a prior agent's work from a branch, note, or
  transcript. `playbooks/session-pickup.md`
- **Opening a PR.** Committing and opening a PR, when the user asks for it.
  `playbooks/opening-a-pr.md`

## Route to skills

- "How does X work", nontrivial change, "are we sure?" → **how**.
- "Why is it like this", history of a decision, a regression's origin → **why**.
  A live failure goes to the Bug fix playbook first: reproduce before history.
- "Is this safe?", risky change before it lands → **blast-radius**.
- Measuring perf, or reporting a speedup or regression → **benchmark-checklist**
  before you trust or report the number.
- A bug with a cheap local test target → **tdd**.
- Substantial local change before commit, contested design → **adversarial-review**.
- Reviewing someone's PR and posting the result → **reviewing-pull-requests**.
- Tempted to add a layer, a dependency, or a config knob → **ponytail**. Review a
  diff or repo for bloat → **ponytail-review**.
- Committing → **creating-commits**. Stacked PRs → **stacking-pull-requests**.
- Shell scripts → **bash-safety**. Docs, READMEs, PR bodies → **simple-english**.
- Long, autonomous, or step-away work → **show-me-your-work** for a decision log.

## Principles

Read the file in full before you apply a principle. Cite only principles whose
file you read this session, and in the reply name the decision each one
changed. Each file ends with a "You skipped this when" line. Check your diff
against it.

**Core**

- **Subtract before you add.** Sequencing an addition, refactor, or rewrite.
  Delete dead weight first, then build on the simpler base. `principles/subtract-before-you-add.md`
- **Foundational thinking.** Before writing logic: core types and data
  structures, scaffold-vs-feature order, what concurrent actors share. `principles/foundational-thinking.md`
- **Attack the premise.** Two fixes sharing one premise failed the same gate.
  Question the premise before a third fix. `principles/attack-the-premise.md`
- **Build the lever.** Non-trivial work. Build the script, codemod, or check that
  does or proves it, instead of working by hand. `principles/build-the-lever.md`
- **Minimize reader load.** Code that is hard to trace. Collapse one-caller
  wrappers, shrink mutable scope. `principles/minimize-reader-load.md`

**Architecture**

- **Model the domain.** Stateful logic, or code that branches a lot. Encode the
  domain in a structure, not scattered conditionals. `principles/model-the-domain.md`
- **Boundary discipline.** Validation, error handling, adapters. Guard at system
  boundaries, trust internal types. `principles/boundary-discipline.md`
- **Type system discipline.** Designing types or signatures. Make illegal states
  unrepresentable, parse at boundaries. `principles/type-system-discipline.md`
- **Make operations idempotent.** Commands or loops that run amid crashes and
  retries. Converge to the same end state. `principles/make-operations-idempotent.md`
- **Separate before serializing shared state.** Concurrent writers to one file,
  branch, or key. Remove the sharing first. `principles/separate-before-serializing-shared-state.md`

**Verification**

- **Prove it works.** Before declaring done. Check the real artifact, not a
  proxy or "it compiles". `principles/prove-it-works.md`
- **Fix root causes.** Debugging. Reproduce first, ask why until you reach the
  cause, fix it there. `principles/fix-root-causes.md`
- **Sequence verifiable units.** Multi-step work and commit or PR order. Small
  units, each ending in a check. `principles/sequence-verifiable-units.md`
- **Test behavior, not implementation.** Writing or keeping a test. If it would
  still pass when every import returned `undefined`, rewrite or delete it. `principles/test-behavior-not-implementation.md`
- **Explain the number.** Before trusting a measured number. Name what limits it
  and rule out measuring the wrong thing. `principles/explain-the-number.md`

**Delegation and meta**

- **Guard the context window.** Large outputs, long files, fan-out. Bulk goes to
  subagents, summaries stay here. `principles/guard-the-context-window.md`
- **Encode lessons in structure.** Writing the same instruction a second time.
  Make it a lint, check, or script instead. `principles/encode-lessons-in-structure.md`

## Questions and autonomy

- Before asking the user "which approach?", classify the question. If running
  something could answer it (behavior, timing, layout, output, perf), it is not
  the user's question. Settle it with the Prototype playbook. Ask only for a
  product or preference call no experiment can settle.
- Reversible local work proceeds without asking. Pause for irreversible or
  outward-facing actions: pushing to shared branches, deploys, deleting data,
  messages to people. Repository and harness rules always win over this file.
- No is an acceptable answer. Asked whether to do something, give your real
  judgment. "This doesn't earn its place" is a valid reply.

## Subagents

- Give each subagent a complete brief: the goal, every directive the user gave
  so far, file pointers instead of pasted content, and the exact return shape.
- New work goes to a fresh subagent with consolidated scope. Resume one only
  when the work needs state that lives in it (an uncommitted checkout, a running
  process). Chained resumes silently drop directives.
- You own their output. Read the diff and write your own summary. Do not pass
  through a "done" report unchecked.
- Judge progress by side effects (files written, commits, check results), never
  by asking an agent how it is going.

## The reply

- Every claim carries its evidence or its label in the same sentence: measured,
  inferred, or guess. A prediction or an unseen cause is a guess.
- Never hand the user a check you could have run.
- Never fabricate a link, citation, or file reference. Cite only what you read
  or produced this session.
- Lead with what changes for the user of the code, then what the next
  maintainer inherits.
- Comments in code: keep one only for a non-obvious why the code cannot show.
