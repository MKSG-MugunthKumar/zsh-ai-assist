---
status: ready
created: 2026-03-11
updated: 2026-03-11
author: Claude (Opus 4.6)
co-author: Mugunth Kumar
tags: [prompts, quality, extended-thinking]
---

# Prompt Restructuring Design

## Problem

The LLM returns generic/textbook answers instead of OS-tailored commands. The current system prompt is a single flat string that newer Claude models don't attend to as well as Sonnet 3.5 did.

## Changes

### 1. External prompt templates (`prompts/ask.txt`, `prompts/fix.txt`)

- XML-structured content with `{{PLACEHOLDER}}` substitution
- System context in a `<system_context>` block within the **user message** (not system prompt), so the model attends to it more
- Separate prompts for `?` (ask) and `??` (fix) with distinct instructions
- Fix prompt explicitly says "fix the command the user intended, don't suggest a different tool"

### 2. Tool schema: add `note` field

```json
{
  "command": {"type": "string"},
  "os": {"type": "string", "enum": ["macOS", "linux", "windows"]},
  "note": {"type": "string", "description": "Optional brief tip, max 15 words"}
}
```

Display note as dim text above the command:
```
💡 archive name comes before source directory
tar -cvzf a.zip a/
```

### 3. Extended thinking (configurable via `CLAUDE_THINKING_BUDGET`)

`CLAUDE_THINKING_BUDGET` env variable, defaults to 1024. Forces the model to reason about the system context before answering. Small budget keeps latency low (~1-2s extra). Requires `anthropic-version: 2025-04-15` or later and removes `temperature` parameter. Set to 0 to disable.

### 4. Prompt loaded relative to script location

Both zsh and fish versions resolve the `prompts/` directory relative to the plugin's install path. Variable substitution is done with `sed` before passing to `jq`.

## Files to modify

- `main.zsh` — load prompt templates, add note display, enable extended thinking, use jq for JSON
- `zsh-ai-assist.plugin.zsh` — same changes (this is the oh-my-zsh entry point)
- `functions/ask_claude.fish` — same changes for fish shell
- `prompts/ask.txt` — new file (created)
- `prompts/fix.txt` — new file (created)

## What we're NOT doing yet

- stderr capture (see task-001)
- Rust rewrite (see task-002)
- Multi-turn agent loops
