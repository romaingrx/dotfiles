# Agent configuration

Instructions for coding agents, split by how many agents can read them.

| Path                            | Read by                              | Linked by                                 |
| ------------------------------- | ------------------------------------ | ----------------------------------------- |
| `skills/<name>/SKILL.md`        | every agent (Agent Skills standard)  | `modules/home/programs/agent-skills.nix`  |
| `claude/output-styles/<name>.md`| Claude Code only                     | `modules/home/programs/claude-code.nix`   |

Both are symlinked from the live checkout, so an edit applies to the next agent
session with no rebuild. Add a skill by creating `skills/<name>/SKILL.md`, add a
style by creating `claude/output-styles/<name>.md`, then `git add` it — the
flake only sees tracked files.

Each entry is linked on its own, never the folder, so the destinations stay real
directories. A skill or style dropped straight into `~/.claude` is machine-local
and survives a switch; only what lives here is portable across hosts.

Keep `claude/output-styles/` free of files that are not styles. Claude Code
reads every `.md` in that directory as one, so a `README.md` there would appear
in the `/config` picker as a style named "README".

## bob-stack

`skills/bob-stack/` is the entry point for non-trivial engineering work. Its
`SKILL.md` is a one-line-per-entry index. The playbooks and principles it
points to are plain files under it, not skills, so no agent lists them and they
cost nothing until a task opens one. The index routes to the other skills here:
`how`, `why`, `blast-radius`, `benchmark-checklist`, `tdd`, `show-me-your-work`,
`recall`, the review skills, and the writing and commit skills.

Add a playbook or principle by dropping a file in the folder and adding one
line to the index. Each principle ends with a "You skipped this when" line, so
an agent can audit its own diff against it.

## Skills against output styles

A skill loads on demand, in any agent, including subagents. An output style is
appended to Claude Code's system prompt and applies to every response, but only
in the main conversation — a subagent runs its own system prompt and never sees
it. Shipping a writing standard as both gives an always-on baseline in chat and
the full rule set wherever the work actually happens.

An output style also replaces Claude Code's built-in software-engineering
instructions unless it sets `keep-coding-instructions: true`. Any style here
that is about voice rather than role must set it.

## Vendored third-party content

Copied in rather than fetched, so an upstream change arrives as a reviewable
content diff instead of a lock-file hash. To update, re-download at a newer
commit and read the diff before committing.

| Content                                  | Upstream                                        | Pinned commit |
| ---------------------------------------- | ----------------------------------------------- | ------------- |
| `skills/simple-english/`                 | [AminBlg/SimpleEnglish](https://github.com/AminBlg/SimpleEnglish) (MIT) | `63f5d57`     |
| `claude/output-styles/simple-english.md` | same                                            | `63f5d57`     |

```sh
# refresh both from a chosen commit
SHA=<commit>
B="https://raw.githubusercontent.com/AminBlg/SimpleEnglish/$SHA"
curl -sfL "$B/skills/simple-english/SKILL.md"                -o config/agents/skills/simple-english/SKILL.md
curl -sfL "$B/skills/simple-english/references/checklist.md" -o config/agents/skills/simple-english/references/checklist.md
curl -sfL "$B/skills/simple-english/references/use-cases.md" -o config/agents/skills/simple-english/references/use-cases.md
curl -sfL "$B/output-styles/simple-english.md"               -o config/agents/claude/output-styles/simple-english.md
```

### Adapted from pstack

The bob-stack skills are adapted, not copied: tool-specific mechanics (model
slugs, agent modes, transcript paths) were rewritten for any agent that reads
`AGENTS.md` and skills, so there is no refresh script. To pull an upstream improvement, diff the
upstream file at a newer commit against the pinned one and port the change by
hand. License: [`third-party/pstack.LICENSE`](third-party/pstack.LICENSE).

| Content                                                              | Upstream                                                                 | Pinned commit |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------ | ------------- |
| `skills/bob-stack/` (router, `playbooks/`, `principles/`)            | [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT) | `00b52d9`     |
| `skills/{why,how,recall,blast-radius,benchmark-checklist,tdd,show-me-your-work}/` | same                                                        | `00b52d9`     |
| `skills/adversarial-review/references/lead-judgment.md`             | same (`interrogate/references/lead-judgment.md`)                         | `00b52d9`     |

The skills the repository writes itself carry no row above. They have no
upstream and are edited in place.
