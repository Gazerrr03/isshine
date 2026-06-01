---
name: isshine
description: "isshine main entry — flash of requirement. Invoke with /isshine. Detect phase and dispatch to sub-skills to generate AI-friendly GitHub Issues from conversations."
---

# isshine — Flash of Requirement

Generate AI-friendly, human-readable GitHub Issues from conversations. One conversation = one Issue.

## Prerequisites

- Working in a git repository
- `gh` CLI authenticated (`gh auth status`)
- (First use) Run `/isshine-init` to set up project-level spec/ and processing strategies

## Dispatch Logic

When user invokes `/isshine`, determine the current state and dispatch:

### Priority-Ordered Decision Table

| # | Condition | Action |
|---|-----------|--------|
| 1 | `spec/` directory does not exist | Invoke `/isshine-init` first |
| 2 | `feature/<slug>/.isshine.yaml` exists, phase != done | Resume from current phase (invoke corresponding sub-skill) |
| 3 | No active feature, or user wants new feature | Create new feature, invoke `/isshine-define` |
| 4 | User says "quick" or "small" or "fix" | Invoke `/isshine-quick` |
| 5 | Feature phase = done, user wants PR comment | Invoke `/isshine-pr` |

### Phase → Sub-skill Mapping

| .isshine.yaml phase | Sub-skill |
|---------------------|-----------|
| `init` | `/isshine-init` |
| `define` | `/isshine-define` |
| `design` | `/isshine-design` |
| `issue` | `/isshine-issue` |
| `done` | Report completion, suggest `/isshine-pr` for PR comment |

### Resume

When `.isshine.yaml` exists with phase other than `done`:
1. Read `.isshine.yaml` to understand current state
2. Check which artifacts exist and are non-empty
3. Resume from the first incomplete step in the current phase
4. Do NOT redo completed work

### Direct Invocation

Users can also directly invoke sub-skills:
- `/isshine-init` — re-run project initialization
- `/isshine-define` — start a new requirement definition
- `/isshine-design` — run technical deep design on existing artifacts
- `/isshine-issue` — re-synthesize Issue from existing artifacts
- `/isshine-pr` — generate PR comment from artifacts
- `/isshine-quick` — quick mode: define → issue (skip design)

## Global Context Loading

Before dispatching, always:
1. Read `src/index.yaml` to understand available specs and active features
2. Load referenced `spec/` files into context
3. Apply processing strategies defined during init

## Script Setup

```bash
ISSHINE_ROOT="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
if [ -z "$ISSHINE_ROOT" ]; then
  echo "ERROR: isshine scripts not found. Ensure the isshine skill is installed." >&2
  return 1
fi
ISSHINE_STATE="${ISSHINE_ROOT}/isshine-state.sh"
ISSHINE_CHECK="${ISSHINE_ROOT}/isshine-check.sh"
ISSHINE_TRANSCRIPT="${ISSHINE_ROOT}/isshine-transcript.sh"
```

## Post-Dispatch

After a sub-skill completes, if the phase transitioned forward, report progress:
```
✅ Phase: [old] → [new]
📁 feature/<slug>/
🔗 Next: /isshine-<next-phase>
```
