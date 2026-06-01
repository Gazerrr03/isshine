---
name: isshine-define
description: "isshine Phase 1: Define. Invoke with /isshine-define. Requirement definition — read spec, explore code, enter Plan Mode dialogue, generate proposal/harness/design/tasks."
---

# isshine Phase 1: Define

Define the requirement: read global context, explore relevant code, enter Plan Mode for human-AI alignment, and generate the four foundation artifacts, including the behavioral harness.

## Prerequisites

- `spec/` directory exists (run `/isshine-init` first)
- `src/index.yaml` exists
- Either: no active feature, OR `.isshine.yaml` phase = `define`

## Steps

### 0. Load Global Context

**Must execute first.** Read the project context:

1. Read `src/index.yaml` for routing information
2. Read `spec/.project-context.md` for checkpoint and strategy summary
3. Read `spec/.processing-strategies.md` for phase-specific conventions
4. Read all activated `spec/*.md` files (philosophy, anti-goals, tech-constraints, etc.)

### 1. Understand the Request

Engage the user to understand:
- **What** needs to be done (the feature, fix, or change)
- **Why** now (the urgency or context)
- **Where** in the codebase (modules, files, systems affected)

Based on processing strategies, enter Plan Mode for this dialogue. Plan Mode provides thought space for the model to reason about requirements.

### 2. Explore Relevant Context

Gather context proportional to the task complexity:

**Always do:**
- `git log --oneline -10` — recent changes
- `gh issue list --limit 10` — related issues
- `gh pr list --limit 5` — in-flight PRs that may conflict

**Based on scope:**
| Complexity | Exploration Depth |
|------------|-------------------|
| Simple (bug fix, small tweak) | Read the 1-2 files mentioned by user |
| Medium (feature, refactor) | Read affected files + 1 layer of dependencies |
| Complex (new module, architecture change) | Full trace: read files, dependencies, tests, configs |

Respect the processing strategy's code exploration depth limit.

### 3. Generate Feature Slug

Create a short, descriptive slug for the feature:

- Lowercase, hyphens for spaces
- Examples: `search-function`, `fix-login-timeout`, `user-auth-refactor`
- Confirm with user if the auto-generated slug is acceptable

### 4. Initialize Feature Directory

```bash
# Locate isshine scripts
ISSHINE_SCRIPTS="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
ISSHINE_STATE="${ISSHINE_SCRIPTS}/isshine-state.sh"

# Initialize state
bash "$ISSHINE_STATE" init <slug> full

# Set session reference (current conversation)
bash "$ISSHINE_STATE" set <slug> session_ref "<current-session-id>"
```

`init` automatically records `issue_context_start_ref` in `.isshine.yaml`. This checkpoint marks the beginning of the feature's requirement-convergence window for later Human Inputs extraction.

Directory created:
```
feature/<slug>/
└── .isshine.yaml    # phase: init
```

Then transition:
```bash
bash "$ISSHINE_STATE" transition <slug> init-complete
# → phase: define
```

### 5. Requirement Definition Dialogue (Plan Mode)

**This is the core of the Define phase.** Enter Plan Mode and align with the user on:

1. **Problem boundary** — What exactly is the problem? What is NOT the problem?
2. **Success criteria** — How will we know this is done?
3. **Scope** — What files/modules will be touched? What is explicitly out of scope?
4. **Constraints** — What tech constraints apply? What anti-goals must not be violated?
5. **Approach direction** — High-level architectural approach (for design.md)

Throughout this dialogue:
- Reference `spec/` principles whenever they apply
- When the user makes a high-quality, direction-setting statement, preserve it as a candidate Human Input for the final Issue. Good candidates define scope, reject approaches, set acceptance criteria, or express product/priority/risk judgment.
- Ask clarifying questions when scope is ambiguous
- Do NOT jump to implementation details — that's for Phase 2 (design)

### 6. Generate Artifacts

Based on the dialogue, generate four files in `feature/<slug>/`:

#### proposal.md
Use template: `assets/templates/feature/proposal.md`

Key sections to fill:
- **Problem**: From the dialogue — what problem, why now
- **Goals**: Concrete, measurable outcomes
- **Scope**: In scope + Out of scope
- **Related**: Link to existing issues/PRs

#### harness.md
Use template: `assets/templates/feature/harness.md`

Key sections to fill:
- **What It Is**: Behavioral definition of the feature, not an implementation plan
- **In Scope / Out of Scope**: What the feature must support and must not take on
- **Behavioral Contract**: Concrete rules later phases must preserve
- **Done Means**: Checkable feature-level success conditions

#### design.md
Use template: `assets/templates/feature/design.md`

Key sections to fill:
- **Approach**: The chosen high-level direction (NOT detailed implementation)
- **Harness Alignment**: The approach must preserve `harness.md`
- **Alternatives Considered**: What else was discussed and why rejected
- **Architecture Impact**: What modules/files will be affected
- **Dependencies**: New libraries, services, or upstream changes needed

#### tasks.md
Use template: `assets/templates/feature/tasks.md`

Key rules:
- Tasks must be **ordered by dependency** (earlier tasks unblock later ones)
- Each task is a **single verifiable unit of work**
- Group tasks into phases (Foundation → Core Logic → Integration & Polish)
- Each task must have a checkbox `- [ ]`

### 7. Update Router

Add the feature to `src/index.yaml`:

```yaml
features:
  - slug: <slug>
    path: feature/<slug>/
    phase: define
    refs:
      - spec/philosophy.md#<relevant-section>
      - spec/anti-goals.md#<relevant-section>
```

### 8. User Review and Confirmation (Blocking Point)

**Must use AskUserQuestion to pause.** Present a summary:

**Summary content:**
- **proposal.md**: Problem, goals, scope summary (2-3 sentences each)
- **harness.md**: Behavioral boundaries, feature rules, and done signals
- **design.md**: Approach summary, key architectural decisions
- **tasks.md**: Task count, phase breakdown

**Options:**
- "Confirm, proceed to next phase" — artifacts meet expectations
- "Needs adjustment" — modify and re-present

After user confirms, proceed to exit conditions.

## Exit Conditions

- proposal.md, harness.md, design.md, tasks.md all created with non-empty content
- `src/index.yaml` updated with feature route
- User has confirmed artifacts
- **Phase guard**: Run `bash "$ISSHINE_STATE" check <slug> define` — validates phase is `define`
- Run `bash "$ISSHINE_STATE" transition <slug> define-complete` — advances to `design`

## Post-Define

```
✅ Phase: define → design
📁 feature/<slug>/
   ├── proposal.md    — Why + What
   ├── harness.md     — Behavioral boundaries
   ├── design.md      — How (high-level)
   └── tasks.md       — Implementation checklist

🔗 Next: /isshine-design (auto-transitioning...)
```

**Immediately invoke `/isshine-design`** to continue the workflow.
