#!/usr/bin/env zsh

# zsh-ai-assist plugin
# AI-powered command generation and fixing using Claude AI or OpenAI

# Set default provider
ZSH_AI_ASSIST_PROVIDER="${ZSH_AI_ASSIST_PROVIDER:-anthropic}"

# Provider-specific defaults
if [[ "$ZSH_AI_ASSIST_PROVIDER" == "openai" ]]; then
    : "${ZSH_AI_ASSIST_BASE_URL:=https://api.openai.com}"
    : "${ZSH_AI_ASSIST_MODEL:=gpt-4o}"
else
    : "${ZSH_AI_ASSIST_BASE_URL:=https://api.anthropic.com}"
    : "${ZSH_AI_ASSIST_MODEL:=claude-sonnet-4-20250514}"
fi

function ask-claude() {
    # Get detailed system information
    local os_type shell_type target_os system_detail

    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macOS"
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

        system_detail="$os_type $macos_version ($macos_name)"
        shell_type="zsh"
        target_os="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            local os_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
            local os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
            system_detail="$os_id $os_version"
        else
            system_detail="Linux"
        fi
        shell_type="zsh"
        target_os="linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        local windows_version=""
        if command -v systeminfo &> /dev/null; then
            windows_version=$(systeminfo | grep "OS Name" | cut -d: -f2 | sed 's/^ *//')
        else
            windows_version="Windows"
        fi
        system_detail="$windows_version"
        shell_type="PowerShell"
        target_os="windows"
    else
        system_detail=$(uname)
        shell_type="zsh"
        target_os="linux"
    fi

    # Check if arguments were provided
    if [[ -z "$*" ]]; then
        echo "Error: No command specified"
        echo "Usage: ? your question here (no quotes needed)"
        echo "       ?? - to debug the last failed command"
        echo ""
        echo "Environment variables:"
        echo "  ZSH_AI_ASSIST_PROVIDER  - anthropic (default) or openai"
        echo "  ZSH_AI_ASSIST_API_KEY   - your API key"
        echo "  ZSH_AI_ASSIST_BASE_URL  - API base URL (default: provider-specific)"
        echo "  ZSH_AI_ASSIST_MODEL     - model name (default: provider-specific)"
        return 1
    fi

    # Check API key
    if [[ -z "$ZSH_AI_ASSIST_API_KEY" ]]; then
        echo -e "\033[31mError: ZSH_AI_ASSIST_API_KEY is not set.\033[0m"
        echo "Add this to your ~/.zshrc file:"
        echo -e "\033[32mexport ZSH_AI_ASSIST_API_KEY=\"your-api-key\"\033[0m"
        return 1
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

    local system_instruction="Generate shell commands for $system_detail for $shell_type only. $os_examples. Use the shell_command tool to provide your response."

    # Build JSON payload and make request based on provider
    local response
    local provider="$ZSH_AI_ASSIST_PROVIDER"

    if [[ "$provider" == "openai" ]]; then
        local json_payload=$(jq -n \
            --arg model "$ZSH_AI_ASSIST_MODEL" \
            --arg system "$system_instruction" \
            --arg prompt "$user_prompt" \
            '{
                model: $model,
                max_tokens: 1024,
                temperature: 0.2,
                messages: [
                    {role: "system", content: $system},
                    {role: "user", content: $prompt}
                ],
                tools: [{
                    type: "function",
                    function: {
                        name: "shell_command",
                        description: "Generate OS-specific shell command",
                        parameters: {
                            type: "object",
                            properties: {
                                command: {type: "string"},
                                os: {type: "string", enum: ["macOS", "linux", "windows"]}
                            },
                            required: ["command", "os"]
                        }
                    }
                }],
                tool_choice: {type: "function", function: {name: "shell_command"}}
            }')

        response=$(curl -s \
            "$ZSH_AI_ASSIST_BASE_URL/v1/chat/completions" \
            -H "Authorization: Bearer $ZSH_AI_ASSIST_API_KEY" \
            -H "content-type: application/json" \
            -d "$json_payload")
    else
        local json_payload=$(jq -n \
            --arg model "$ZSH_AI_ASSIST_MODEL" \
            --arg system "$system_instruction" \
            --arg prompt "$user_prompt" \
            '{
                model: $model,
                max_tokens: 1024,
                temperature: 0.2,
                system: $system,
                messages: [{role: "user", content: $prompt}],
                tools: [{
                    name: "shell_command",
                    description: "Generate OS-specific shell command",
                    input_schema: {
                        type: "object",
                        properties: {
                            command: {type: "string"},
                            os: {type: "string", enum: ["macOS", "linux", "windows"]}
                        },
                        required: ["command", "os"]
                    }
                }],
                tool_choice: {type: "tool", name: "shell_command"}
            }')

        response=$(curl -s \
            "$ZSH_AI_ASSIST_BASE_URL/v1/messages" \
            -H "x-api-key: $ZSH_AI_ASSIST_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -H "content-type: application/json" \
            -d "$json_payload")
    fi

    # Check for API errors
    if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
        local error_message=$(echo "$response" | jq -r '.error.message')
        echo -e "\033[31mAPI Error:\033[0m $error_message"

        if [[ "$error_message" == *"overloaded"* || "$error_message" == *"rate"* ]]; then
            echo -e "\033[33mTip: Try again in a few seconds\033[0m"
        fi
        return 1
    fi

    # Extract command from response
    local cmd=""
    if [[ "$provider" == "openai" ]]; then
        cmd=$(echo "$response" | jq -r '.choices[0].message.tool_calls[0].function.arguments // empty' 2>/dev/null)
        if [[ -n "$cmd" && "$cmd" != "empty" ]]; then
            cmd=$(echo "$cmd" | jq -r '.command // empty' 2>/dev/null)
        fi
        if [[ -z "$cmd" || "$cmd" == "null" || "$cmd" == "empty" ]]; then
            cmd=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
        fi
    else
        cmd=$(echo "$response" | jq -r '.content[0].input.command // empty' 2>/dev/null)
        if [[ -z "$cmd" || "$cmd" == "null" || "$cmd" == "empty" ]]; then
            cmd=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)
        fi
    fi

    if [[ -z "$cmd" || "$cmd" == "null" || "$cmd" == "empty" ]]; then
        echo -e "\033[31mError: Failed to parse API response\033[0m"
        echo "$response"
        return 1
    fi

    # Put the command on the command line but don't execute
    print -z "$cmd"
}

# Fix the last failed command
function fix-last-command() {
    # Get the last command from history
    local last_cmd=$(fc -ln -1)
    last_cmd=$(echo "$last_cmd" | sed 's/^[[:space:]]*//')

    # Skip if the last command was ? or ?? function itself
    if [[ "$last_cmd" == "??"* || "$last_cmd" == "?"* ]]; then
        echo -e "\033[33mNo previous command to fix (last command was ? or ??)\033[0m"
        return 1
    fi

    if [[ -z "$last_cmd" ]]; then
        echo -e "\033[33mNo previous command found in history\033[0m"
        return 1
    fi

    echo -e "\033[33m🔍 Analyzing failed command:\033[0m $last_cmd"

    local fix_prompt="The command '$last_cmd' failed. Please provide a corrected version or alternative approach."
    ask-claude "$fix_prompt"
}

# Create aliases
alias "?"="ask-claude"
alias "??"="fix-last-command"
