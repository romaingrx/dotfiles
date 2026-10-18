# Source playbooks

The why skill spawns one investigator per lane, each reading a single playbook below. The three default lanes always run (or run inline for small questions). The optional lanes run only when a matching MCP is connected and the question warrants the full scale. The Linear playbook is the worked example. Adapt their shape (search terms, date window, verbatim quotes) for any other connected MCP.

| Lane | Playbook | Runs when |
|---|---|---|
| Code and in-repo | [`code-archaeology.md`](./sources/code-archaeology.md), section "Lane: code and in-repo" | Always |
| Git history | [`code-archaeology.md`](./sources/code-archaeology.md), section "Lane: git history" | Always |
| PR and issue discussion | [`code-archaeology.md`](./sources/code-archaeology.md), section "Lane: PR and issue discussion" | Always (needs `gh`; if `gh` is missing or unauthenticated, record the gap) |
| Issue tracker | [`linear.md`](./sources/linear.md) | If a Linear MCP is connected |
| Any other team-history MCP | adapt [`linear.md`](./sources/linear.md) | If one is connected |

GitHub Issues belong to the PR and issue discussion lane, through `gh`. The issue / ticket tracker lane is for a separate tracker.

Cross-cutting:

- [`incident-postmortem.md`](./sources/incident-postmortem.md). Add this if the target code looks defensive (null checks, retry, timeout, rate limit, feature flag, egress guard, OOM handler).
