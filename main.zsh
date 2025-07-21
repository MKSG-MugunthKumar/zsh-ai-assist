function ask-claude() {
    # Get detailed system information
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local os_type="macOS"
        local macos_version=$(sw_vers -productVersion)
        local macos_major_version=${macos_version%%.*}

        case $macos_major_version in
            16) local macos_name="Tahoe" ;;
            15) local macos_name="Sequoia" ;;
            14) local macos_name="Sonoma" ;;
            13) local macos_name="Ventura" ;;
            12) local macos_name="Monterey" ;;
            11) local macos_name="Big Sur" ;;
            *) local macos_name="Catalina or earlier" ;;
        esac

        local system_detail="$os_type $macos_version ($macos_name)"
        local shell_type="zsh"
        local target_os="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            local os_type=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
            local os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
            local system_detail="$os_type $os_version"
        else
            local system_detail="Linux"
        fi
        local shell_type="zsh"
        local target_os="linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        local windows_version=""
        if command -v systeminfo &> /dev/null; then
            windows_version=$(systeminfo | grep "OS Name" | cut -d: -f2 | sed 's/^ *//')
        else
            windows_version="Windows"
        fi
        local system_detail="$windows_version"
        local shell_type="PowerShell"
        local target_os="windows"
    else
        local system_detail=$(uname)
        local shell_type="zsh"
        local target_os="linux"
    fi

    # Check if arguments were provided
    if [[ -z "$*" ]]; then
        echo "Error: No command specified"
        echo "Usage: ? your question here (no quotes needed)"
        echo "       ?? - to debug the last failed command"
        return 1
    fi

    # Check API key
    if [[ -z "$CLAUDE_API_KEY" ]]; then
        echo -e "\033[31mError: CLAUDE_API_KEY is not set.\033[0m"
        echo "Add this to your ~/.zshrc file:"
        echo -e "\033[32mexport CLAUDE_API_KEY=\"your-api-key\"\033[0m"
        return 1
    fi

    # Validate API key format - use string comparison instead of regex
    if [[ "${CLAUDE_API_KEY:0:7}" != "sk-ant-" ]]; then
        echo -e "\033[31mError: CLAUDE_API_KEY appears to be invalid.\033[0m"
        echo "API key should start with 'sk-ant-'"
        return 1
    fi

    # Set default model if not set
    if [[ -z "$CLAUDE_MODEL" ]]; then
        export CLAUDE_MODEL="claude-sonnet-4-20250514"
    fi

    # Concatenate all arguments as the user prompt
    local user_prompt="$*"

    # Build OS-specific examples
    local os_examples=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_examples="Examples: brew install, launchctl, defaults write, sw_vers"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        os_examples="Examples: winget install, Get-Service, Set-ExecutionPolicy, Get-Process"
    else
        os_examples="Examples: apt/yum/dnf install, systemctl, /etc/ configs"
    fi

    local system_instruction=$(cat <<EOF
Generate shell commands for $system_detail for $shell_type only. $os_examples. Use the shell_command tool to provide your response.
EOF
)

    # Use tool-based approach for structured response
    local json_payload=$(cat <<EOF
{
    "model": "$CLAUDE_MODEL",
    "max_tokens": 1024,
    "temperature": 0.2,
    "system": "$system_instruction",
    "messages": [{"role": "user", "content": "$user_prompt"}],
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
}
EOF
)

    local response=$(curl -s \
        "https://api.anthropic.com/v1/messages" \
        -H "x-api-key: $CLAUDE_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$json_payload")

    # Check for API errors
    if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
        local error_message=$(echo "$response" | jq -r '.error.message')
        echo -e "\033[31mAPI Error:\033[0m $error_message"

        if [[ "$error_message" == *"overloaded"* || "$error_message" == *"rate"* ]]; then
            echo -e "\033[33mTip: Try again in a few seconds\033[0m"
        fi
        return 1
    fi

    # Extract command from tool use response
    local cmd=$(echo "$response" | jq -r '.content[0].input.command' 2>/dev/null)
    if [[ $? -ne 0 || "$cmd" == "null" ]]; then
        local content=$(echo "$response" | jq -r '.content[0].text' 2>/dev/null)
        if [[ $? -ne 0 || "$content" == "null" ]]; then
            echo -e "\033[31mError: Failed to parse API response\033[0m"
            echo "$response"
            return 1
        fi
        cmd="$content"
    fi

    # Put the command on the command line but don't execute
    print -z "$cmd"
}

# Simple function to fix the last command
function fix-last-command() {
    # Get the last command from history
    local last_cmd=$(fc -ln -1)
    last_cmd=$(echo "$last_cmd" | sed 's/^[[:space:]]*//')  # trim whitespace

    # Skip if the last command was the ? or ?? function itself
    if [[ "$last_cmd" == "??"* || "$last_cmd" == "?"* ]]; then
        echo -e "\033[33mNo previous command to fix (last command was ? or ??)\033[0m"
        return 1
    fi

    if [[ -z "$last_cmd" ]]; then
        echo -e "\033[33mNo previous command found in history\033[0m"
        return 1
    fi

    echo -e "\033[33m🔍 Analyzing failed command:\033[0m $last_cmd"

    # Simple string concatenation instead of jq escaping
    local fix_prompt="The command '$last_cmd' failed. Please provide a corrected version or alternative approach."

    # Call the ? function with the fix prompt
    ask-claude "$fix_prompt"
}

alias "?"="ask-claude"
alias "??"="fix-last-command"
