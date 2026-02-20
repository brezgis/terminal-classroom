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

TMUX="tmux -L $SESSION"
$TMUX kill-server 2>/dev/null
$TMUX new-session -d -s "$SESSION" -c "$PROJECT_DIR"
$TMUX send-keys -t "$SESSION" "echo '📚 Study session ready. Use rr to capture terminal output.'" Enter
$TMUX split-window -h -l 45% -t "$SESSION" -c "$PROJECT_DIR"
# Find python3 with textual installed — prefer conda
if [ -x /opt/anaconda3/bin/python3 ]; then
  PYTHON3="/opt/anaconda3/bin/python3"
else
  PYTHON3="$(which python3 2>/dev/null || echo python3)"
fi

# Prefer Textual TUI (rich interface), fall back to prompt_toolkit, then bash
if "$PYTHON3" -c "import textual" 2>/dev/null; then
  $TMUX send-keys -t "$SESSION" "'$PYTHON3' '$SCRIPT_DIR/chat_tui.py' '$AGENT' '$SERVER'" Enter
elif "$PYTHON3" -c "from prompt_toolkit import prompt" 2>/dev/null; then
  $TMUX send-keys -t "$SESSION" "COLUMNS=\$(tput cols) '$PYTHON3' '$SCRIPT_DIR/tutor-chat.py' '$AGENT' '$SERVER'" Enter
else
  $TMUX send-keys -t "$SESSION" "bash '$SCRIPT_DIR/tutor-chat.sh' '$AGENT' '$SERVER'" Enter
fi
$TMUX select-pane -t "$SESSION:.0"
$TMUX attach-session -t "$SESSION"
