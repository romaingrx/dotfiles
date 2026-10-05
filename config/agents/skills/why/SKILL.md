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

Investigate the motivation and intent behind code.

Companion to the `how` skill. `how` answers what the code does and how it works. `why` answers what forces led to its shape.

Model roles: investigators run on a fast model (Claude Code: `model: haiku`, or `sonnet` for a long or tangled history). The synthesizer runs on the strongest model (Claude Code: `model: opus`, or inherit).

## Operating Posture

Operate as a **careful, cautious, and precise investigator**. Be honest about what you know vs what you're inferring. Read `references/epistemics.md` for the full confidence framework and phrasing guide. The synthesizer must follow it.

## Step 1. Understand the Target and the Question

Parse what the user is asking. The **target** is usually a chunk of code, a pattern, a feature, or a named design decision. The **question** is usually a design rationale, a tradeoff, a motivating edge case, an external constraint, dead code, or a broad history sweep.

If the target is vague ("why do we do it this way?" with no clear referent), make your best guess from conversation context (open files, recent edits, what was just discussed). State your interpretation briefly so the user can redirect if you're off, then proceed.

## Step 2. Establish the Code Anchor

Before spawning investigators, anchor the investigation in concrete code. You need:

- The relevant file path(s) and line range(s)
- The key symbols (function names, class names, constants)
- An initial commit list. The last few commits touching the target.
- PR numbers from merge commits (pattern `(#1234)` in the subject line)

Build this inline.

```bash
# Blame target lines for last-touch commits
git blame -L <start>,<end> <file>

# Full file history, with patches, through renames
git log --follow -p -- <file>

# Last N commits touching the file, PR numbers visible
git log --oneline -20 -- <file>

# Extract PR numbers from a commit message
git log -1 --format=%B <commit>
```

Pull PR bodies and discussion via `gh` for any substantive commits:

```bash
gh pr view <number> --json title,body,author,createdAt,mergedAt,labels,closingIssuesReferences,comments,reviews
```

Capture this as seed context (file paths, symbols, commits, PR numbers, linked ticket IDs). Pass it to the investigators.

## Step 3. Pick the Scale

Choose one of three scales. Whatever the scale, every lane in the coverage map gets a line in Sources Consulted, with a skip reason when it did not run.

### Inline (small questions)

Use this when the target is a single commit or a short history and the PR body or commit message already answers the question. Run the three default lanes below yourself, with no subagents. Follow `references/epistemics.md`, use the output format in `references/synthesizer-prompt.md`, and say in the Confidence Summary that the answer was built inline. If the inline pass turns up contradictions or a thin trail, escalate to the default scale.

### Default: three investigators

Spawn three investigators in parallel, in a single message. Each owns exactly one lane:

1. **Code and in-repo investigator.** Inline comments, TODO/FIXME notes, tests, ADRs, CHANGELOG, READMEs near the target. Best at surfacing *constraints the author wrote down next to the code*.
2. **Git history investigator.** `git log --follow`, pickaxe (`-S`, `-G`), `git blame`, `git show`, co-changed files, reverts. Best at surfacing *when the shape appeared, and what it replaced*.
3. **PR and issue discussion investigator.** `gh pr view`, `gh issue view`, `gh search prs`, `gh search issues`, review threads, linked GitHub issues. Best at surfacing *implementation-time rationale captured during review*.

### Full: scale up when the question warrants it

Add one investigator per connected optional lane when any of these hold:

- The target looks defensive (null checks, retry logic, timeout handling, rate limiting, feature flags, egress guards, OOM handlers) and an incident origin is plausible.
- The default lanes come back thin, or contradict each other.
- The question is about a product or business decision, a threshold chosen from data, or a cross-team choice.
- The user asks for a thorough sweep.

Optional lanes, each only if a matching MCP is connected in this session:

4. **Issue / ticket tracker** (if a Linear, Jira, Plane, or Shortcut MCP is connected). Best at surfacing *the product or business forcing function*.
5. **Long-form documents** (if a Notion, Confluence, Google Docs, or Coda MCP is connected). Best at surfacing *long-form design rationale written before the code*.
6. **Real-time team chat** (if a Slack, Discord, Teams, or Mattermost MCP is connected). Best at surfacing *deliberation that never reached a doc*.
7. **Infrastructure observability** (if a Datadog, New Relic, Honeycomb, Grafana, or Splunk MCP is connected). Best at surfacing *the runtime reality that motivated the code*.
8. **Error / exception tracking** (if a Sentry, Rollbar, Bugsnag, or Airbrake MCP is connected). Best at surfacing *the exceptions that motivated defensive code*.
9. **Product analytics warehouse** (if a Databricks, Snowflake, BigQuery, ClickHouse, or dbt MCP is connected). Best at surfacing *product and data reality, and where a number came from*.

### Discovery

To find connected MCPs, check the tools available in this session (Claude Code: MCP tools are named `mcp__<server>__<tool>`, and deferred ones can be found with ToolSearch). Classify each by its name, server instructions, and tool names. If an MCP could fit more than one lane, choose the one matching its primary evidence. Record ambiguous cases in the coverage map. Don't ask one agent to cover multiple lanes.

### Investigator config

Spawn each investigator as a fresh subagent (Claude Code: the Agent tool, `subagent_type: Explore` for the three default lanes; `general-purpose` for MCP lanes if your read-only agent type cannot call MCP tools). Investigators never write files, commit, or change external state.

Each investigator gets:
1. The base prompt from `references/investigator-prompt.md`
2. The lane playbook from `references/sources/`, picked from the index in `references/source-playbook.md`. For an MCP lane, adapt the example playbook to the MCP actually connected.
3. The cross-cutting `references/sources/incident-postmortem.md` **if the target code looks defensive**
4. The code anchor from Step 2 (file paths, symbols, commit hashes, PR numbers, ticket IDs)
5. The user's original question

### The coverage map

Aim for a complete **coverage map**, not a minimal one. Document the null, don't skip the search. Every lane gets one of these outcomes, written into Sources Consulted:

- **Searched**, with what was searched (verbatim queries) and what came back, including nothing.
- **Not connected.** No MCP for that lane in this session. Flag this as a gap, not a choice. Example: "Real-time team chat: not searched. No chat MCP connected, so the conversational record was not searchable."
- **Not run at this scale.** The lane is connected but the question did not trigger the full scale. Name it so the user can ask for a wider sweep.
- **Provably irrelevant.** A high bar, not "probably irrelevant." Example: "Error / exception tracking: skipped. Target is a build-time script with no runtime code path."

## Step 4. Synthesize

Spawn one synthesizer as a fresh subagent on the strongest model (Claude Code: `subagent_type: general-purpose`, `model: opus`). It may read the codebase, run `git` and `gh`, and call MCP tools to spot-check citations. It must not write files, commit, or change external state.

The synthesizer gets:
1. The investigator findings, including any null results and every lane skipped with its reason
2. The code anchor from Step 2 (file paths, symbols, commit hashes, PR numbers, ticket IDs)
3. The user's original question
4. The epistemics framework from `references/epistemics.md`
5. The synthesizer prompt template from `references/synthesizer-prompt.md`

## Step 5. Present

Take the synthesizer's output and present it to the user. You may lightly edit for clarity or add context from the conversation, but **do not rewrite the confidence language**.

## Output Format

The output structure is the one in `references/synthesizer-prompt.md`: The Question, The Code in Question, What We Found, What We Can Reasonably Infer, Competing Hypotheses, What We Don't Know, Sources Consulted, Confidence Summary. Adapt as needed, but keep the confidence separation intact, and keep Sources Consulted as one line per lane, including the ones that returned nothing or were skipped, with the reason.

After the Sources Consulted block, if the user's `why` question is a precursor to actually changing this code, convert the lineage findings into a Preserve / Change / Avoid / Risk constraint set suitable for planning the change.

## Common Failure Modes to Avoid

- **Recency bias**. Assuming the most recent commit is authoritative. The current shape is often the accretion of many earlier decisions. Trace back.
- **Sycophancy**. Confirming the hypothesis embedded in the user's question. Treat it as one candidate and check the evidence independently. See "The Sycophancy Trap" in `references/epistemics.md`.
- **Investigators concluding**. Investigators gather evidence. Only the synthesizer forms the answer.

## Reference Files

- `references/epistemics.md`. Confidence tiers and phrasing guide. The synthesizer must follow it.
- `references/investigator-prompt.md`. Base prompt template for investigator subagents.
- `references/source-playbook.md`. Index mapping each lane to its playbook.
- `references/sources/*.md`. One self-contained playbook per lane, plus cross-cutting `incident-postmortem.md`. Give an investigator the single file (or section) that matches its lane.
- `references/synthesizer-prompt.md`. Prompt template for the synthesizer subagent, including the output format.
