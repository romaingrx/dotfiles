# Investigation

Apply when the request is a read-only question: how does X work, why was Y built this way, are we sure about Z, should we do X or Y.

**You own the answer. Plan, route, write.**

Investigation requests are read-only. They produce a cited explanation or a recommendation, not a code change.

1. Route the question. "How does X work" goes through the **how** skill. "Why is it this way" goes through the **why** skill. A question that needs both runs both.
2. Produce the `how`-shaped output (Overview / Key Concepts / How It Works / Where Things Live / Gotchas), or a recommendation with a tradeoffs table if the request is a decision between alternatives. Cite a file and line, a commit, or a command output for every claim.
3. Apply the **simple-english** skill to the reply.

No PR and no code change. If the investigation precedes a code change, hand back to the user and re-route to `playbooks/bug-fix.md` or `playbooks/feature.md`.

**Reply:** the investigation output. For "are we sure?" answers, include your real judgment with reasons. Push back if the premise is wrong.
