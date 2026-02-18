# Terminal Classroom

**Most AI coding tutors are just autocomplete with a chat window. Here's how to build one that actually teaches.**

---

## The Problem

Every AI coding tool on the market is optimized for the same thing: producing code faster. Copilot autocompletes your functions. Cursor rewrites your files. ChatGPT gives you the answer before you finish asking the question.

And if you're a professional shipping features on a deadline, that's great.

But if you're *learning* — if you're a student trying to understand why a red-black tree rotation works, or why your linked list traversal segfaults — getting the answer instantly is the worst thing that can happen to you. It short-circuits the struggle that builds understanding. You get the assignment done, but you don't learn the concept. And next week, when a harder problem builds on that concept, you're lost.

This isn't speculation. It's one of the most robust findings in education research: **students who struggle with a problem before receiving instruction learn more deeply than those who receive instruction first** (Kapur, 2008; 2014). The struggle isn't an obstacle to learning — it *is* the learning.

So here's the question: can you build an AI tutor that's *strategically unhelpful*? One that asks questions instead of giving answers, that watches you work in real time, that remembers what you know and what you don't, and that calibrates its help to keep you in the productive struggle zone?

Yes. That's what this framework is.

---

## What This Is

Terminal Classroom is an open-source framework for building a **pedagogically grounded AI coding tutor** using [OpenClaw](https://github.com/nicholasgasior/openclaw). The tutor:

- **Lives in a tmux pane** alongside your editor and terminal — not a separate app you alt-tab to
- **Sees your terminal output** via `tmux capture-pane` — compiler errors, test results, stack traces, all in real time
- **Watches your files** via `inotifywait` — knows when you save, what changed, without you copying anything
- **Uses the Socratic method** — asks questions before giving answers, provides hints before solutions
- **Maintains persistent memory** — knows what concepts you're solid on and where you're shaky, across sessions
- **Enforces productive struggle** — gives you think-time, detects procrastination, redirects tangents

It's not a product. It's a blueprint and a set of principles, backed by real CS education research, that you can use to configure your own AI tutor.

---

## How It's Different

| Feature | CS50 Duck | Copilot Chat | Cursor | Khanmigo | Continue.dev | **Terminal Classroom** |
|---|---|---|---|---|---|---|
| Socratic method | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Sees your files | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ |
| Sees terminal output | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Persistent memory | ❌ | ❌ | ❌ | Partial | ❌ | ✅ |
| Student knowledge model | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Open source | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Works with any editor | ✅ | ❌ (VS Code) | ❌ (Cursor) | N/A | ❌ (VS Code) | ✅ |
| Anti-distraction design | ❌ | ❌ | ❌ | Partial | ❌ | ✅ |
| Won't give you the answer | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ |

**The gap nobody's filled:** No existing tool combines environment awareness + Socratic pedagogy + persistent memory. Copilot sees your code but doesn't teach. Khanmigo teaches but can't see your code. CS50 Duck teaches but forgets you exist between sessions.

See [docs/comparison.md](docs/comparison.md) for the detailed breakdown.

---

## The Architecture

Your tutor lives in a tmux split alongside your editor:

```
┌────────────────────────────────────────────────────────┐
│                     tmux session                       │
│                                                        │
│  ┌────────────────────────┐  ┌───────────────────────┐ │
│  │  Your editor +         │  │  AI Tutor             │ │
│  │  terminal              │  │                       │ │
│  │                        │  │  "What do you think   │ │
│  │  $ javac Foo.java      │  │   that error means?"  │ │
│  │  error: line 42...     │  │                       │ │
│  │                        │  │  Reads your terminal  │ │
│  │                        │  │  Watches your files   │ │
│  └────────────────────────┘  └───────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

The tutor gets context through two channels:

1. **`tmux capture-pane`** — reads your terminal output (compiler errors, test results, command history)
2. **`inotifywait`** — watches your project directory for file changes

No VS Code extensions. No LSP integration. No copy-pasting error messages into a chat window. Just tmux and the filesystem — tools that work with any editor, any language, any build system.

See [docs/architecture.md](docs/architecture.md) for the full technical deep dive.

---

## Quick Start

### Prerequisites

- [OpenClaw](https://github.com/nicholasgasior/openclaw) installed and configured
- `tmux` installed
- `inotifywait` installed (`sudo apt install inotify-tools` on Debian/Ubuntu)

### 1. Clone this repo

```bash
git clone https://github.com/brezgis/terminal-classroom.git
cd terminal-classroom
```

### 2. Copy the example tutor prompt

```bash
cp examples/soul.md ~/.openclaw/agents/tutor/SOUL.md
```

### 3. Set up course tracking

```bash
mkdir -p ~/.openclaw/agents/tutor/{course-state,session-summaries}
```

### 4. Launch a tutoring session

```bash
# Using the provided launcher script
./examples/setup.sh ~/my-project

# Or manually: create a tmux split with the tutor in the right pane
```

### 5. Add the `rr` command wrapper

The tutor can only see your terminal output if it's captured to a file. Add this to your `~/.bashrc` or `~/.zshrc`:

```bash
rr() { "$@" 2>&1 | tee .terminal.log; }
```

Now use `rr` to run commands in the left pane:

```bash
rr javac MyCode.java    # compile — tutor sees errors
rr java MyCode           # run — tutor sees output
rr python3 solution.py   # works with any language
```

The `.terminal.log` file syncs to the server (via Syncthing, sshfs, or similar), so the tutor can read your compiler errors and output in real time. Without `rr`, the tutor can still see your source files but won't know what happened when you ran them.

### 6. Start working

Open your editor in the left pane. Use `rr` to compile and run. The tutor watches your files and terminal output. When you're stuck, ask it. When you're not stuck, it stays quiet.

---

## The Pedagogy

This isn't "ChatGPT with a system prompt that says be Socratic." The tutoring approach is grounded in decades of CS education research:

### Productive Failure (Kapur, 2008; 2014)

Students who attempt to solve problems *before* receiving instruction develop deeper conceptual understanding than those who receive instruction first. The initial struggle — even when it leads to wrong answers — creates cognitive structures that make subsequent learning more effective. Your tutor enforces this by giving you think-time before hints, and hints before answers.

### The 2-Sigma Problem (Bloom, 1984)

One-on-one tutoring produces learning gains of two standard deviations over classroom instruction. That's the difference between an average student and a top-2% student. The reason: constant calibration to where the learner actually is. Your tutor maintains a knowledge model that tracks exactly this.

### Zone of Proximal Development (Vygotsky, 1978)

There's a sweet spot between "too easy" and "impossible" where learning happens — what you can do with help but not yet alone. The tutor aims to keep you there by adjusting its scaffolding based on your demonstrated understanding.

### Dialogic Pedagogy for LLMs (Beale, 2025)

Recent work on using LLMs for teaching emphasizes that the dialogue structure matters as much as the content. Question-driven interaction, where the learner does most of the cognitive work, produces better outcomes than explanation-driven interaction.

See [docs/pedagogy.md](docs/pedagogy.md) for the full research deep dive.

---

## What's in This Repo

| File | What it is |
|------|-----------|
| [docs/pedagogy.md](docs/pedagogy.md) | Deep dive on the CS education research behind the framework |
| [docs/architecture.md](docs/architecture.md) | Technical architecture: tmux integration, file watching, memory design |
| [docs/comparison.md](docs/comparison.md) | Detailed comparison of existing AI tutoring tools |
| [examples/soul.md](examples/soul.md) | Copy-paste-ready system prompt for your tutor agent |
| [examples/setup.sh](examples/setup.sh) | tmux launcher script with language detection |
| [examples/course-config.md](examples/course-config.md) | Example course configuration and knowledge tracking |
| [tui/](tui/) | Interactive terminal classroom: chat REPL + tmux session launcher |

---

## Philosophy

1. **The best tutor is strategically unhelpful.** If the tutor always makes you feel helped, it's failing. Learning feels like confusion resolving into clarity. That confusion is load-bearing.

2. **Environment awareness changes everything.** The difference between pasting an error into ChatGPT and having a tutor that *already sees* the error is the difference between a web search and a TA sitting next to you. Context eliminates the friction that makes students give up on asking for help.

3. **Memory is the killer feature.** A tutor that forgets you between sessions is just a search engine with personality. Real tutoring is longitudinal — it builds on what came before, notices patterns, adjusts over time.

4. **Anti-distraction is pedagogy.** An AI tutor is one tab away from being a procrastination tool. Detecting tangents, enforcing think-time, and redirecting off-topic conversation aren't bonus features — they're core to making the thing actually work for learning.

5. **Open source matters here.** Every student learns differently. The system prompt, the scaffolding levels, the frustration thresholds — these all need to be tunable. A locked-down product can't do that. A framework you own and modify can.

---

## Contributing

This is a young project. If you're interested in CS education, AI tutoring, or building tools that make people smarter instead of lazier, contributions are welcome. Open an issue, submit a PR, or just fork it and build your own tutor.

---

## License

[MIT](LICENSE)

---

## References

- Bloom, B. S. (1984). The 2 Sigma Problem: The Search for Methods of Group Instruction as Effective as One-to-One Tutoring. *Educational Researcher*, 13(6), 4–16.
- Kapur, M. (2008). Productive Failure. *Cognition and Instruction*, 26(3), 379–424.
- Kapur, M. (2014). Productive Failure in Learning Math. *Cognitive Science*, 38(5), 1008–1022.
- Vygotsky, L. S. (1978). *Mind in Society: The Development of Higher Psychological Processes*. Harvard University Press.
- Beale, R. (2025). Dialogic Pedagogy and Large Language Models. *Proceedings of the ACM Conference on Learning at Scale*.
- Teague, D., & Lister, R. (2015). Programming: Reading, Writing and Reversing. *ACM Conference on Innovation and Technology in Computer Science Education*.
