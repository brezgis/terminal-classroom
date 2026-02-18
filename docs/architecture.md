# Architecture

How the tutor sees your code, your errors, and your progress — without you lifting a finger.

---

## The Core Insight

Most AI coding tools require you to actively provide context: paste your code, paste the error, explain what you're trying to do. This friction means students either don't ask for help (too much effort) or dump everything at once (no learning).

Classroom's tutor **passively observes your environment** and builds context automatically. You just work. When you want help, the tutor already knows what you're looking at.

---

## tmux Integration

The entire framework runs inside a tmux session. Your editor and terminal occupy the left pane; the tutor occupies the right pane.

```
┌──────────────────────────────────────────────────┐
│                  tmux session                     │
│                                                   │
│  ┌────────────────────┐  ┌─────────────────────┐  │
│  │   Pane 0 (65%)     │  │   Pane 1 (35%)      │  │
│  │                    │  │                      │  │
│  │   Your workspace   │  │   Tutor agent        │  │
│  │   - Editor         │  │   - Conversational   │  │
│  │   - Terminal       │  │   - Context-aware    │  │
│  │   - Tests          │  │                      │  │
│  └────────────────────┘  └─────────────────────┘  │
└──────────────────────────────────────────────────┘
```

### Reading Terminal Output

The tutor reads your terminal via `tmux capture-pane`:

```bash
# Capture the last 200 lines from the work pane
tmux capture-pane -t 0 -p -S -200
```

This gives the tutor access to:
- Compiler errors and warnings
- Test output and failures
- Stack traces
- Command history
- Build tool output (Maven, Gradle, npm, etc.)

The tutor polls this periodically or on demand — not constantly streaming, just checking when relevant.

### Why tmux?

- **Zero dependencies** beyond tmux itself (which you probably already have)
- **Works with any editor** — Vim, Neovim, VS Code in terminal, Emacs, nano, whatever
- **Works with any language and build tool** — if it prints to a terminal, the tutor can see it
- **Survives editor restarts** — the tmux session persists
- **Works over SSH** — tutor works exactly the same on a remote machine
- **No extensions to install** — no VS Code marketplace, no plugin compatibility issues

---

## File Watching

The tutor watches your project directory for changes using `inotifywait`:

```bash
# Watch for file modifications and creations
inotifywait -m -r -e modify,create --format '%w%f' ./src/
```

When you save a file, the tutor:
1. Notices the change event
2. Reads the modified file
3. Updates its understanding of your current code
4. Checks for obvious issues (if configured)

This runs as a background process managed by OpenClaw's `exec`/`process` tools.

### What the Tutor Sees After a Save

```
Event: src/Stack.java modified
→ Read file content
→ Compare with previous version (optional)
→ Note: student added a push() method
→ Ready to discuss if asked
```

The tutor **does not** proactively comment on every save. It updates its context silently and waits for you to ask — or waits for a compilation error that suggests you might need help.

---

## Context Assembly

When the tutor needs to respond, it assembles context from multiple sources:

```
┌─────────────────────────────────────────┐
│           Context Assembly               │
│                                          │
│  ┌──────────────┐  ┌──────────────────┐  │
│  │ Terminal      │  │ File Watcher     │  │
│  │ Output        │  │ Events           │  │
│  │ (capture-pane)│  │ (inotifywait)    │  │
│  └──────┬───────┘  └────────┬─────────┘  │
│         │                    │            │
│         ▼                    ▼            │
│  ┌──────────────────────────────────────┐ │
│  │        Current Context               │ │
│  │  - Latest terminal output            │ │
│  │  - Current file contents             │ │
│  │  - Recent error messages             │ │
│  └──────────────┬───────────────────────┘ │
│                 │                          │
│                 ▼                          │
│  ┌──────────────────────────────────────┐ │
│  │        Persistent Context            │ │
│  │  - Student knowledge model           │ │
│  │  - Course state                      │ │
│  │  - Session history                   │ │
│  │  - Error patterns                    │ │
│  └──────────────┬───────────────────────┘ │
│                 │                          │
│                 ▼                          │
│  ┌──────────────────────────────────────┐ │
│  │        Pedagogy Engine               │ │
│  │  (System prompt + knowledge model)   │ │
│  │  → Decides scaffolding level         │ │
│  │  → Generates response                │ │
│  └──────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## Session Structure

Every tutoring session follows a deliberate arc:

### 1. Opening
The tutor reads the course state file and recent session summaries, then asks:
> "What are we working on today?"

This forces the student to articulate their goal — which is itself a learning act.

### 2. Core Work
The student works in the left pane. The tutor watches passively. When the student asks for help or hits a wall, the tutor responds using the [Socratic Ladder](pedagogy.md#the-socratic-ladder), calibrated to the student's knowledge level for that concept.

### 3. Checkpoints (~every 20 minutes)
The tutor pauses the work:
> "Quick check: can you explain what a balanced BST property means in your own words?"

Retrieval practice — the single most evidence-backed study technique.

### 4. Closing
When the session ends, the tutor generates a summary:

```markdown
## Session Summary
**Date:** 2026-02-17 14:00–15:30

### Covered
- Binary search tree insertion
- AVL tree rotations (single)

### Demonstrated Understanding
- Can trace BST insertion independently
- Understands why balance matters for O(log n)

### Struggled With
- Double rotations (left-right case)
- Couldn't visualize the intermediate state

### Next Session
- Revisit double rotations with diagrams
- Introduce red-black trees if double rotations click
```

This summary persists and is read at the start of the next session for continuity.

---

## Memory Design

### Knowledge Model

The tutor maintains a per-course knowledge model in YAML:

```yaml
course: data-structures
concepts:
  arrays:
    level: solid
    last_seen: 2026-02-15
  linked-lists:
    level: working
    last_seen: 2026-02-14
  recursion:
    level: shaky
    last_seen: 2026-02-16
    notes: "gets base case but struggles with recursive step"
  generics:
    level: confused
    last_seen: 2026-02-17
    notes: "wildcard types especially"

error_patterns:
  - pattern: "NullPointerException"
    frequency: high
    understanding: "knows what it means but doesn't proactively check"
  - pattern: "off-by-one in loops"
    frequency: medium
    understanding: "improving — was every time, now occasional"
```

### Mastery Levels

| Level | Meaning | Tutor Behavior |
|-------|---------|---------------|
| `confused` | Doesn't understand the concept | Direct instruction, worked examples |
| `intro` | Has seen it, can't apply independently | Heavy scaffolding, step-by-step |
| `shaky` | Can sometimes do it, inconsistent | Socratic questioning, targeted hints |
| `working` | Can do it with occasional help | Light touch, struggle first |
| `solid` | Reliable, can explain to others | Don't explain unless asked |

### Error Pattern Tracking

The tutor distinguishes between:

- **Syntax/mechanical errors** (missing semicolons, wrong brackets): Brief correction. These diminish with practice — don't lecture.
- **Conceptual errors** (`==` for string comparison, confusion about references vs. values): These need teaching. Track them, revisit them.
- **Design errors** (bad naming, no decomposition, god methods): Note but deprioritize while the student is still learning fundamentals.

### Session Summaries

Each session produces a markdown summary stored in `session-summaries/`. These provide longitudinal tracking:
- What was worked on and when
- Which concepts clicked
- What needs revisiting
- Engagement patterns over time

---

## Inter-Agent Communication

If you're running multiple OpenClaw agents, the tutor can communicate with them:

### Idea Routing

When the student has an idea mid-session that's not about the current work:

1. The tutor acknowledges it: "Good thought — I'll save that."
2. Writes it to a shared file (e.g., `idea-dumps.jsonl`)
3. Redirects: "Back to the problem — where were we?"

This protects focus while ensuring nothing gets lost.

### Session Summaries for Other Agents

Other agents can read the tutor's session summaries to understand:
- What the student is learning
- Where they're struggling
- How much time they're spending on coursework

This enables coordination without the student having to repeat themselves.

---

## Proactive vs. Reactive Behavior

**Default: Reactive.** The tutor stays silent while you work. It only speaks when spoken to.

**Exception: Gentle nudge.** If the tutor notices a compilation error and you haven't made progress in ~30 seconds, it might offer:
> "I noticed a compilation error. Want to talk through it?"

If you ignore the offer, it goes back to silence.

**Student-controlled modes:**
- `@tutor watch` — Proactive mode. The tutor comments on errors as they happen.
- `@tutor quiet` — Silent mode. Only responds when directly asked.
- `@tutor just tell me` — Bypass Socratic method for this question. Sometimes you just need the answer.

---

## What's NOT in v1

Some things that could enhance the tutor but aren't worth the complexity yet:

- **LSP integration** — Language Server Protocol could provide richer error context (types, go-to-definition). But compiler output via tmux gives 90% of the value for 10% of the complexity.
- **Spaced repetition engine** — Formal SRS for concept review. The knowledge model approximates this informally.
- **Analytics dashboard** — Visual progress tracking over time. The session summaries provide the raw data; visualization can come later.
- **Multi-student support** — The framework assumes one student. Classroom use would need per-student profiles and auth.
