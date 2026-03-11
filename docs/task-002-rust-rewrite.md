---
status: deferred
created: 2026-03-11
updated: 2026-03-11
author: Claude (Opus 4.6)
co-author: Mugunth Kumar
tags: [rust, rewrite, architecture]
---

# Task 002: Rust Rewrite Exploration

## Motivation

- Shell scripts become hard to maintain as complexity grows
- Multi-turn agentic loops (LLM requests system info before answering) need state management
- Proper JSON construction, error handling, and string escaping are awkward in shell
- Single binary distribution is simpler than shell scripts across zsh/fish/bash

## What Rust Would Enable

- **Multi-turn agent loop**: LLM can request tool calls (check `which`, `brew list`, `pip list`) before generating the final command
- **Persistent context**: Cache system info, installed packages, recent commands
- **Proper error handling**: No more silent failures from broken pipes or bad JSON
- **Cross-shell support**: One binary works with zsh, fish, bash via thin shell wrappers
- **Streaming**: Show thinking/progress as the LLM works

## Architecture Sketch

```
zsh/fish wrapper (thin alias)
  → rust binary (CLI)
    → system detection module
    → anthropic API client
    → agent loop (tool calls for system introspection)
    → output formatter (command + optional note)
```

The shell wrappers would be minimal:
```zsh
function ask-claude() { eval "$(zsh-ai-assist ask "$*")" }
function fix-last-command() { eval "$(zsh-ai-assist fix "$(fc -ln -1)")" }
```

The Rust binary outputs shell-specific commands (print -z for zsh, commandline -r for fish).

## Dependencies

- `reqwest` for HTTP
- `serde_json` for JSON
- `clap` for CLI args

## Status

Deferred - evaluate after prompt restructuring proves (or disproves) that single-shot is sufficient.
