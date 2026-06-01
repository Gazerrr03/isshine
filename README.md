# ⚡ isshine（一闪）

> Flash of requirement — generate AI-friendly, human-readable GitHub Issues from conversations.

**isshine** transforms the conversation between you and your AI coding assistant into a structured, dual-layer GitHub Issue. It preserves your exact words (not AI-paraphrased summaries), references your project's philosophy and constraints, and ensures information completeness before publishing.

## Why isshine?

### The Problem

Current Issue creation tools have three gaps:

1. **No global context reference** — each Issue is an island. Philosophy, design systems, and anti-goals can't be systematically referenced.
2. **Human input gets compressed** — the TL;DR layer paraphrases your precise instructions, losing accuracy.
3. **No completeness guarantee** — no mechanism checks whether all necessary information layers are present before publishing.

### The Solution

isshine sits between your conversation and the Issue:

```
Conversation → isshine → Dual-Layer Issue
                  ↓
         spec/ (global context, once per project)
         feature/ (per-issue design artifacts)
                     ↓
               PR Comment (for reviewers)
```

**One conversation = one Issue.** The conversation is the "vibe" — the Issue is its crystallization.

## Quick Start

### Installation

```bash
npx skills add rpamis/isshine
```

### First Use

```
/isshine-init
```

This sets up your project's global context (`spec/`):
- **philosophy.md** — product worldview, core principles
- **tech-constraints.md** — technology boundaries
- **anti-goals.md** — what must never happen
- Plus optional: design-system, glossary, architecture

It also defines **processing strategies** — how the model should behave in each phase.

### Create Your First Issue

```
/isshine "add search functionality"
```

The workflow:
1. **Define** — Plan Mode dialogue, generate proposal + design + tasks
2. **Design** — Technical deep design, identify risks
3. **Issue** — Extract your verbatim directions from the transcript, assemble dual-layer Issue, publish

For quick changes:
```
/isshine-quick "fix login timeout"
```

### Generate PR Comment

```
/isshine-pr
```

Produces a reviewer-friendly PR description: what changed, design decisions applied, risk status, verification checklist.

## Architecture

### Three-Layer Information Model

| Layer | Location | Content | Stability |
|-------|----------|---------|-----------|
| **Spec** (Global) | `spec/` | Philosophy, constraints, anti-goals | Fixed (milestone-level changes) |
| **Feature** (Local) | `feature/<slug>/` | Proposal, design, tasks, risks | Semi-fixed (requirement iteration) |
| **Surface** (Output) | `output/<slug>/` | Issue, PR comment | Variable (evolves with development) |

### Dual-Layer Issue

#### Human Consumption Layer
- **TL;DR** — 1-2 sentence summary
- **Direction Inputs** — your exact words from the conversation + AI summary for scanning
- **Decision Points** — choices needing human judgment

#### Agent Consumption Layer
- **Problem Description** — precise, no fluff
- **Current Behavior** — file paths, line numbers, actual code logic
- **Impact Scope** — every file that will be touched
- **Risks & Mitigations** — from the design phase
- **Acceptance Criteria** — mechanically checkable
- **References** — links to full design artifacts

### Project Structure

```
your-project/
├── src/index.yaml              # Router — maps spec ↔ feature relationships
├── spec/                       # Global context (once per project)
│   ├── philosophy.md
│   ├── tech-constraints.md
│   ├── anti-goals.md
│   ├── .processing-strategies.md
│   └── .project-context.md
├── feature/<slug>/             # Per-issue artifacts
│   ├── .isshine.yaml           # State machine
│   ├── proposal.md             # Why + What
│   ├── design.md               # How (high-level)
│   ├── tasks.md                # Implementation checklist
│   ├── technical-design.md     # Deep technical design
│   └── risks.md                # Risk matrix
└── output/<slug>/              # Final deliverables
    ├── issue.md                # The published Issue
    └── pr-comment.md           # PR reviewer guide
```

### Completeness, Not Completion Rate

isshine replaces "Good First Issue" thinking with **information completeness**:

> A quality Issue is not defined by "can an AI complete it in one shot" but by "are all information layers present and non-trivial."

Completeness is checked against the **Spec** defined in each template — every required section must exist with non-placeholder content.

## Commands

| Command | Description |
|---------|-------------|
| `/isshine` | Main entry — detect phase, dispatch to sub-skill |
| `/isshine-init` | Project setup — templates, strategies, checkpoint |
| `/isshine-define` | Requirement definition — Plan Mode → proposal/design/tasks |
| `/isshine-design` | Technical deep design — risks, edge cases, interfaces |
| `/isshine-issue` | Synthesize + publish dual-layer Issue |
| `/isshine-pr` | Generate PR comment from design artifacts |
| `/isshine-quick` | Quick mode — skip deep design for small changes |

## Related

- [Comet](https://github.com/rpamis/comet) — OpenSpec + Superpowers dual-star development workflow
- Built for [Claude Code](https://claude.ai/code)

## License

MIT
