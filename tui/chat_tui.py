#!/usr/bin/env python3
"""Textual TUI chat app for OpenClaw agents."""
from __future__ import annotations

import asyncio
import os
import random
import sys
import shlex

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.widgets import RichLog, TextArea, Static
from textual.containers import Vertical
from textual.timer import Timer
from rich.text import Text


AGENT = (sys.argv[1] if len(sys.argv) > 1 else os.environ.get("AGENT", "tutor")).lower()
DISPLAY_NAME = AGENT.capitalize()
SERVER = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("SERVER", "localhost")

THINKING_MESSAGES = [
    "Compiling thoughts",
    "Traversing the tree",
    "Searching the heap",
    "Resolving dependencies",
    "Optimizing",
    "Dereferencing pointers",
    "Unwinding the stack",
    "Consulting the docs",
    "Running the garbage collector",
    "Rebalancing the tree",
    "Checking edge cases",
    "Reducing to base case",
    "Following the linked list",
    "Hashing it out",
    "Building the parse tree",
    "Evaluating the expression",
    "Allocating brain cells",
    "Performing a deep copy",
    "Sorting thoughts in O(n log n)",
    "Awaiting the future",
]


def _find_openclaw(server: str):
    """Find openclaw binary — check env, common nvm paths, then bare name."""
    if os.environ.get("OPENCLAW"):
        return os.environ["OPENCLAW"]
    if server != "localhost":
        # Remote mode: try common nvm install paths on server
        return "openclaw"
    import shutil
    if shutil.which("openclaw"):
        return "openclaw"
    import glob
    for p in glob.glob(os.path.expanduser("~/.nvm/versions/node/*/bin/openclaw")):
        return p
    return "openclaw"


OPENCLAW = _find_openclaw(SERVER)
REMOTE_PATH = f"PATH={os.path.dirname(OPENCLAW)}:$PATH" if OPENCLAW != "openclaw" else "PATH=$PATH"


def build_command(message: str) -> list[str]:
    """Build the command to send a message to an agent."""
    escaped = message.replace("'", "'\\''")
    payload = f"[terminal] {escaped}"
    if SERVER == "localhost":
        return [OPENCLAW, "agent", "--agent", AGENT, "--message", payload]
    else:
        remote_cmd = f"{REMOTE_PATH} {OPENCLAW} agent --agent {AGENT} --message {shlex.quote(payload)}"
        return ["ssh", SERVER, remote_cmd]


class ChatInput(TextArea):
    """Multi-line input with Enter to send."""

    BINDINGS = [
        Binding("ctrl+c", "app.quit", "Quit", show=False, priority=True),
        Binding("ctrl+d", "app.quit", "Quit", show=False, priority=True),
    ]

    def _on_key(self, event) -> None:
        if event.key == "enter":
            event.prevent_default()
            event.stop()
            text = self.text.strip()
            if text:
                self.app.send_message(text)
                self.clear()


class ChatApp(App):
    """OpenClaw agent chat TUI."""

    CSS_PATH = "chat_tui.tcss"
    TITLE = "Terminal Classroom"
    ENABLE_COMMAND_PALETTE = False
    BINDINGS = [
        Binding("ctrl+c", "quit", "Quit", show=True),
        Binding("ctrl+d", "quit", "Quit", show=False),
    ]

    _spinner_frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    _spinner_index = 0
    _spinner_timer: Timer | None = None
    _thinking_msg = ""
    _messages: list[str] = []  # stored markup lines for reflow on resize

    def compose(self) -> ComposeResult:
        yield Static(
            f"[bold #89b4fa]{DISPLAY_NAME}[/bold #89b4fa] [dim]— CS Tutor[/dim]\n"
            f"[dim]Type your message and press Enter. Ctrl+C or Ctrl+D to exit.[/dim]",
            id="header",
        )
        with Vertical():
            chat = RichLog(id="chat", wrap=True, highlight=False, markup=True)
            chat.can_focus = False
            yield chat
            yield Static("", id="spinner")
            yield ChatInput(id="input")

    def _write_msg(self, markup: str) -> None:
        """Write a line to the chat log and store it for reflow."""
        self._messages.append(markup)
        self.query_one("#chat", RichLog).write(markup)

    def _reflow(self) -> None:
        """Clear and rewrite all messages to reflow at new width."""
        chat = self.query_one("#chat", RichLog)
        chat.clear()
        for msg in self._messages:
            chat.write(msg)

    def on_resize(self, event) -> None:
        """Reflow chat content when terminal is resized."""
        self._reflow()

    def on_mount(self) -> None:
        self.query_one("#input").focus()

    def _start_spinner(self) -> None:
        self._spinner_index = 0
        self._thinking_msg = random.choice(THINKING_MESSAGES)
        spinner = self.query_one("#spinner", Static)
        spinner.update(f"  [dim]{self._spinner_frames[0]} {self._thinking_msg}...[/dim]")
        spinner.display = True
        self._spinner_timer = self.set_interval(0.08, self._tick_spinner)

    def _tick_spinner(self) -> None:
        self._spinner_index = (self._spinner_index + 1) % len(self._spinner_frames)
        frame = self._spinner_frames[self._spinner_index]
        self.query_one("#spinner", Static).update(
            f"  [dim]{frame} {self._thinking_msg}...[/dim]"
        )

    def _stop_spinner(self) -> None:
        if self._spinner_timer:
            self._spinner_timer.stop()
            self._spinner_timer = None
        self.query_one("#spinner", Static).display = False

    def send_message(self, text: str) -> None:
        from rich.markup import escape
        self._write_msg("")  # spacing before user message
        self._write_msg(f"[bold #a6e3a1]You →[/bold #a6e3a1] {escape(text)}")
        self._write_msg("")  # spacing between user and agent
        self._start_spinner()
        self._run_response(text)

    def _run_response(self, text: str) -> None:
        """Launch response fetch as a background task (no worker = no loading bar)."""
        asyncio.get_event_loop().create_task(self._get_response(text))

    async def _get_response(self, text: str) -> None:
        cmd = build_command(text)
        try:
            proc = await asyncio.create_subprocess_exec(
                *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
            )
            stdout, stderr = await proc.communicate()
            raw = (stdout.decode() + stderr.decode()).strip()
            lines = [l for l in raw.splitlines() if l.strip().lower() not in ("completed", "sent", "queued")]
            response = "\n".join(lines).strip()
            self._stop_spinner()
            from rich.markup import escape
            if response:
                self._write_msg(f"[bold #89b4fa]{DISPLAY_NAME} →[/bold #89b4fa] {escape(response)}")
            else:
                self._write_msg("[dim](no response)[/dim]")
        except Exception as e:
            self._stop_spinner()
            from rich.markup import escape
            self._write_msg(f"[bold red]Error:[/bold red] {escape(str(e))}")


if __name__ == "__main__":
    ChatApp().run()
