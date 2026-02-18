#!/bin/bash
# tutor-session.sh — Launch a tmux split-screen tutoring environment
# Left pane: your terminal (coding, compiling, running)
# Right pane: interactive chat with your tutor agent
#
# Usage: ./tutor-session.sh [agent-name] [server-host] [project-dir]
# Example: ./tutor-session.sh tutor myserver ~/projects/data-structures

AGENT="${1:-tutor}"
SERVER="${2:-localhost}"
PROJECT_DIR="${3:-$HOME}"

SESSION="$AGENT"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

tmux kill-session -t "$SESSION" 2>/dev/null
tmux new-session -d -s "$SESSION" -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION" "echo '📚 Study session ready. Use rr to capture terminal output.'" Enter
tmux split-window -h -t "$SESSION" -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION" "bash '$SCRIPT_DIR/tutor-chat.sh' '$AGENT' '$SERVER'" Enter
tmux select-pane -t "$SESSION:.0"
tmux attach-session -t "$SESSION"
