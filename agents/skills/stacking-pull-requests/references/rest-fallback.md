# REST fallback for stacked PRs

Use this reference only when `gh stack` fails. The usual cause is a proxy that blocks GitHub GraphQL. Claude Code cloud sessions return HTTP 403 with "GitHub GraphQL is not available from Claude Code sessions".

GitHub's stacks API is REST. GraphQL has only read-only stack fields. This method makes the same native stack as `gh stack submit`.

Set `R=repos/{owner}/{repo}` and send `-H 'X-GitHub-Api-Version: 2026-03-10'` on the stack calls.

## Create a stack

1. Create each branch on top of the branch below it. Push each branch.
2. Open each PR as a draft: `gh api -X POST $R/pulls -f head=<branch> -f base=<branch below> -f title=... -f body=... -F draft=true`. The bottom PR targets the trunk.
3. Create the stack, bottom PR first: `gh api -X POST $R/stacks -F 'pull_requests[]=101' -F 'pull_requests[]=102'`.

## Change a stack

- Add PRs on top: `POST $R/stacks/{stack_number}/add` with the same body.
- Read a stack: `GET $R/stacks?pull_request={n}`, `GET $R/stacks/{stack_number}`, or `GET $R/pulls/{n} --jq .stack`.
- Restack after a change lower in the stack: check out the top branch and run `git rebase --update-refs origin/<trunk>`. Then run `git push --force-with-lease` for each branch.
- Dissolve a stack: `POST $R/stacks/{stack_number}/unstack`.

## Merge a stack

The synchronous merge endpoint (`PUT .../pulls/{n}/merge`) does not merge stacked PRs. Use the async merge API:

1. Submit on the highest PR to merge. GitHub merges it and every PR below it, atomically:
   `gh api -X PUT $R/pulls/{n}/merge-async -f merge_method=squash -f merge_action=default -f commit_title='...' -f commit_message='...'`
2. If `status` is `pending`, poll `GET $R/pulls/{n}/merge-async/{uuid}` until `status` is `merged`, `enqueued`, or `failed`.

Auto-merge is not available for stacked PRs.

## Draft state and auto-merge in Claude Code cloud sessions

Public REST has no route to mark a PR ready or to disable auto-merge. In a Claude Code cloud session, use the proxy routes:

- `POST $R/pulls/{n}/ccr/ready_for_review`
- `DELETE $R/pulls/{n}/ccr/auto_merge`

Sources: https://docs.github.com/en/rest/pulls/stacks, https://code.claude.com/docs/en/cloud-environments#github-proxy, and the gh-stack docs (`reference/rest-api`, `reference/merge-api`).
