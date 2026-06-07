---
name: creating-commits
description: >-
  Creates a conventional-commit for staged changes: a type(scope): subject under
  72 characters in imperative mood, plus a body listing the changes grouped by
  area, with no co-author or AI-assistance trailers. Use when the user asks to
  commit, says "make a commit", or wants staged changes committed.
---

# Creating commits

Write a git commit for the **staged** changes. Review them first with
`git diff --staged`, then follow the rules below.

## Rules

1. Subject `type(scope): description` — `type` is one of feat, fix, docs, style,
   refactor, test, chore; scope is optional. Use imperative mood ("add" not
   "added"), keep it under 72 characters, and omit the trailing period.
2. Body: list the actual changes, grouped by file or feature area; be specific.
3. Never add co-author lines or any mention of AI assistance.

## Examples

**Input:** Added a JWT login endpoint and token-validation middleware.

```
feat(auth): add JWT-based authentication

- Add POST /login endpoint issuing access tokens
- Validate tokens in request middleware
```

**Input:** Fixed report dates showing in the wrong timezone.

```
fix(reports): use UTC timestamps for date formatting

Dates rendered in server-local time; convert to UTC before formatting.
```

**Input:** Bumped lodash and standardized error responses.

```
chore: update dependencies and standardize error handling

- Upgrade lodash to 4.17.21
- Return a consistent error shape across endpoints
```
