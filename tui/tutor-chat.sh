#!/bin/bash
# tutor-chat.sh — Interactive chat REPL for your tutor agent
# Usage: ./tutor-chat.sh [agent-name] [server-host]
# Example: ./tutor-chat.sh tutor myserver

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: tutor-chat.sh [agent-name] [server-host]"
  echo ""
  echo "Interactive chat REPL for your AI tutor agent."
  echo ""
  echo "Arguments:"
  echo "  agent-name    Name of the OpenClaw agent (default: tutor)"
  echo "  server-host   SSH host where OpenClaw runs, or 'localhost' (default: localhost)"
  echo ""
  echo "Examples:"
  echo "  ./tutor-chat.sh                  # local agent named 'tutor'"
  echo "  ./tutor-chat.sh rook myserver    # remote agent named 'rook'"
  echo ""
  echo "Commands inside the chat:"
  echo "  quit, exit, bye    End the session (tutor writes a summary)"
  echo "  Ctrl+C             Exit immediately"
  exit 0
fi

AGENT="${1:-tutor}"
SERVER="${2:-localhost}"
# Full path to openclaw binary — needed for non-interactive SSH (nvm isn't in PATH)
OPENCLAW="${OPENCLAW:-openclaw}"
# Ensure the right node is in PATH for the openclaw shebang (#!/usr/bin/env node)
REMOTE_PATH="PATH=$(dirname "$OPENCLAW"):\$PATH"

BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
DIM="\033[2m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}${AGENT}${RESET} ${DIM}— CS Tutor${RESET}"
echo -e "${DIM}Type your message and press Enter. Ctrl+C to exit.${RESET}"
echo ""

while true; do
  echo -ne "${GREEN}you → ${RESET}"
  read -r msg
  if [ -z "$msg" ]; then continue; fi
  if [[ "$msg" == "quit" || "$msg" == "exit" || "$msg" == "bye" ]]; then
    echo -e "${DIM}Session ended. Your tutor will write the summary.${RESET}"
    if [[ "$SERVER" == "localhost" ]]; then
      openclaw agent --agent "$AGENT" --message 'Session over, thanks!' > /dev/null 2>&1
    else
      ssh "$SERVER" "$REMOTE_PATH $OPENCLAW agent --agent $AGENT --message 'Session over, thanks!'" > /dev/null 2>&1
    fi
    break
  fi

  echo ""
  if [[ "$SERVER" == "localhost" ]]; then
    openclaw agent --agent "$AGENT" --message "$(echo "$msg" | sed "s/'/'\\\\''/g")" 2>/dev/null | sed "s/^/ /"
  else
    ssh "$SERVER" "$REMOTE_PATH $OPENCLAW agent --agent $AGENT --message '$(echo "$msg" | sed "s/'/'\\\\''/g")'" 2>/dev/null | sed "s/^/ /"
  fi
  echo ""
done
