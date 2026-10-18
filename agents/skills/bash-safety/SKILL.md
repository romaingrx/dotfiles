---
name: bash-safety
description: >-
  Enforces safe bash scripting when writing, reviewing, or fixing shell
  scripts: ShellCheck first, then the strict-mode, portability, and injection
  traps static analysis misses. Use when editing .sh/.bash files, reviewing
  shell scripts, fixing shellcheck warnings, or writing new bash code.
---

# Bash safety

## 1. Run ShellCheck first

```bash
shellcheck -o all script.sh
```

Fix every finding, then re-run until clean. It catches quoting, word
splitting, `ls` parsing, `echo` with data, redirection order, `local x=$(cmd)`,
and most other classic pitfalls. If it is not installed, use
`nix run nixpkgs#shellcheck -- -o all script.sh`.

## 2. Script header

```bash
#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
```

Options go in `set`, not the shebang. Strict mode has holes that ShellCheck
does not flag:

- `set -e` is ignored inside a function called as a condition (`f && ...`,
  `if f`) and inside command substitutions. Check those exits explicitly.
- `pipefail` fails `producer | head` when the producer gets SIGPIPE. Guard
  that pipeline or drop `pipefail` around it.
- `set -u` treats an empty array as unset before bash 4.4. Use
  `${arr[@]+"${arr[@]}"}` when a script must run there.

## 3. Traps static analysis misses

- **macOS `/bin/bash` is 3.2.** No associative arrays, `mapfile`, `${var,,}`,
  or `&>>`. Target 3.2 or require a newer bash explicitly.
- **zsh is not bash.** zsh does not word-split unquoted variables, so a
  one-liner that works in your zsh prompt can break in a bash script, and the
  reverse. Test the script with the interpreter in its shebang.
- **BSD vs GNU tools.** `sed -i` needs `sed -i ''` on macOS. Prefer
  `sed ... > tmp && mv tmp file`. Never read and write the same file in one
  pipeline.
- **Injection.** No `eval` on data. Validate a value before it reaches an
  arithmetic context or an array index. With `find -exec sh -c`, pass the path
  as `"$1"` (`sh -c '... "$1"' _ {}`), never inline `{}`.
- **Pipelines run in subshells.** A variable set inside `cmd | while read`
  is lost. Use `while read ...; done < <(cmd)`.
- **Dependencies.** Fail early on missing tools:
  `require() { command -v "$1" >/dev/null || { printf 'missing: %s\n' "$1" >&2; exit 127; }; }`

## Reference

[reference.md](reference.md) has the full rule catalogue (40+ rules with
examples, by category). Read the relevant section when ShellCheck flags
something you need to understand, or when reviewing a script line by line.

---

> Adapted from [tenstorrent/tt-metal](https://github.com/tenstorrent/tt-metal),
> licensed under Apache-2.0.
