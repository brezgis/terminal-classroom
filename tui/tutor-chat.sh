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
DISPLAY_NAME="${AGENT^}"
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

echo -e "${CYAN}${BOLD}${DISPLAY_NAME}${RESET} ${DIM}— CS Tutor${RESET}"
echo -e "${DIM}Type your message and press Enter. Ctrl+C to exit.${RESET}"
echo ""

while true; do
  read -e -r -p $'\033[32myou → \033[0m' msg
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
    response=$(openclaw agent --agent "$AGENT" --message "[terminal] $(echo "$msg" | sed "s/'/'\\\\''/g")" 2>/dev/null)
  else
    response=$(ssh "$SERVER" "$REMOTE_PATH $OPENCLAW agent --agent $AGENT --message '[terminal] $(echo "$msg" | sed "s/'/'\\\\''/g")'" 2>&1)
  fi
  if [ -n "$response" ]; then
    # Word-wrap responses to terminal width (with 4-char indent for continuation)
    WRAP_WIDTH="${COLUMNS:-80}"
    FIRST_PREFIX="${CYAN}${DISPLAY_NAME} →${RESET} "
    CONT_PREFIX="    "
    echo "$response" | fold -s -w "$WRAP_WIDTH" | while IFS= read -r line; do
      if [ -z "$_first_done" ]; then
        echo -e "${CYAN}${DISPLAY_NAME} →${RESET} ${line}"
        _first_done=1
      else
        echo -e "${CONT_PREFIX}${line}"
      fi
    done
  else
    echo -e "${DIM}(no response — check connection)${RESET}"
  fi
  echo ""
done
