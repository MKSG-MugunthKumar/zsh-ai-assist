#!/usr/bin/env fish

# zsh-ai-assist plugin for fish shell
# AI-powered command generation and error fixing using Claude AI

function ask_claude -d "Generate commands using Claude AI"
    # Get detailed system information
    set -l os_type ""
    set -l system_detail ""
    set -l shell_type "fish"
    set -l target_os ""

    switch (uname)
        case Darwin
            set os_type "macOS"
            set -l macos_version (sw_vers -productVersion)
            set -l macos_major_version (string split '.' $macos_version)[1]

            switch $macos_major_version
                case 16
                    set -l macos_name "Tahoe"
                case 15
                    set -l macos_name "Sequoia"
                case 14
                    set -l macos_name "Sonoma"
                case 13
                    set -l macos_name "Ventura"
                case 12
                    set -l macos_name "Monterey"
                case 11
                    set -l macos_name "Big Sur"
                case '*'
                    set -l macos_name "Catalina or earlier"
            end

            set system_detail "$os_type $macos_version ($macos_name)"
            set target_os "macOS"
        case Linux
            if test -f /etc/os-release
                set -l os_id (grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
                set -l os_version (grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
                set system_detail "$os_id $os_version"
            else
                set system_detail "Linux"
            end
            set target_os "linux"
        case '*'
            set system_detail (uname)
            set target_os "linux"
    end

    # Check if arguments were provided
    if test (count $argv) -eq 0
        echo "Error: No command specified"
        echo "Usage: ask_claude your question here"
        echo "       fix_last_command - to debug the last failed command"
        return 1
    end

    # Check if API key is set
    if test -z "$CLAUDE_API_KEY"
        set_color red
        echo "Error: CLAUDE_API_KEY is not set."
        set_color normal
        echo "Add this to your fish config:"
        set_color green
        echo "set -gx CLAUDE_API_KEY \"your-api-key\""
        set_color normal
        return 1
    end

    # Set default API endpoint if not set
    if test -z "$CLAUDE_API_ENDPOINT"
        set -gx CLAUDE_API_ENDPOINT "https://api.anthropic.com/v1/messages"
    end

    

    # Set default model if not set
    if not set -q CLAUDE_MODEL
        set -gx CLAUDE_MODEL "claude-sonnet-4-20250514"
    end

    # Join all arguments as the user prompt
    set -l user_prompt (string join ' ' $argv)

    # Build OS-specific examples
    set -l os_examples ""
    switch $target_os
        case "macOS"
            set os_examples "Examples: brew install, launchctl, defaults write, sw_vers"
        case "linux"
            set os_examples "Examples: apt/yum/dnf install, systemctl, /etc/ configs"
    end

    set -l system_instruction "Generate shell commands for $system_detail for $shell_type only. $os_examples. Use the shell_command tool to provide your response."

    # Create JSON payload
    set -l json_payload (printf '{
        "model": "%s",
        "max_tokens": 1024,
        "temperature": 0.2,
        "system": "%s",
        "messages": [{"role": "user", "content": "%s"}],
        "tools": [{
            "name": "shell_command",
            "description": "Generate OS-specific shell command",
            "input_schema": {
                "type": "object",
                "properties": {
                    "command": {"type": "string"},
                    "os": {"type": "string", "enum": ["macOS", "linux", "windows"]}
                },
                "required": ["command", "os"]
            }
        }],
        "tool_choice": {"type": "tool", "name": "shell_command"}
    }' $CLAUDE_MODEL $system_instruction $user_prompt)

    set response (curl -s \
        "$CLAUDE_API_ENDPOINT" \
        -H "x-api-key: $CLAUDE_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d $json_payload)

    # Check for API errors
    if echo $response | jq -e '.error' >/dev/null 2>&1
        set -l error_message (echo $response | jq -r '.error.message')
        set_color red
        echo "API Error: $error_message"
        set_color normal

        if string match -q "*overloaded*" $error_message; or string match -q "*rate*" $error_message
            set_color yellow
            echo "Tip: Try again in a few seconds"
            set_color normal
        end
        return 1
    end

    # Extract command from tool use response
    set -l cmd (echo $response | jq -r '.content[0].input.command' 2>/dev/null)
    if test $status -ne 0; or test "$cmd" = "null"
        set -l content (echo $response | jq -r '.content[0].text' 2>/dev/null)
        if test $status -ne 0; or test "$content" = "null"
            set_color red
            echo "Error: Failed to parse API response"
            set_color normal
            echo $response
            return 1
        end
        set cmd $content
    end

    # Put the command on the command line but don't execute
    commandline -r $cmd
end

function fix_last_command -d "Fix the last failed command using Claude AI"
    # Get the last command from history
    set -l last_cmd (history | head -n 1)

    # Remove leading/trailing whitespace
    set last_cmd (string trim $last_cmd)

    # Skip if the last command was ask_claude or fix_last_command
    if string match -q "ask_claude*" $last_cmd; or string match -q "fix_last_command*" $last_cmd
        set_color yellow
        echo "No previous command to fix (last command was ask_claude or fix_last_command)"
        set_color normal
        return 1
    end

    if test -z "$last_cmd"
        set_color yellow
        echo "No previous command found in history"
        set_color normal
        return 1
    end

    set_color yellow
    echo "🔍 Analyzing failed command: $last_cmd"
    set_color normal

    # Create fix prompt
    set -l fix_prompt "The command '$last_cmd' failed. Please provide a corrected version or alternative approach."

    # Call ask_claude with the fix prompt
    ask_claude $fix_prompt
end