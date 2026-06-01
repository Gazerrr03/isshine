---
name: isshine-design
description: "isshine Phase 2: Design. Invoke with /isshine-design. Technical deep design — generate technical-design doc, identify risks and mitigations."
---

# isshine Phase 2: Deep Design

Technical deep design: take the high-level approach from proposal.md + design.md and produce detailed technical specification, edge case analysis, and risk identification.

## Prerequisites

- `feature/<slug>/.isshine.yaml` exists with phase = `design`
- proposal.md, design.md, tasks.md exist and are non-empty

## Steps

### 0. Entry State Verification

```bash
ISSHINE_SCRIPTS="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
ISSHINE_STATE="${ISSHINE_SCRIPTS}/isshine-state.sh"

bash "$ISSHINE_STATE" check <slug> design
```

Proceed only after verification passes.

### 1. Load Context

Read all existing artifacts:
- `spec/` — global constraints and philosophy
- `feature/<slug>/proposal.md` — problem, goals, scope
- `feature/<slug>/design.md` — high-level approach
- `feature/<slug>/tasks.md` — implementation plan
- `spec/.processing-strategies.md` — phase conventions

### 2. Enter Plan Mode

**Must use Plan Mode** for deep design (per processing strategies). The design phase requires thought space to reason about:
- Architecture patterns and trade-offs
- Edge cases and failure modes
- Risk surfaces and mitigation strategies

### 3. Generate Technical Design

Create `feature/<slug>/technical-design.md` from template `assets/templates/feature/technical-design.md`.

Key sections:

#### Data Flow
Trace how data moves through the system:
- Input → Processing → Output
- What state changes occur?
- What external systems are involved?

#### Interfaces
Define every interface/API contract:
- Function signatures
- REST endpoints
- Database schema changes
- Event/message formats
- Error handling for each

#### Edge Cases
Must list at least 3 edge cases:
- Empty input / null / undefined
- Concurrent access / race conditions
- Network failure / timeout
- Authorization failure
- Rate limiting / throttling
- Data volume extremes

For each: expected behavior + handling strategy.

#### Performance Considerations
- Any N+1 queries?
- Memory pressure points?
- Blocking operations?

### 4. Identify Risks

Create `feature/<slug>/risks.md` from template `assets/templates/feature/risks.md`.

Must identify at least **3 risks** (per processing strategies minimum).

Risk identification approach:
1. **Security scan**: What could an attacker exploit?
2. **Dependency scan**: What upstream failures cascade?
3. **Data scan**: What data could be lost or corrupted?
4. **UX scan**: What user flows could break?
5. **Performance scan**: What could become slow under load?

For each risk:
- **Description**: Concrete scenario, not abstract concern
- **Severity**: Critical / High / Medium / Low
- **Likelihood**: High / Medium / Low
- **Mitigation**: What we do now to prevent it
- **Trigger**: Early warning signal
- **Fallback**: What we do if it materializes

### 5. Cross-Reference Check

Verify alignment between artifacts:
- Does technical-design.md implement the approach in design.md? If diverging, note why.
- Do risks.md entries cover the edge cases in technical-design.md?
- Are any tasks in tasks.md missing based on the technical design?

Flag inconsistencies to user.

### 6. Run Completeness Check

```bash
bash "$ISSHINE_CHECK" <slug>
```

Review results. If checks fail:
- Fill missing sections
- Replace placeholder content
- Re-run check

### 7. User Review and Confirmation (Blocking Point)

**Must use AskUserQuestion.** Present:

**Summary content:**
- **Technical Design**: Architecture approach, key interfaces, critical edge cases
- **Risks**: Top 3 risks by severity, mitigation summary
- **Completeness**: Check results (passed X of Y checks)
- **Cross-Reference**: Any inconsistencies found

**Options:**
- "Confirm, proceed to next phase"
- "Adjust technical design" — modify technical-design.md
- "Adjust risks" — modify risks.md
- "Return to define phase" — requirements need more clarity

### 8. Fallback to Define

If the user or model determines that design.md is insufficient to support deep technical design:
1. Inform user: "The high-level design needs more clarity before deep design can proceed."
2. Run `bash "$ISSHINE_STATE" set <slug> phase define` to revert
3. Invoke `/isshine-define` to redo the define phase

## Exit Conditions

- technical-design.md created with all Spec sections filled
- risks.md created with at least minimum risk count
- Completeness check passes
- User confirmed
- Run `bash "$ISSHINE_STATE" transition <slug> design-complete` — advances to `issue`

## Post-Design

```
✅ Phase: design → issue
📁 feature/<slug>/
   ├── proposal.md
   ├── design.md
   ├── tasks.md
   ├── technical-design.md  — Deep design
   └── risks.md              — Risk matrix

🔗 Next: /isshine-issue (auto-transitioning...)
```

**Immediately invoke `/isshine-issue`** to synthesize and publish the Issue.
