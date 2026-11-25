---
name: why
description: >-
  Investigates the motivation and history behind code and returns a cited,
  confidence-tiered answer on the decisions and tradeoffs that shaped it. Use
  when the user asks "why does X work this way", "why was this built this way",
  "why did we pick Y", "what's the history of", or asks about design rationale,
  regressions, postmortems, or where a threshold came from. Use how for runtime
  behavior. A live failure to debug goes to reproduction first, not here.
---

# Why

Answer from the record, not the code: read the commits and PR discussions that introduced the target and each later change, and other sources if the trail is thin. Cite what the authors wrote, mark your own inferences as inferences, and say what the record does not answer.
