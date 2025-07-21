#!/usr/bin/env fish

# zsh-ai-assist fish plugin configuration
# Create convenient aliases for the Claude AI functions

# Create ? alias (fish doesn't allow ? as function name, so we use an abbreviation)
abbr -a '?' ask_claude

# Create ?? alias for fixing last command
abbr -a '??' fix_last_command