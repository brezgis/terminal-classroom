#!/bin/bash
# agent-tui.sh — Interactive agent chat with word-wrapped I/O
# Prefers Python version (prompt_toolkit), falls back to bash.
#
# Usage: agent-tui.sh [agent-name] [server-host]
# Environment:
#   OPENCLAW       Path to openclaw binary (default: openclaw)
#   SERVER         SSH host (default: localhost)
#   AGENT_LABEL    Display name (default: agent name)
#   AGENT_COLOR    ANSI color code for agent (default: orange)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Use Python version if prompt_toolkit is available
if python3 -c "from prompt_toolkit import prompt" 2>/dev/null; then
  exec python3 "$SCRIPT_DIR/agent-tui.py" "$@"
fi

# Bash fallback
AGENT="${1:-main}"
SERVER="${2:-${SERVER:-localhost}}"
OPENCLAW="${OPENCLAW:-openclaw}"
REMOTE_PATH="PATH=$(dirname "$OPENCLAW"):\$PATH"
AGENT_LABEL="${AGENT_LABEL:-$AGENT}"
AGENT_COLOR="${AGENT_COLOR:-\033[38;2;217;119;87m}"

BOLD="\033[1m"
GREEN="\033[32m"
DIM="\033[2m"
RESET="\033[0m"

echo -e "${AGENT_COLOR}${BOLD}${AGENT_LABEL}${RESET} ${DIM}— terminal${RESET}"
echo -e "${DIM}Type your message and press Enter. Ctrl+C to exit.${RESET}"
echo ""

while true; do
  read -e -r -p $'\033[32myou → \033[0m' msg
  if [ -z "$msg" ]; then continue; fi
  if [[ "$msg" == "quit" || "$msg" == "exit" || "$msg" == "bye" ]]; then
    echo -e "${DIM}See you later.${RESET}"
    break
  fi

  echo ""
  WRAP_WIDTH="${COLUMNS:-80}"
  if [[ "$SERVER" == "localhost" ]]; then
    response=$($OPENCLAW agent --agent "$AGENT" --message "[terminal] $(echo "$msg" | sed "s/'/'\\\\''/g")" 2>/dev/null)
  else
    response=$(ssh -o LogLevel=ERROR "$SERVER" "$REMOTE_PATH $OPENCLAW agent --agent $AGENT --message '[terminal] $(echo "$msg" | sed "s/'/'\\\\''/g")'" 2>/dev/null)
  fi
  if [ -n "$response" ]; then
    echo "$response" | fold -s -w "$WRAP_WIDTH" | {
      read -r first_line
      echo -e "${AGENT_COLOR}${AGENT_LABEL} →${RESET} $first_line"
      while IFS= read -r line; do
        echo "    $line"
      done
    }
  else
    echo -e "${DIM}(no response — check connection)${RESET}"
  fi
  echo ""
done
