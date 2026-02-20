#!/usr/bin/env python3
"""Interactive agent chat TUI with word-wrapped I/O.

Uses prompt_toolkit for word-wrapped input (no mid-word breaks)
and textwrap for word-wrapped output.
"""

import os
import subprocess
import sys
import textwrap
import shutil

AGENT = sys.argv[1] if len(sys.argv) > 1 else "main"
SERVER = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("SERVER", "localhost")
OPENCLAW = os.environ.get("OPENCLAW", "openclaw")
REMOTE_PATH = f"PATH={os.path.dirname(OPENCLAW)}:$PATH"
AGENT_LABEL = os.environ.get("AGENT_LABEL", AGENT)

# Colors
AGENT_COLOR = os.environ.get("AGENT_COLOR", "\033[38;2;217;119;87m")
GREEN = "\033[32m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

def get_width():
    return shutil.get_terminal_size().columns

def wrap_text(text):
    """Word-wrap text to terminal width."""
    width = get_width()
    lines = []
    for paragraph in text.split('\n'):
        if not paragraph.strip():
            lines.append('')
            continue
        wrapped = textwrap.wrap(paragraph, width=width - 4,
                                break_long_words=False,
                                break_on_hyphens=False)
        lines.extend(wrapped if wrapped else [''])
    return lines

def send_message(msg):
    """Send message to agent via OpenClaw gateway."""
    escaped = msg.replace("'", "'\\''")
    if SERVER == "localhost":
        cmd = [OPENCLAW, "agent", "--agent", AGENT, "--message", f"[terminal] {msg}"]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
            return result.stdout.strip()
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            return f"(error: {e})"
    else:
        cmd = f"{REMOTE_PATH} {OPENCLAW} agent --agent {AGENT} --message '[terminal] {escaped}'"
        try:
            result = subprocess.run(
                ["ssh", "-o", "LogLevel=ERROR", SERVER, cmd],
                capture_output=True, text=True, timeout=120
            )
            return result.stdout.strip()
        except subprocess.TimeoutExpired:
            return "(timeout — check connection)"

def main():
    print(f"{AGENT_COLOR}{BOLD}{AGENT_LABEL}{RESET} {DIM}— terminal{RESET}")
    print(f"{DIM}Type your message and press Enter. Ctrl+C or Ctrl+D to exit.{RESET}")
    print()

    # Try prompt_toolkit for word-wrapped input
    pt_session = None
    try:
        from prompt_toolkit import PromptSession
        from prompt_toolkit.styles import Style
        pt_session = PromptSession()
        pt_style = Style.from_dict({'green': '#00aa00'})
    except ImportError:
        pt_session = None

    while True:
        try:
            if pt_session:
                msg = pt_session.prompt(
                    [('class:green', 'you → ')],
                    style=pt_style,
                ).strip()
            else:
                msg = input(f"{GREEN}you → {RESET}").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break

        if not msg:
            continue

        if msg in ("quit", "exit", "bye"):
            print(f"{DIM}See you later.{RESET}")
            break

        print()
        response = send_message(msg)
        if response:
            lines = wrap_text(response)
            for i, line in enumerate(lines):
                if i == 0:
                    print(f"{AGENT_COLOR}{AGENT_LABEL} →{RESET} {line}")
                else:
                    print(f"    {line}")
        else:
            print(f"{DIM}(no response — check connection){RESET}")
        print()

if __name__ == "__main__":
    main()
