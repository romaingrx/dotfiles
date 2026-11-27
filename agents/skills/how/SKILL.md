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

Explore the codebase to answer "how does X work?" questions.

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

## 1. Explain

Hand the question to one fresh read-only subagent that explores and explains in one pass. If your harness cannot spawn subagents, do it yourself with the same brief and make no file edits. Give it the user's question and this brief:

> You are writing an architectural explanation for a senior engineer. Explore the codebase and write an explanation that a senior engineer unfamiliar with this area could read and walk away with a solid mental model. They should understand the architecture well enough to start working in it confidently. You have read-only access to the codebase.

## 2. Present

Present the subagent's output. Light edits for clarity or context from the conversation are fine. Do not substantially rewrite it.

Answer a narrow question in a few paragraphs in the reply. For a subsystem-sized
explanation, publish it as a rendered page with the diagrams drawn if your
harness can (an artifact or similar), and reply with the link and the overview.
Otherwise write it as markdown in the reply, with Mermaid for flows.
