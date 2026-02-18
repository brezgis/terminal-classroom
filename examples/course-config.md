# Course Configuration Example

How to set up per-course knowledge tracking for your tutor.

---

## Directory Structure

```
~/.openclaw/agents/tutor/
├── SOUL.md                    # Tutor system prompt (see examples/soul.md)
├── course-state/              # Per-course knowledge models
│   ├── data-structures.md     # Updated each session
│   ├── algorithms.md
│   └── web-dev.md
├── session-summaries/         # Session logs
│   ├── 2026-02-15-14-data-structures.md
│   ├── 2026-02-16-10-algorithms.md
│   └── ...
└── idea-dumps.jsonl           # Routed tangents
```

---

## Course State File

Create one per course. The tutor reads this at session start and updates it at session end.

### Example: `course-state/data-structures.md`

```markdown
# Data Structures — Course State

## Current Topics
Working through: trees and balanced BSTs
Next up: heaps and priority queues

## Concept Mastery

### Solid (independent)
- Arrays and array operations
- Linked lists (singly and doubly)
- Stacks and queues (array-based and linked)
- Big-O basics (constant, linear, logarithmic)

### Working (occasional help needed)
- Binary search trees (insertion, search, traversal)
- Recursion (simple cases)
- Hash tables (chaining)

### Shaky (needs scaffolding)
- Recursion (complex/multi-branch)
- AVL rotations (single rotations OK, double rotations unclear)
- Generic types

### New / Not Yet Covered
- Red-black trees
- Heaps
- Graphs
- Sorting algorithms

## Error Patterns

| Pattern | Frequency | Notes |
|---------|-----------|-------|
| NullPointerException | High | Knows what it means, doesn't proactively check |
| Off-by-one in loops | Medium | Improving — used to be constant |
| Forgetting edge cases (empty list) | Medium | Needs reminding to consider edge cases |
| Generic type syntax | High | Confused by wildcards and bounded types |

## Learning Notes
- Thinks well in terms of linguistic structures — analogies to sentence parsing work well for trees
- Tends to jump to coding before planning — encourage pseudocode first
- Gets frustrated after ~15 minutes of being stuck
- Responds well to "trace through with a specific example" prompts
```

---

## Setting Up a New Course

1. **Create the course state file:**

```bash
touch ~/.openclaw/agents/tutor/course-state/my-course.md
```

2. **Initialize with what you know:**

```markdown
# My Course — Course State

## Current Topics
Starting with: [first topic]

## Concept Mastery

### Solid
- [things you're confident in]

### Working
- [things you mostly get]

### Shaky
- [things you struggle with]

### New
- [everything else on the syllabus]

## Error Patterns
(Will be filled in as patterns emerge)

## Learning Notes
- [Your learning style preferences]
- [What kinds of explanations work for you]
- [Your frustration tolerance]
```

3. **Tell the tutor about it** at the start of your first session. It will maintain the file from there.

---

## Multiple Courses

The tutor switches context based on what you're working on. You can:

- **Explicitly say:** "Let's work on algorithms today"
- **Let it detect from the directory:** If your algorithms homework is in `~/cs/algorithms/hw3/`, the tutor can infer the course
- **Set it in the launcher:** `./setup.sh ~/cs/algorithms/hw3/`

The key is that each course has its own knowledge model. Being solid on arrays in data structures doesn't mean the tutor skips array-related concepts in an algorithms course — the context and depth are different.

---

## Tips

- **Be honest in your initial assessment.** If you mark something "solid" when it's actually "shaky," the tutor will under-scaffold and you'll get frustrated.
- **Let the tutor update the file.** Don't manually edit mastery levels after the initial setup — the tutor's assessment is based on what it observes in sessions.
- **Review session summaries periodically.** They're a great record of your learning arc over a semester.
- **Error patterns are gold.** If the tutor notices you make the same mistake repeatedly, that's a signal to spend dedicated time on that concept.
