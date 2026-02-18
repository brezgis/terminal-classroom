# Terminal Classroom TUI

A tmux-based study environment that puts your terminal and AI tutor side by side — no browser, no alt-tabbing, no copy-pasting error messages.

## Why a TUI?

Most AI coding tutors live in a browser or a VS Code sidebar. You write code, hit an error, copy it, paste it into the chat, wait for a response, copy the suggestion back. That friction adds up.

This setup puts the tutor *in your terminal*. You compile, the tutor sees the error. You edit a file, the tutor sees the change. No copy-paste loop.

## How It Works

```
┌─────────────────────────────┬──────────────────────────────┐
│                             │                              │
│  Your Terminal              │  Tutor Chat                  │
│                             │                              │
│  $ rr javac MyCode.java    │  tutor: What error are you   │
│  MyCode.java:12: error:    │  seeing on line 12?          │
│    incompatible types       │                              │
│  $ rr java MyCode          │  you → I think it's because  │
│  Output: [1, 3, 5, 7]      │  I'm returning an int...     │
│                             │                              │
└─────────────────────────────┴──────────────────────────────┘
```

The left pane is your normal terminal. The right pane is an interactive chat with your tutor agent. The `rr` command wraps your commands and logs output to `.terminal.log`, which syncs to the server so the tutor can read it.

## Setup

### 1. Install the launcher

```bash
chmod +x tutor-session.sh tutor-chat.sh
```

### 2. Add the `rr` alias to your shell

Add this to `~/.bashrc` or `~/.zshrc`:

```bash
rr() {
  "$@" 2>&1 | tee .terminal.log
}
```

This runs any command and saves its output (including errors) to `.terminal.log` in the current directory.

### 3. Set up file sync

The tutor needs to see your files. Options:

- **Syncthing** (recommended): Sync your project directory to the server. Free, encrypted, peer-to-peer.
- **sshfs**: Mount the remote directory locally (or vice versa).
- **rsync + fswatch**: Watch for changes and sync on save.

The key requirement: when you save a file or run a command, the tutor should be able to read the result within a few seconds.

### 4. Launch

```bash
./tutor-session.sh <agent-name> <server-host>

# Examples:
./tutor-session.sh tutor localhost      # local OpenClaw
./tutor-session.sh rook myserver        # remote via SSH
```

## File Flow

```
local machine                          server (agent)
~/projects/my-project/     ←sync→      /synced/projects/my-project/
  MyCode.java              (1-5s)       MyCode.java  ← tutor reads
  .terminal.log                         .terminal.log ← tutor reads
```

## tmux Controls

| Action | Key |
|--------|-----|
| Switch panes | Click (mouse mode) or `Ctrl+B` then arrow |
| Resize panes | Drag the divider |
| Scroll | Mouse scroll in the pane |
| Detach (keep running) | `Ctrl+B` then `d` |
| Reattach | `tmux attach -t <agent-name>` |
| Kill session | `tmux kill-session -t <agent-name>` |

## What the Tutor Sees

When configured to watch your project directory, the tutor can:

- **Read your source files** — sees your code as you write it
- **Read `.terminal.log`** — sees compiler errors, test output, runtime exceptions
- **Track changes over time** — knows what you just modified
- **Not** keylog or watch in real-time — it reads files when you ask a question, not continuously
