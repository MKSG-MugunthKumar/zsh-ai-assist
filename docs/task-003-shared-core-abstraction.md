---
status: planned
created: 2026-07-19
updated: 2026-07-19
author: Claude (Opus 4.8)
co-author: Mugunth Kumar
tags: [refactor, deduplication, architecture, zsh, fish]
target: next release (post-1.1.0)
---

# Task 003: Collapse duplicated logic into a shared core

## Problem

The plugin logic exists as **three full copies**, not a shared abstraction:

- `zsh-ai-assist.plugin.zsh` — the canonical zsh plugin; what Homebrew, the AUR
  PKGBUILD, and zsh plugin managers actually install and source.
- `functions/ask_claude.fish` (+ `conf.d/zsh_ai_assist.fish`) — the fish port.
- `main.zsh` — a standalone copy of the zsh logic that **nothing sources**.

Every behavior change must be made in all three, by hand, kept in sync. This is
already a live hazard: in the 1.1.0 work (API-key-file support + `sonnet-5`
default), the feature initially landed **only** in `main.zsh` — the one file
that isn't installed — because `CLAUDE.md` claimed the codebase was "a single
main file." It was caught before release, but a copy was missed once and will be
missed again. The two zsh files in particular must currently be kept
byte-for-byte identical for no reason.

## Goal

One source of truth for the command-generation logic. Per-shell code reduced to
a thin shim that does only what *must* live in the shell.

The one thing that genuinely cannot leave the shell: **placing the generated
command on the prompt line** — `print -z` in zsh, `commandline -r` in fish. A
subprocess cannot write to the parent shell's line editor. Everything else
(system detection, prompt assembly, `curl`/`jq`, response parsing, error/key
handling) is shell-agnostic and can be shared.

## Options

### A) Shell-agnostic core script, thin per-shell shims (recommended target)

Extract the logic into a single POSIX/bash core (e.g. `lib/core.sh` or an
executable `bin/zsh-ai-assist-core`). It reads the query + env, does detection,
calls the API, and prints the resulting command to stdout (diagnostics/errors to
stderr). Each shell shim becomes:

```zsh
# zsh shim
ask-claude() { local cmd; cmd=$(zsh-ai-assist-core "$@") || return; print -z "$cmd" }
```
```fish
# fish shim
function ask_claude; set -l cmd (zsh-ai-assist-core $argv); or return; commandline -r -- $cmd; end
```

- Pro: true single source; fish and zsh finally share behavior.
- Pro: same core boundary a future Rust binary would use (see task-002) — this
  refactor is a stepping stone, not throwaway.
- Con: core must resolve the `prompts/` dir itself (already done relative to
  install path — see `docs/2026-03-11-prompt-restructuring-design.md`); the shim
  must pass or let the core discover its own location.
- Con: one extra process per invocation (negligible next to the network call).

### B) Minimal step: make the two zsh files one (cheap, low-risk, do first)

Pick one canonical zsh source and have the other `source` it. Since packagers
install `zsh-ai-assist.plugin.zsh`, that stays the entry point; move the bodies
into a sourced file (or just delete `main.zsh` and update `CLAUDE.md`). Removes
the most dangerous duplication (2 identical zsh files) without touching fish.

### C) Fold into the Rust rewrite (task-002)

A compiled core binary collapses all three by construction — shells only invoke
it and insert the result. If task-002 is happening soon, Option A may be wasted
effort; if not, Option A is the pragmatic interim.

## Recommendation

Two phases:

1. **Phase 1 (this refactor):** Option B — decide the canonical zsh file and
   eliminate the zsh/zsh duplication. Fast, removes the sharpest edge, and
   corrects the "single file" story in `CLAUDE.md`. Likely candidate: keep
   `zsh-ai-assist.plugin.zsh` as the installed entry point; retire or source
   `main.zsh`.
2. **Phase 2:** Option A — extract the shell-agnostic core so fish and zsh share
   one implementation, leaving only prompt-line insertion per shell. Design the
   core boundary to match task-002 so a later Rust core is a drop-in.

## Testing / prerequisites

- Need a **fish environment to validate the fish path** — the 1.1.0 fish changes
  shipped reviewed-but-unrun. Set up a distrobox image with fish + curl + jq.
- Add at least a smoke test per shell (key-file resolution, error paths,
  command-on-prompt behavior) so future single-core changes are verifiable.

## Status

Planned — targeted for the release after 1.1.0.
