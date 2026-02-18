#!/bin/bash
# agent-chat.sh — Chat with any OpenClaw agent from your terminal
# Usage: ./agent-chat.sh [agent-name] [server-host] [color-hex]
# Example: ./agent-chat.sh main myserver d97757

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: agent-chat.sh [agent-name] [server-host] [color-hex]"
  echo ""
  echo "Chat with any OpenClaw agent from your terminal."
  echo ""
  echo "Arguments:"
  echo "  agent-name    Name of the OpenClaw agent (default: main)"
  echo "  server-host   SSH host where OpenClaw runs, or 'localhost' (default: localhost)"
  echo "  color-hex     Hex color for agent responses, no # (default: d97757)"
  echo ""
  echo "Examples:"
  echo "  ./agent-chat.sh                          # local main agent"
  echo "  ./agent-chat.sh main myserver            # remote main agent"
  echo "  ./agent-chat.sh tutor myserver 36b5a0    # remote tutor, teal"
  echo ""
  echo "Environment:"
  echo "  OPENCLAW    Path to openclaw binary (default: openclaw)"
  exit 0
fi

AGENT="${1:-main}"
SERVER="${2:-localhost}"
COLOR_HEX="${3:-d97757}"

# Parse hex color to RGB for true color escape
R=$((16#${COLOR_HEX:0:2}))
G=$((16#${COLOR_HEX:2:2}))
B=$((16#${COLOR_HEX:4:2}))

OPENCLAW="${OPENCLAW:-openclaw}"
REMOTE_PATH="PATH=$(dirname "$OPENCLAW"):\$PATH"

BOLD="\033[1m"
AGENT_COLOR="\033[38;2;${R};${G};${B}m"
GREEN="\033[32m"
DIM="\033[2m"
RESET="\033[0m"

echo -e "${AGENT_COLOR}${BOLD}${AGENT}${RESET} ${DIM}— terminal${RESET}"
echo -e "${DIM}Type your message and press Enter. Ctrl+C to exit.${RESET}"
echo ""

while true; do
  echo -ne "${GREEN}you → ${RESET}"
  read -r msg
  if [ -z "$msg" ]; then continue; fi
  if [[ "$msg" == "quit" || "$msg" == "exit" || "$msg" == "bye" ]]; then
    echo -e "${DIM}See you later.${RESET}"
    break
  fi

  echo ""
  if [[ "$SERVER" == "localhost" ]]; then
    response=$($OPENCLAW agent --agent "$AGENT" --message "[terminal] $(echo "$msg" | sed "s/'/'\\\\''/g")" 2>&1)
  else
    response=$(ssh "$SERVER" "$REMOTE_PATH $OPENCLAW agent --agent $AGENT --message '[terminal] $(echo "$msg" | sed "s/'/'\\\\''/g")'" 2>&1)
  fi
  if [ -n "$response" ]; then
    echo -e "${AGENT_COLOR}${AGENT} →${RESET} $(echo "$response" | head -1)"
    echo "$response" | tail -n +2 | sed "s/^/    /"
  else
    echo -e "${DIM}(no response — check connection)${RESET}"
  fi
  echo ""
done
