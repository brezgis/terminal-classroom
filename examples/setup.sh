#!/bin/bash
# setup.sh — Launch a tutoring session with tmux split
# Usage: ./setup.sh [project-directory]
#
# Creates a tmux session with:
#   Left pane (65%): Your editor/terminal
#   Right pane (35%): OpenClaw tutor agent

set -e

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
SESSION_NAME="tutor-$(basename "$PROJECT_DIR")"

# Check dependencies
if ! command -v tmux &>/dev/null; then
    echo "Error: tmux is required. Install it with: sudo apt install tmux"
    exit 1
fi

if ! command -v openclaw &>/dev/null; then
    echo "Error: openclaw is required. See https://github.com/nicholasgasior/openclaw"
    exit 1
fi

# Detect language (for context)
detect_language() {
    if ls "$PROJECT_DIR"/*.java &>/dev/null || [ -f "$PROJECT_DIR/pom.xml" ] || [ -f "$PROJECT_DIR/build.gradle" ]; then
        echo "java"
    elif ls "$PROJECT_DIR"/*.py &>/dev/null || [ -f "$PROJECT_DIR/requirements.txt" ] || [ -f "$PROJECT_DIR/setup.py" ]; then
        echo "python"
    elif ls "$PROJECT_DIR"/*.js &>/dev/null || [ -f "$PROJECT_DIR/package.json" ]; then
        echo "javascript"
    elif ls "$PROJECT_DIR"/*.rs &>/dev/null || [ -f "$PROJECT_DIR/Cargo.toml" ]; then
        echo "rust"
    elif ls "$PROJECT_DIR"/*.go &>/dev/null || [ -f "$PROJECT_DIR/go.mod" ]; then
        echo "go"
    elif ls "$PROJECT_DIR"/*.c &>/dev/null || ls "$PROJECT_DIR"/*.cpp &>/dev/null; then
        echo "c/cpp"
    else
        echo "unknown"
    fi
}

LANG=$(detect_language)
echo "📚 Starting tutor session"
echo "   Project: $PROJECT_DIR"
echo "   Language: $LANG"
echo "   Session: $SESSION_NAME"

# Kill existing session if it exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Create new session
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR"

# Split: 65% left (work), 35% right (tutor)
tmux split-window -h -t "$SESSION_NAME" -p 35 -c "$PROJECT_DIR"

# Start the tutor agent in the right pane
# Customize this command for your OpenClaw setup
tmux send-keys -t "$SESSION_NAME:0.1" \
    "echo '🎓 Tutor ready. Working on: $PROJECT_DIR ($LANG)'" Enter

# Optional: start file watcher in the background
# Uncomment if you have inotify-tools installed
# tmux send-keys -t "$SESSION_NAME:0.1" \
#     "inotifywait -m -r -e modify,create --format '%w%f' '$PROJECT_DIR/src/' &" Enter

# Focus the left pane (work area)
tmux select-pane -t "$SESSION_NAME:0.0"

# Attach to the session
echo "   Attaching to tmux session..."
tmux attach -t "$SESSION_NAME"
