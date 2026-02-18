#!/bin/bash
# tutor-chat.sh — Interactive chat REPL for your tutor agent
# Usage: ./tutor-chat.sh [agent-name] [server-host]
# Example: ./tutor-chat.sh tutor myserver

AGENT="${1:-tutor}"
SERVER="${2:-localhost}"

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
      ssh "$SERVER" "openclaw agent --agent $AGENT --message 'Session over, thanks!'" > /dev/null 2>&1
    fi
    break
  fi

  echo ""
  if [[ "$SERVER" == "localhost" ]]; then
    openclaw agent --agent "$AGENT" --message "$(echo "$msg" | sed "s/'/'\\\\''/g")" 2>/dev/null | sed "s/^/ /"
  else
    ssh "$SERVER" "openclaw agent --agent $AGENT --message '$(echo "$msg" | sed "s/'/'\\\\''/g")'" 2>/dev/null | sed "s/^/ /"
  fi
  echo ""
done
