#!/bin/bash
# chat-tui.sh — Launch the Textual chat TUI
# Usage: ./chat-tui.sh [agent-name] [server-host]
# Example: ./chat-tui.sh tutor myserver

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT="${1:-${AGENT:-tutor}}" SERVER="${2:-${SERVER:-localhost}}" \
    python3 "$SCRIPT_DIR/chat_tui.py" "$@"
