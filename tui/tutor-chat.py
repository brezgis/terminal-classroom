#!/usr/bin/env python3
"""Interactive chat REPL for your tutor agent with word-wrapped I/O."""

import os
import subprocess
import sys
import textwrap
import shutil

AGENT = sys.argv[1] if len(sys.argv) > 1 else "tutor"
SERVER = sys.argv[2] if len(sys.argv) > 2 else "localhost"
OPENCLAW = os.environ.get("OPENCLAW", "openclaw")
REMOTE_PATH = f"PATH={os.path.dirname(OPENCLAW)}:$PATH"

# Colors
CYAN = "\033[36m"
GREEN = "\033[32m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

def get_width():
    return shutil.get_terminal_size().columns

def wrap_text(text, prefix_len=0):
    """Word-wrap text to terminal width, accounting for prefix on first line."""
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
    """Send message to agent, return response."""
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
            result = subprocess.run(["ssh", SERVER, cmd], capture_output=True, text=True, timeout=120)
            return (result.stdout + result.stderr).strip()
        except subprocess.TimeoutExpired:
            return "(timeout — check connection)"

def get_input_prompt_toolkit():
    """Use prompt_toolkit for word-wrapped input."""
    from prompt_toolkit import PromptSession
    from prompt_toolkit.formatted_text import HTML
    session = PromptSession()
    return session

def get_input_fallback():
    """Fallback to basic input()."""
    return None

def main():
    print(f"{CYAN}{BOLD}{AGENT}{RESET} {DIM}— CS Tutor{RESET}")
    print(f"{DIM}Type your message and press Enter. Ctrl+C or Ctrl+D to exit.{RESET}")
    print()

    # Try prompt_toolkit for nice word-wrapped input
    pt_session = None
    try:
        pt_session = get_input_prompt_toolkit()
    except ImportError:
        pass

    while True:
        try:
            if pt_session:
                msg = pt_session.prompt(
                    [('class:green', 'you → ')],
                    style=_pt_style(),
                ).strip()
            else:
                msg = input(f"{GREEN}you → {RESET}").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break

        if not msg:
            continue

        if msg in ("quit", "exit", "bye"):
            print(f"{DIM}Session ended. Your tutor will write the summary.{RESET}")
            send_message("Session over, thanks!")
            break

        print()
        response = send_message(msg)
        if response:
            lines = wrap_text(response)
            for i, line in enumerate(lines):
                if i == 0:
                    print(f"{CYAN}{AGENT} →{RESET} {line}")
                else:
                    print(f"    {line}")
        else:
            print(f"{DIM}(no response — check connection){RESET}")
        print()

def _pt_style():
    from prompt_toolkit.styles import Style
    return Style.from_dict({'green': '#00aa00'})

if __name__ == "__main__":
    main()
