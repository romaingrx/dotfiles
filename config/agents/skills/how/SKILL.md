---
name: how
description: >-
  Explores the codebase and explains how a subsystem, feature, or code path
  works, at the level a senior engineer needs to build a working mental model.
  Use when the user asks "how does X work", "walk me through", "explain this
  code path", wants a walkthrough before changing something, or asks placement
  and ownership questions ("where should this live", "which package owns this",
  "is this the right layer"). Use why for motivation.
---

# How

Explore the codebase to answer "how does X work?" questions. Produce architectural explanations at the level of a senior engineer onboarding onto a subsystem, enough to build a working mental model, not so much that it reads like annotated source code.

Model roles: explorers run on a fast model. The explainer runs on the strongest model available. If your harness cannot spawn subagents, do each lane yourself in sequence with the same brief.

## Step 1. Assess Complexity

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

- **Simple** (a single module, a small utility, a narrow question such as "how does function X work"): no explorers. One explainer explores and explains in a single pass. Go to Step 2b.
- **Complex** (a subsystem spanning multiple files or services, a cross-cutting feature, a full architectural overview): spawn parallel explorers first, then hand off to the explainer. Go to Step 2a.

When in doubt, take the simple path.

## Step 2a. Explore (complex questions only)

Decompose the question into 2 to 4 exploration angles, each a distinct slice of the subsystem. Spawn all explorers in a single message so they run in parallel. Each explorer is a fresh read-only subagent.

Each explorer gets the prompt in `references/explorer-prompt.md` with its angle filled in. Then go to Step 3.

## Step 2b. Direct Explain (simple questions)

Explore and explain in one pass yourself, or hand it to one fresh subagent on the strongest model. Either way the task is read-only: no file edits.

Build its prompt from `references/explainer-prompt.md` without the explorer-findings section and without the spot-check step. Go to Step 4.

## Step 3. Synthesize (complex questions only)

Once all explorers have returned, spawn one fresh subagent to synthesize their findings into one explanation, on the strongest model. Tell it the task is read-only: no file edits.

Build its prompt from `references/explainer-prompt.md` with every explorer's findings filled in. Before it relies on the findings, the explainer spot-checks 2 to 3 load-bearing `file:line` claims against the code. The template carries this step.

## Step 4. Present

Present the explainer's output to the user. Light edits for clarity or context from the conversation are fine. Do not substantially rewrite it.

## Output Format

The explanation uses the sections defined in `references/explainer-prompt.md`, dropping any that do not apply: Overview, Key Concepts, How It Works, Where Things Live, Gotchas.
