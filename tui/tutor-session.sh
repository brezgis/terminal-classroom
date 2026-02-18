#!/bin/bash
# tutor-session.sh — Launch a tmux split-screen tutoring environment
# Left pane: your terminal (for coding, compiling, running)
# Right pane: interactive chat with your tutor agent
#
# Usage: ./tutor-session.sh [agent-name] [server-host]
# Example: ./tutor-session.sh rook north

set -euo pipefail

AGENT="${1:-tutor}"
SERVER="${2:-localhost}"
SESSION="$AGENT"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Kill existing session if any
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Create new tmux session with two panes
tmux new-session -d -s "$SESSION" -x "$(tput cols)" -y "$(tput lines)"

# Split horizontally: left for terminal, right for tutor chat
tmux split-window -h -t "$SESSION"

# Right pane: launch the chat REPL
tmux send-keys -t "$SESSION:.1" "bash '$SCRIPT_DIR/tutor-chat.sh' '$AGENT' '$SERVER'" Enter

# Left pane: show a welcome message
tmux send-keys -t "$SESSION:.0" "echo '📚 Terminal ready. Use rr to run commands (output visible to tutor).'" Enter

# Focus the left pane (where you code)
tmux select-pane -t "$SESSION:.0"

# Attach
tmux attach -t "$SESSION"
