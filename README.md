# zsh-ai-assist

A shell plugin that leverages Claude AI to generate contextually accurate terminal commands for macOS, Linux, and Windows systems. Simply describe what you want to do, and get the correct command for your specific OS and version. Features intelligent error fixing with the innovative `??` command.

**Supports both zsh and fish shells!**

## Features

- **Smart command generation**: Get OS-specific commands for your exact system
- **Error fixing**: Use `??` to automatically fix failed commands with AI assistance
- **Multi-platform support**: Works on macOS, Linux, and Windows (PowerShell)
- **System detection**: Automatically detects OS version and distribution
- **Safe execution**: Commands are placed on prompt for review, never auto-executed
- **Natural language**: Ask questions in plain English
- **Context-aware**: The `??` function analyzes your last failed command

## Prerequisites

- **zsh** or **fish** shell installed and configured
- An Anthropic API key (Get one from [Anthropic Console](https://console.anthropic.com/settings/keys))
- `curl` and `jq` installed on your system

### Installing Dependencies

**macOS:**

```bash
brew install curl jq
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt install curl jq
```

**Linux (Fedora):**

```bash
sudo dnf install curl jq
```

## Installation

### Environment Setup (Required for both shells)

First, set up your API key:

**For zsh**, add to your `~/.zshrc`:
```bash
export CLAUDE_API_KEY="YOUR-API-KEY" # Replace with your actual API key. It should start with "sk-ant-"
export CLAUDE_MODEL="claude-sonnet-4-20250514"  # Optional, this is the default
```

**For fish**, add to your fish config:
```fish
set -gx CLAUDE_API_KEY "YOUR-API-KEY" # Replace with your actual API key. It should start with "sk-ant-"
set -gx CLAUDE_MODEL "claude-sonnet-4-20250514"  # Optional, this is the default
```

### Zsh Package Managers

**Oh My Zsh:**
```bash
git clone https://github.com/MKSG-MugunthKumar/zsh-ai-assist ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-assist
```
Then add `zsh-ai-assist` to your plugins list in `~/.zshrc`:
```bash
plugins=(... zsh-ai-assist)
```

**Antigen:**
```bash
antigen bundle MKSG-MugunthKumar/zsh-ai-assist
```

**Zinit:**
```bash
zinit load MKSG-MugunthKumar/zsh-ai-assist
```

**Antibody:**
```bash
antibody bundle MKSG-MugunthKumar/zsh-ai-assist
```

**Prezto:**
Add to your `.zpreztorc`:
```bash
zstyle ':prezto:load' pmodule \
  ... \
  'zsh-ai-assist'
```
Then clone to the contrib directory:
```bash
git clone https://github.com/MKSG-MugunthKumar/zsh-ai-assist ~/.zprezto/contrib/zsh-ai-assist
```

### Manual zsh Installation

```bash
# Create a directory for the plugin
mkdir -p ~/.config/zsh/plugins/zsh-ai-assist

# Download the plugin file
curl -o ~/.config/zsh/plugins/zsh-ai-assist/zsh-ai-assist.plugin.zsh https://raw.githubusercontent.com/MKSG-MugunthKumar/zsh-ai-assist/main/zsh-ai-assist.plugin.zsh

# Add to your ~/.zshrc
echo 'source ~/.config/zsh/plugins/zsh-ai-assist/zsh-ai-assist.plugin.zsh' >> ~/.zshrc

# Reload your shell
source ~/.zshrc
```

### Fish Shell Installation

For fish users, you can install this plugin using Fisher, or manually:

**Using Fisher (Recommended):**
```fish
fisher install MKSG-MugunthKumar/zsh-ai-assist
```

**Manual Installation:**
```fish
# Clone the repository
git clone https://github.com/MKSG-MugunthKumar/zsh-ai-assist ~/.config/fish/plugins/zsh-ai-assist

# Create symlinks for fish functions
ln -sf ~/.config/fish/plugins/zsh-ai-assist/functions/ask_claude.fish ~/.config/fish/functions/
ln -sf ~/.config/fish/plugins/zsh-ai-assist/conf.d/zsh_ai_assist.fish ~/.config/fish/conf.d/

# Reload fish
source ~/.config/fish/config.fish
```

### Package Distribution Platforms

**Homebrew:**
For Homebrew distribution, you have two options:

1. **Create a Homebrew Tap** (your own repository):
   ```bash
   # Create a tap repository: homebrew-YOUR-TAP-NAME
   # Users install with: brew install MKSG-MugunthKumar/YOUR-TAP-NAME/zsh-ai-assist
   ```

2. **Submit to Homebrew Core** (requires meeting Homebrew's criteria):
   - Must have 75+ GitHub stars, 30+ forks, or be a notable project
   - Submit a PR to homebrew-core repository

**Arch User Repository (AUR):**
Create a PKGBUILD file for Arch Linux users to install via `yay` or `pacman`.

**Package Managers Support Status:**
- ✅ **Automatic Support**: Antigen, Zinit, Antibody, Oh-my-zsh (any that source `.plugin.zsh`)
- 📝 **Requires Submission**: Homebrew, AUR, apt repositories
- 🐟 **Fish-specific**: Fisher (already supported)

## Usage

### Basic Command Generation

**For zsh users**, use the `?` function to ask for commands:
```bash
? flush DNS cache
? install docker on ubuntu
? find all files larger than 100MB
? create a systemd service
? compress a directory with tar
```

**For fish users**, use the `ask_claude` function:
```fish
ask_claude flush DNS cache
ask_claude install docker on ubuntu
ask_claude find all files larger than 100MB
ask_claude create a systemd service
ask_claude compress a directory with tar
```

You can also use the `?` abbreviation in fish (note: no space after `?`):
```fish
? flush DNS cache
```

### Error Fixing (The Magic `??` Command)

**For zsh users**, when a command fails, simply type `??`:
```bash
# Command fails
$ docker container ls
permission denied while trying to connect to the Docker daemon socket...

# Get AI assistance
$ ??
🔍 Analyzing failed command: docker container ls
# Suggests: sudo usermod -aG docker $USER && newgrp docker
```

**For fish users**, use `fix_last_command` or the `??` abbreviation:
```fish
# Command fails
$ docker container ls
permission denied while trying to connect to the Docker daemon socket...

# Get AI assistance
$ fix_last_command
# OR
$ ??
🔍 Analyzing failed command: docker container ls
# Suggests: sudo usermod -aG docker $USER && newgrp docker
```

### Examples by Platform

**macOS:**

```bash
$ ? restart the DNS resolver
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

$ ? install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Linux (Ubuntu/Debian):**

```bash
$ ? install nginx
sudo apt update && sudo apt install nginx

$ ? check systemd service status
sudo systemctl status nginx
```

**Windows (PowerShell):**

```bash
$ ? install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

## How It Works

The plugin:

1. **System Detection**: Automatically identifies your OS, version, and distribution
   - macOS: Version names (Sequoia, Sonoma, Ventura, etc.)
   - Linux: Distribution and version (Ubuntu 22.04, Fedora 39, etc.)
   - Windows: PowerShell-optimized commands

2. **AI Integration**: Uses Claude AI with structured prompts to ensure OS-appropriate commands

3. **Error Analysis**: The `??` function captures your last command and asks Claude to fix it

4. **Safe Execution**: All commands are placed on your prompt for review before execution

## Shell Compatibility

### zsh Support
- **oh-my-zsh**: Full plugin support with `zsh-ai-assist.plugin.zsh`
- **Manual zsh**: Source the plugin file directly
- **Aliases**: `?` and `??` work as expected

### fish Support
- **Fisher**: Install via `fisher install MKSG-MugunthKumar/zsh-ai-assist`
- **Manual**: Copy functions and config files to appropriate fish directories
- **Functions**: `ask_claude` and `fix_last_command`
- **Abbreviations**: `?` and `??` available as shortcuts

### Function Name Reference

| Action | zsh | fish |
|--------|-----|------|
| Ask for command | `?` | `ask_claude` or `?` |
| Fix last command | `??` | `fix_last_command` or `??` |

## System Support
