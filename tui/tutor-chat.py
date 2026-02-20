#!/usr/bin/env python3
"""Interactive chat REPL for your tutor agent with word-wrapped I/O."""

import os
import subprocess
import sys
import textwrap
import shutil

AGENT = sys.argv[1] if len(sys.argv) > 1 else "tutor"
DISPLAY_NAME = AGENT.capitalize()
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
    """Get terminal width — try tput (works in tmux panes), then COLUMNS, then shutil."""
    import subprocess as _sp
    try:
        result = _sp.run(['tput', 'cols'], capture_output=True, text=True, timeout=2)
        if result.returncode == 0:
            return int(result.stdout.strip())
    except Exception:
        pass
    try:
        cols = int(os.environ.get('COLUMNS', 0))
        if cols > 0:
            return cols
    except (ValueError, TypeError):
        pass
    return shutil.get_terminal_size().columns

def wrap_text(text, first_prefix_len=0, cont_prefix_len=4):
    """Word-wrap text to terminal width, accounting for prefixes.
    
    The response from openclaw agent often comes pre-wrapped with \n.
    We rejoin soft-wrapped lines into paragraphs (split on \n\n),
    then re-wrap to the actual terminal width.
    """
    width = get_width()
    lines = []
    is_first = True
    
    # Rejoin soft wraps: split on double newlines (real paragraph breaks),
    # then collapse single newlines within each paragraph into spaces
    paragraphs = text.split('\n\n')
    
    for paragraph in paragraphs:
        # Collapse single newlines into spaces (undo pre-wrapping)
        reflowed = ' '.join(paragraph.split())
        if not reflowed:
            lines.append('')
            is_first = False
            continue
        if is_first:
            first_wrapped = textwrap.wrap(reflowed, width=width - first_prefix_len,
                                          break_long_words=False,
                                          break_on_hyphens=False)
            lines.extend(first_wrapped if first_wrapped else [''])
            is_first = False
        else:
            wrapped = textwrap.wrap(reflowed, width=width - cont_prefix_len,
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
    print(f"{CYAN}{BOLD}{DISPLAY_NAME}{RESET} {DIM}— CS Tutor{RESET}")
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
            # "Rook → " = display name + " → " = len(DISPLAY_NAME) + 3
            prefix_len = len(DISPLAY_NAME) + 3
            lines = wrap_text(response, first_prefix_len=prefix_len, cont_prefix_len=4)
            for i, line in enumerate(lines):
                if i == 0:
                    print(f"{CYAN}{DISPLAY_NAME} →{RESET} {line}")
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
