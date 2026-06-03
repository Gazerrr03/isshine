---
name: isshine-quick
description: "isshine Quick Mode. Invoke with /isshine-quick. Streamlined workflow: define → issue (skip design). For small changes and bug fixes."
---

# isshine Quick Mode

A streamlined workflow for small changes that don't need full technical deep design. Skips the `design` phase entirely.

## When to Use

- Bug fixes with clear root cause
- Small tweaks (copy changes, style fixes, config updates)
- Dependency updates
- User explicitly requests "quick" or "small change"

## Workflow

```
define → issue → done
```

## Steps

### 1. Quick Define

Same as `/isshine-define` but with reduced ceremony:

- **Shorter exploration**: Read only the directly affected files
- **Behavioral Boundaries in proposal.md**: Do not create standalone `harness.md`; add a concise `## Behavioral Boundaries` section to `proposal.md`
- **Simpler design.md**: Just the approach paragraph, no full alternatives analysis
- **Simpler tasks.md**: Flat list, no phase grouping needed

Initialize state:
```bash
bash "$ISSHINE_STATE" init <slug> quick
bash "$ISSHINE_STATE" transition <slug> init-complete
# → phase: define (quick workflow)
```

### 2. Generate Minimal Artifacts

Only the essentials:
- `proposal.md` — Problem + Goals (required)
- `design.md` — One-paragraph approach (lightweight)
- `tasks.md` — Checklist (flat, no phases)

Skip:
- `harness.md` (quick mode uses `proposal.md#Behavioral Boundaries`)
- `technical-design.md`
- `risks.md`

### 3. User Review (Blocking Point)

Single confirmation for all artifacts.

### 4. Transition Directly to Issue

```bash
bash "$ISSHINE_STATE" transition <slug> define-complete
# Quick workflow: define-complete → issue (skips design)
```

### 5. Synthesize and Publish

Same as `/isshine-issue`, but:
- Use `proposal.md#Behavioral Boundaries` as the behavioral source
- Skip risk extraction (no risks.md)
- Skip technical design references
- Human Consumption Layer and Agent Consumption Layer still required

## Exit Conditions

- Issue published to GitHub
- Phase transitioned to `done`

## Quick Mode Limitations

If during quick define you discover:
- The change is larger than expected
- Architecture decisions need deep analysis
- Multiple modules are affected in non-trivial ways

→ **Upgrade to full workflow**:
```bash
bash "$ISSHINE_STATE" set <slug> workflow full
```
Then continue with `/isshine-design` before `/isshine-issue`.
