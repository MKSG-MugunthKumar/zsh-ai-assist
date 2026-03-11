---
status: deferred
created: 2026-03-11
updated: 2026-03-11
author: Claude (Opus 4.6)
co-author: Mugunth Kumar
tags: [stderr, fix-command, context]
---

# Task 001: Capture stderr for ?? (fix-last-command)

## Problem

`??` currently only knows the command text, not how it failed. The LLM has to guess what went wrong, leading to generic or incorrect fixes. If it could see `tar: a.zip: Cannot stat: No such file or directory`, it would immediately know the argument order is wrong.

## Options

### A) zsh preexec/precmd hooks

Use zsh hooks to capture stderr of every command to a temp file. `??` reads the temp file.

```zsh
precmd() { export LAST_STDERR=$(cat /tmp/zsh-last-stderr 2>/dev/null) }
preexec() { exec 2> >(tee /tmp/zsh-last-stderr >&2) }
```

- Pro: Always available, no re-execution
- Con: Slightly invasive, redirects stderr globally, may interfere with other plugins
- Con: fish shell equivalent is different (fish_preexec / fish_postexec)

### B) Re-run with stderr capture

When `??` is invoked, re-run the failed command with `2>&1` to capture output.

- Pro: Simple, no global hooks
- Con: Side effects for destructive commands (rm, mv, etc.)
- Con: Slow for long-running commands

### C) Use `script` command

Wrap shell in `script` to capture all terminal output.

- Pro: Captures everything
- Con: Heavy, changes terminal behavior, compatibility issues

## Recommendation

Option A with a lightweight approach: only capture last N lines of stderr, clean up on each command. Needs separate implementation for zsh and fish.

## Status

Deferred - implement after prompt restructuring is validated.
