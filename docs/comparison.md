# Comparison of AI Tutoring Tools

A detailed look at what exists, what each tool gets right, and what's missing.

---

## The Landscape

There's no shortage of AI tools for coding. But there's a spectrum from "code assistant" to "actual tutor," and almost everything clusters at the assistant end.

```
Code Assistants ◄────────────────────────────────► Actual Tutors

Copilot  Cursor  Cline  Continue    CodeHelp  CS50 Duck  Khanmigo
  │        │       │       │            │         │          │
  ▼        ▼       ▼       ▼            ▼         ▼          ▼
Gives    Gives   Does    Gives      Gives     Asks you    Asks you
answers  answers  it     answers     hints     to think    to think
fast     fast    for you  fast                  first       first
```

Classroom sits at the far right — but with the environment awareness of the tools on the left.

---

## CS50 Duck Debugger

**What it is:** Harvard's CS50 course provides an AI debugging assistant shaped like a rubber duck. It's explicitly designed to *not* give answers.

**What it gets right:**
- Genuinely Socratic — asks "what do you think this line does?" before helping
- Forces the student to articulate their thinking (rubber duck philosophy)
- Refuses to give direct solutions to assignments
- Well-tested with thousands of students

**What's missing:**
- **No environment awareness.** It can't see your terminal or files. You paste code into a web chat.
- **No memory.** Every conversation starts from scratch. It doesn't know what you struggled with yesterday.
- **No student model.** Treats every student the same regardless of their level.
- **Limited to CS50 context.** Designed for one course, not generalizable.
- **Web-based.** Not integrated into your development environment.

---

## GitHub Copilot Chat

**What it is:** AI assistant integrated into VS Code that can see your open files and answer questions about your code.

**What it gets right:**
- Deep VS Code integration — sees your open files, understands project structure
- Can explain code, suggest fixes, generate tests
- Available inline, doesn't require context-switching

**What's missing:**
- **Optimized for answers, not learning.** Ask "why doesn't this work?" and it'll tell you the fix, not help you find it.
- **No memory.** Every conversation resets. No knowledge of your learning history.
- **No terminal awareness.** Can't see your compiler output, test results, or stack traces.
- **No pedagogical framework.** No scaffolding, no Socratic questioning, no concept of "this student needs to struggle with this."
- **VS Code only.** Locked to one editor.

---

## Cursor

**What it is:** A fork of VS Code with deeply integrated AI. Best-in-class codebase understanding and code generation.

**What it gets right:**
- Excellent codebase understanding — indexes your entire project
- Multi-file editing and refactoring
- Natural language code generation
- Tab-completion that feels like mind-reading

**What's missing:**
- **Actively antithetical to learning.** The entire UX is "describe what you want, AI writes it." This is the opposite of what a student needs.
- **Replaces your editor.** You have to use Cursor instead of VS Code/Vim/whatever you normally use.
- **No pedagogical mode.** There's no way to say "help me understand this" vs. "just do it."
- **Creates dependency.** Students who learn with Cursor often can't code without it — they've learned to prompt, not to program.
- **No memory across sessions.**

---

## Continue.dev

**What it is:** An open-source AI coding assistant that integrates with VS Code and JetBrains IDEs. Model-agnostic — works with any LLM.

**What it gets right:**
- **Open source.** You can extend and modify it.
- **Model-agnostic.** Use Claude, GPT, Llama, whatever.
- **Extensible context.** You can add custom context providers.
- Good IDE integration with autocomplete and chat.

**What's missing:**
- **Still a code assistant.** The UX is optimized for producing code, not for learning.
- **No tutoring framework.** No Socratic mode, no scaffolding, no concept tracking.
- **No persistent memory.** No student model across sessions.
- **VS Code/JetBrains only.** Tied to specific IDEs.

---

## Khanmigo (Khan Academy)

**What it is:** Khan Academy's AI tutor, built on GPT-4. The most pedagogically sophisticated commercial AI tutoring tool.

**What it gets right:**
- **Genuinely Socratic.** Refuses to give answers. Asks guiding questions. Has a real pedagogical framework.
- **Encourages productive struggle.** Designed by educators who understand learning science.
- **Some persistent context** within Khan Academy's platform.
- **Proven at scale** with real students.

**What's missing:**
- **Can't see your code.** It's a chat interface on Khan Academy's website. You can paste code in, but it can't watch your files or terminal.
- **Locked to Khan Academy.** Can't use it with your own projects, courses, or assignments.
- **Not customizable.** You can't adjust the scaffolding levels, the prompts, or the pedagogical approach.
- **Not open source.** Proprietary system, no self-hosting.
- **Limited programming content.** Khan Academy's CS curriculum is introductory.

---

## CodeHelp

**What it is:** An AI tool designed for educational settings that provides hints rather than direct answers. Used by several universities.

**What it gets right:**
- **Hint-based design.** Gives targeted hints instead of complete solutions.
- **Designed for education.** Built with instructor oversight in mind.
- **Tracks interactions.** Instructors can see what students are asking about.

**What's missing:**
- **Web-based only.** No integration with your editor or terminal.
- **No persistent student model.** Doesn't track what you know across sessions.
- **No environment awareness.** Can't see your files or errors.
- **Limited language support.**

---

## What Nobody Has Built (Until Now)

Here's the gap:

| Capability | Who has it |
|---|---|
| Sees your files in real time | Copilot, Cursor, Continue |
| Sees your terminal output | **Nobody** |
| Socratic method | CS50 Duck, Khanmigo |
| Persistent student model | **Nobody** |
| Open source | Continue |
| Works with any editor | CS50 Duck (web) |
| Anti-distraction design | **Nobody** |
| Error pattern tracking | **Nobody** |

Classroom combines all of these:

- **Environment awareness** (tmux + file watchers) from the code assistant world
- **Socratic pedagogy** from the education tools
- **Persistent memory** that nobody else has
- **Open source and editor-agnostic** so you can make it yours

The bet is that these capabilities are multiplicative, not additive. A Socratic tutor that can already see your error is fundamentally different from one where you have to paste the error in. A tutor that remembers you struggled with recursion last week can connect today's problem to that experience. A tutor that detects procrastination patterns can keep the session productive.

No single one of these features is revolutionary. Together, they create something that doesn't exist yet: **an AI that actually teaches you to code, in your own environment, with longitudinal awareness of your learning.**
