# Incident & Postmortem Context

Not a separate source, a **cross-cutting angle**. Incidents often motivate defensive code ("we added this check after the X outage"), so if the target looks defensive (null checks, retry logic, timeout handling, rate limiting, feature flags), specifically hunt for incident history inside every lane that runs. The optional lanes apply only when their MCP is connected:

- **Linear** (if connected): look for tickets labeled `incident`, `sev-*`, `postmortem-action-item`, `reliability`
- **Code and in-repo**: comments or tests that name an incident, outage, or ticket ID near the target
- **PR and issue discussion**: PRs and GitHub issues labeled `incident`, `bug`, or `regression`, and PR bodies that link a postmortem
- **Git**: commits with messages like "fix for incident", "add defensive check", "revert" followed by "re-apply with..." are strong signals

If you find an incident link, fetch the full postmortem. Postmortems typically have an "Action Items" section that ties directly to code changes. When several sources corroborate (a Linear ticket links the PR, which links the postmortem, and a test names the incident), the evidence is especially strong.

Worth spending time on when the code's defensive character makes an incident-driven origin plausible. Skip it for code that doesn't look defensive.
