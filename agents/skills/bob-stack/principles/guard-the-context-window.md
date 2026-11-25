# Guard the Context Window

Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Route bulk to subagents; keep summaries in the main thread, not raw payloads.

**Why:** Context overflow degrades reasoning quality, creates compression artifacts, and halts progress.

**Pattern:**
- **Size phases and cap scope.** Limit files per phase, set turn budgets, account for mechanism costs.

You skipped this when the main thread holds a full log, a whole large file, or the same file read twice, where a subagent summary or a targeted read would have answered the question.
