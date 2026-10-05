---
name: recall
description: >-
  Searches past agent sessions (Claude Code and Codex transcripts), live git
  state, and the shared record to rebuild recent working context, then hands
  back a tight current-state brief. Use when the user says "recall", "recall my
  work on X", "what did we do last time", "find that session where",
  "catch me up", "what have I been working on", or "where did I leave off".
---

# Recall

**Before you start or resume work, you rebuild the user's recent working context and hand back a tight capsule of where things stand now and what to do next.**

Keep it tight and on-topic. Read only what the in-scope threads need, then stop.

Your context lives in two records. Your own chat history holds what you did and decided. The shared record holds everything that happened around the same code under other names: the symptoms users keep reporting, the fixes that shipped and got reverted, the errors still firing in prod. That second record is what the **why** skill searches, across source control, PR and issue discussion, and any connected tracker, chat, docs, or error-tracking MCP. A feature with a long bug tail keeps most of its story there, so don't reconstruct it from your transcripts alone.

## Where transcripts live

**Claude Code.** `~/.claude/projects/<slug>/<session-id>.jsonl`, one file per session. `<slug>` is the absolute working directory with every `/` and `.` replaced by `-`, so `/Users/you/.dotfiles` becomes `-Users-you--dotfiles`. If unsure, `ls ~/.claude/projects | grep <repo-name>`.

- Git worktrees get their own slug (`<repo-slug>--claude-worktrees-<name>`). When the scope is a repo, include its worktree slugs too.
- Subagent transcripts live in `<session-id>/subagents/agent-*.jsonl`. Skip them as noise unless the question is about what a subagent did.
- Each line is one JSON record with a `type`. The ones that matter:
  - `type == "user"`: `.message.content` is a string (typed prompt) or an array of blocks. Text blocks are `{type: "text", text}`. Blocks with `type == "tool_result"` are tool output, not the user. Lines with `isMeta == true` are injected, not typed.
  - `type == "assistant"`: `.message.content` is an array of blocks with `type` `text`, `tool_use` (`.name`, `.input`), or `thinking`.
  - `type == "custom-title"`: `.customTitle`, the session title. `type == "pr-link"`: `.prNumber`, `.prUrl`. `type == "last-prompt"`: `.lastPrompt`.
  - Every message record carries `.timestamp`, `.cwd`, `.gitBranch`, `.sessionId`.
- Typed user text that starts with a tag such as `<system-reminder>`, `<task-notification>`, `<command-name>`, `<local-command-stdout>`, or `<bash-input>` is harness noise. Drop it before reading for intent.

```bash
P=~/.claude/projects/<slug>
# Sessions in the window, newest first, by real mtime (never by UUID name)
find "$P" -maxdepth 1 -name '*.jsonl' -mtime -7 -print0 | xargs -0 -r ls -t
# Which sessions mention the topic
grep -l -i '<topic>' "$P"/*.jsonl
# Session title, branch, and PRs
jq -r 'select(.type=="custom-title") | .customTitle' "$F" | tail -1
jq -r 'select(.gitBranch) | .gitBranch' "$F" | sort -u
jq -r 'select(.type=="pr-link") | .prUrl' "$F" | sort -u
# What the user typed (drops tool results and injected lines)
jq -r 'select(.type=="user" and .isMeta != true) | .message.content
  | if type=="string" then . else (map(select(.type=="text") | .text) | join("\n")) end
  | select(length > 0 and (startswith("<") | not))' "$F"
# What the assistant said
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' "$F"
# Tools it ran, for "what did the agent actually do"
jq -c 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | {name, input}' "$F"
```

**Codex.** `~/.codex/sessions/YYYY/MM/DD/rollout-<timestamp>-<id>.jsonl`, all projects mixed. Filter by working directory through the `session_meta` record.

- `type == "session_meta"`: `.payload.cwd`, `.payload.id`, `.payload.git`, and `.payload.parent_thread_id` (non-null for sub-threads; skip those as noise).
- `type == "event_msg"` with `.payload.type == "user_message"`: `.payload.message` is what the user typed. Prefer this over `response_item` user messages, which also carry injected context.
- `type == "event_msg"` with `.payload.type == "agent_message"`: `.payload.message` is the assistant reply.

```bash
# Sessions in the window for this cwd
find ~/.codex/sessions -name '*.jsonl' -mtime -7 -print0 | xargs -0 -r ls -t | while read -r F; do
  jq -e --arg cwd "$PWD" 'select(.type=="session_meta" and .payload.cwd==$cwd)' "$F" >/dev/null && echo "$F"
done
# What the user typed / what the agent said
jq -r 'select(.type=="event_msg" and .payload.type=="user_message") | .payload.message' "$F"
jq -r 'select(.type=="event_msg" and .payload.type=="agent_message") | .payload.message' "$F"
```

## Steps

1. Classify, then route. If the user wants one specific past session ("find that session where..."), run one search subagent that returns the matching sessions in the schema below, plus the path and session id, and tell the user how to reopen it (Claude Code: `claude --resume <session-id>`; Codex: `codex resume`). A human-readable summary of your work is a different task. Recall loads working context across recent chats before you act. If the user already gave you a full state capsule (paths, branch, the change), use it and skip the mining.
2. Lock the scope before searching. Pin the window ("recent" is a real range, default the last 7 days), the topic if named, the tools (default both Claude Code and Codex, whichever has transcripts), and the workspace (default the active one. Never read another project's transcripts without being asked). State the scope back. Never quietly turn "all" into "recent N".
3. Fan out across your chat history. Spawn parallel subagents on a fast model (Claude Code: the Agent tool, `subagent_type: Explore`, `model: haiku`), each taking a slice of the corpus. Give every subagent the "Where transcripts live" section above. Tell it to order candidates by real modification time and never by UUID name, grep the topic first and then read only the matching chats and only their relevant regions, and skip the current chat plus obvious noise (subagent, eval, and test chats). Each returns the same schema, one block per chat:
   - **Chat:** tool (Claude Code or Codex), session id, date, title if any
   - **Topic**
   - **User's goal**
   - **Decisions**
   - **Open threads**
   - **Struggles and corrections**
   - **Artifacts** (PRs, tickets, branches, files)

   For one or two chats, use a single subagent instead of a fan-out. Either way, the raw transcripts stay in the subagents. The main thread gets only their findings, never transcript dumps.
4. Sweep the shared record when the topic names a feature, subsystem, or bug and the chat history alone leaves the current state unclear. Hand it to the **why** skill's lane investigators, but steer their question from "why was this built this way" to "what's the current state, what's been tried and didn't hold, and what are users still reporting". Reuse its per-lane playbooks, run the investigators in parallel with the chat-history mining, and inherit its posture: one investigator per lane, null results are findings, skip an MCP lane that isn't connected and say so. Fold what comes back into the brief. Skip this step only for pure activity recall with no named target ("what did I do this week"), where your own history and live state are the entire answer.
5. Verify against live state. Take the PRs, branches, and tickets that the mining and the sweep surfaced and check them with `git` and `gh`. When the answer hinges on what an agent actually did (the tools it ran, files it read, errors it hit), have a subagent read the full transcript, not just a grep hit.
6. Write the brief to the contract below. Group by thread. Stay on the named topic.

## Output contract

Lead with the capsule, then the thread status, then the problems, then the next move. Deeper detail goes below or gets cut.

- **Capsule.** At most 5 bullets. What this work is and where it stands overall.
- **Threads.** One line each, prefixed with exactly one status tag: `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`. A thread with no tag is not done yet, so tag it.
- **Problems.** At most 5, the recurring ones. Include the symptoms users keep reporting and any fix that shipped and was reverted, so the next attempt starts where the last one failed.
- **Next move.** The single most useful next action, concrete.

An adjacent feature or ticket stays out unless it blocks this one. When the capsule and thread lines outgrow a screen, cut detail before you cut threads. Write the brief with the **simple-english** skill, cite chat findings by session id and shared-record findings by their source (PR #, ticket ID, chat permalink, error-tracker issue), and sanitize private context before any public output.

**Reply:** the brief, to the contract above.
