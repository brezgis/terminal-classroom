#!/bin/bash
# tutor-chat.sh — Interactive REPL for chatting with your tutor agent
# Sends messages via OpenClaw's agent CLI over SSH (or locally)
#
# Usage: ./tutor-chat.sh [agent-name] [server-host]

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

send_message() {
  local msg="$1"
  if [[ "$SERVER" == "localhost" || "$SERVER" == "local" ]]; then
    openclaw agent --agent "$AGENT" --message "$msg" 2>/dev/null
  else
    ssh "$SERVER" "openclaw agent --agent '$AGENT' --message '$msg'" 2>/dev/null
  fi
}

while true; do
  echo -ne "${GREEN}you → ${RESET}"
  read -r msg

  if [ -z "$msg" ]; then continue; fi

  if [[ "$msg" == "quit" || "$msg" == "exit" || "$msg" == "bye" ]]; then
    echo -e "\n${DIM}Ending session...${RESET}"
    send_message "/end-session"
    echo -e "${DIM}Session ended. Your tutor wrote a summary.${RESET}"
    break
  fi

  echo ""
  response=$(send_message "$msg")
  echo -e "${CYAN}${BOLD}${AGENT}${RESET}: $response"
  echo ""
done
