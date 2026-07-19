---
status: planned
created: 2026-07-19
updated: 2026-07-19
author: Claude (Opus 4.8)
co-author: Mugunth Kumar
tags: [provider, abstraction, api, models, openai-compatible, architecture]
target: next release cycle
depends-on: [task-002, task-003]
---

# Task 004: Abstract the provider away from Anthropic/Claude

## Motivation

The plugin is hardwired to Anthropic. Non-Anthropic models — especially the
recent Chinese ones (DeepSeek, Qwen, Zhipu GLM, Moonshot Kimi, MiniMax) — are
now good enough for command generation and often far cheaper. Users should be
able to point the plugin at any provider, including OpenAI-compatible hosted
APIs and local runtimes (Ollama, llama.cpp, vLLM), without editing the code.

Goals: no vendor lock-in, cheaper options, offline/local support, and keeping
the plugin's name/UX (`?` / `??`, `zsh-ai-assist`) — which are already
provider-neutral — honest.

## Current coupling to Anthropic

Every one of these lives (triplicated) in `zsh-ai-assist.plugin.zsh`,
`functions/ask_claude.fish`, and `main.zsh`:

- Endpoint: `https://api.anthropic.com/v1/messages`.
- Auth headers: `x-api-key: $CLAUDE_API_KEY` + `anthropic-version: 2023-06-01`.
- Request body: Anthropic Messages shape + Anthropic **tool-use** schema with
  `tool_choice` forcing the `shell_command` tool.
- Response parsing: `.content[0].input.command` (tool result), text fallback
  `.content[0].text`.
- Config/validation: `CLAUDE_API_KEY` (validated against the `sk-ant-` prefix),
  `CLAUDE_MODEL`.

Note: the 1.1.0 key-file default path (`~/.config/zsh-ai-assist/api-key`) is
already provider-neutral — good. The `sk-ant-` prefix check is **not** and must
become provider-aware (or drop to a generic non-empty check).

## The hard part: structured output across providers

Anthropic forces a tool call to guarantee a clean `command` string. Other
providers vary:

- **OpenAI-compatible** (most hosted Chinese APIs + local servers): function
  calling and/or `response_format: json_schema`. Response at
  `.choices[0].message.tool_calls[0].function.arguments` or `.content`.
- **Weaker/local models**: unreliable tool calling — need a plain-text prompt
  ("output only the command, no prose, no backticks") plus defensive parsing
  (strip code fences, take first line) as a fallback.

So an adapter is not just a base URL swap; it owns request shape, auth style,
**and** how the command is extracted.

## Options

### A) Two adapters: "anthropic" + "openai-compatible" (recommended)

Treat OpenAI's Chat Completions shape as the lingua franca — it covers DeepSeek,
Qwen/DashScope, GLM, Kimi, OpenAI itself, OpenRouter, Ollama, vLLM, etc. Keep a
native Anthropic adapter for the default. Two adapters cover ~everything.

Select provider explicitly (`AI_PROVIDER=openai|anthropic`) or infer from a
`AI_BASE_URL`. Config surface (proposed, provider-neutral):

```
AI_PROVIDER   # openai | anthropic (default: anthropic)
AI_BASE_URL   # override endpoint (e.g. https://api.deepseek.com)
AI_API_KEY    # generic key; CLAUDE_API_KEY kept as a back-compat alias
AI_MODEL      # generic model; CLAUDE_MODEL kept as a back-compat alias
```

Back-compat: if `AI_*` unset, fall through to `CLAUDE_*` so existing configs
keep working. Reuse the existing key-file resolution for `AI_API_KEY` too.

- Pro: two code paths cover the whole practical market.
- Con: structured-output handling differs per adapter (unavoidable).

### B) Full pluggable adapter registry

One adapter per provider with per-provider quirks. More flexible, more code and
maintenance. Overkill until Option A proves insufficient.

### C) Assume OpenAI schema everywhere (minimal)

Just parameterize base URL + bearer auth + model, drop Anthropic's native shape.
Simplest, but throws away Anthropic tool-use reliability and breaks the current
default. Not recommended.

## Strong dependency: do this in the shared core, not the shell copies

Building provider abstraction across the three duplicated shell implementations
would triple an already-fiddly change (per-provider JSON assembly + response
parsing). This should land **after / as part of** the core extraction:

- Ride on **task-003** (shared shell core) at minimum, or
- Better, build it natively in **task-002** (Rust), where adapters are a clean
  trait and JSON/typing are pleasant.

Sequencing: `task-003` (de-dup) → `task-002` (Rust core) → provider adapters
inside that core. Attempting task-004 first, in shell, is the wrong order.

## Recommendation

Option A (anthropic + openai-compatible), implemented inside the shared/Rust
core, with `AI_*` env vars that fall back to the existing `CLAUDE_*` names for
backward compatibility. Ship with a couple of documented example configs
(DeepSeek, Qwen, a local Ollama) in the README.

## Status

Planned — gated on task-002/003; do not implement against the current
triplicated shell code.
