#!/bin/bash
# tutor-session.sh — Launch a tmux split-screen tutoring environment
# Left pane: your terminal (coding, compiling, running)
# Right pane: interactive chat with your tutor agent
#
# Usage: ./tutor-session.sh [agent-name] [server-host] [project-dir]
# Example: ./tutor-session.sh tutor myserver ~/projects/data-structures

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: tutor-session.sh [agent-name] [server-host] [project-dir]"
  echo ""
  echo "Launch a tmux split-screen tutoring environment."
  echo "  Left pane:  your terminal (coding, compiling, running)"
  echo "  Right pane: interactive chat with your tutor agent"
  echo ""
  echo "Arguments:"
  echo "  agent-name    Name of the OpenClaw agent (default: tutor)"
  echo "  server-host   SSH host where OpenClaw runs, or 'localhost' (default: localhost)"
  echo "  project-dir   Working directory for the session (default: \$HOME)"
  echo ""
  echo "Examples:"
  echo "  ./tutor-session.sh                              # defaults"
  echo "  ./tutor-session.sh rook myserver ~/projects/ds  # remote, specific project"
  echo ""
  echo "Tips:"
  echo "  Use 'rr' to run commands so the tutor can see your output:"
  echo "    rr javac MyCode.java    # compile"
  echo "    rr java MyCode          # run"
  echo ""
  echo "  Add this to ~/.bashrc:  rr() { \"\$@\" 2>&1 | tee .terminal.log; }"
  exit 0
fi

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
