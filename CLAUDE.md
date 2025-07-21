# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a zsh plugin that provides AI-powered command generation and error fixing using Claude AI. The plugin adds two primary functions to the shell:
- `?` (ask-claude): Generates OS-specific commands based on natural language queries
- `??` (fix-last-command): Analyzes and fixes the last failed command from history

## Architecture

The codebase consists of a single main file:
- `main.zsh`: Contains all plugin functionality including system detection, API communication, and command generation

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
- `CLAUDE_MODEL`: Optional, defaults to "claude-sonnet-4-20250514"
- System dependencies: `curl` and `jq`

## Key Implementation Details

- API requests use structured tool schema to ensure consistent command formatting
- System information is dynamically detected on each invocation
- The `??` function analyzes command history to avoid fixing itself recursively
- All commands are OS-specific with appropriate examples and validation
- Temperature is set to 0.2 for consistent, deterministic command suggestions