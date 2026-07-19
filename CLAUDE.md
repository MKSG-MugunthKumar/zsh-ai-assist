# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a zsh plugin that provides AI-powered command generation and error fixing using Claude AI. The plugin adds two primary functions to the shell:

- `?` (ask-claude): Generates OS-specific commands based on natural language queries
- `??` (fix-last-command): Analyzes and fixes the last failed command from history

## Architecture

The plugin logic is duplicated across three parallel implementations. **When changing behavior, update all three** (they do not share code):

- `zsh-ai-assist.plugin.zsh`: The canonical zsh plugin — this is what Homebrew, the AUR PKGBUILD, and zsh plugin managers actually install and source.
- `functions/ask_claude.fish` (with `conf.d/zsh_ai_assist.fish`): The fish shell port.
- `main.zsh`: A standalone/reference copy of the zsh logic; not sourced by the installed plugin.

Each contains the full plugin functionality including system detection, API communication, and command generation.

Key architectural components:

- **System Detection**: Automatically identifies OS type (macOS/Linux/Windows), version, and distribution
- **API Integration**: Uses Anthropic Claude API with structured tool-based responses
- **Safe Command Placement**: Commands are placed on the prompt line (using `print -z`) rather than auto-executed
- **Error Handling**: Comprehensive API error detection and user-friendly error messages

## Development Commands

Since this is a zsh plugin with no build process, testing is done by:

1. **Manual Testing**: Source the plugin and test the functions:

   ```bash
   source main.zsh
   ? your test query
   ??
   ```

2. **Installation Testing**: Test various installation methods described in README.md

## Environment Requirements

The plugin requires:

- `CLAUDE_API_KEY`: Anthropic API key (must start with "sk-ant-")
- `CLAUDE_API_KEY_FILE`: Optional, path to a file containing the API key; used only when `CLAUDE_API_KEY` is unset. If it too is unset, the key is read from the default `${XDG_CONFIG_HOME:-$HOME/.config}/zsh-ai-assist/api-key`
- `CLAUDE_MODEL`: Optional, defaults to "claude-sonnet-5"
- System dependencies: `curl` and `jq`

## Key Implementation Details

- API requests use structured tool schema to ensure consistent command formatting
- System information is dynamically detected on each invocation
- The `??` function analyzes command history to avoid fixing itself recursively
- All commands are OS-specific with appropriate examples and validation
- Temperature is set to 0.2 for consistent, deterministic command suggestions
- When the API key is loaded from a file, its permissions are checked via zsh's `zstat`; a warning is printed (but not fatal) if it is group/other-accessible. Note octal masks in zsh math must use `8#NN` notation since `OCTAL_ZEROES` is off by default
