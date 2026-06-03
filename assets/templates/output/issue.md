# Issue: [Feature Name]

## Document Contract

| Field | Value |
|-------|-------|
| Scope | Output |
| Primary Consumer | GitHub Issue |
| Secondary Consumer | AI coding agent |
| Stability | Delivery-level; update when the published issue content changes |
| Owns | Dual-layer issue, behavioral summary, implementation scope, and acceptance criteria |
| Should Not Contain | Full source docs, ungrounded work, or unrelated implementation detail |

> **Spec**:
> - `## TL;DR` — must be 1-2 sentences, non-empty
> - `## 📖 Direction Context` — must reference at least 1 spec/ file
> - `## 🎯 Decision Points` — if the define phase identified decisions, must list them
> - `## 📋 Problem Description` — must be non-empty
> - `## 🔍 Current Behavior` — must list at least 1 file with line numbers
> - `## ✅ Acceptance Criteria` — must list at least 1 checkable criterion

## TL;DR
[1-2 sentences summarizing what this issue will change. Keep this short; do not compress important human direction here.]

## 📖 Direction Context
> Related: [[spec/philosophy#...]], [[spec/anti-goals#...]]
> Behavioral source: [[feature/[slug]/harness.md]] (full) or [[feature/[slug]/proposal.md#Behavioral-Boundaries]] (quick)

## Human Inputs
<!-- Preserve high-quality user inputs from the checkpoint window. Omit this section only if no directional human input is worth preserving. -->

### Human Input 1
> [User's original words, verbatim]

AI Summary: [One sentence explaining what this input constrains or decides for the issue.]

### Human Input 2
> [User's original words, verbatim]

AI Summary: [One sentence explaining what this input constrains or decides for the issue.]

## 🧭 Behavioral Boundaries
<!-- Summarize the key In Scope, Out of Scope, and Behavioral Contract points from harness.md. Do not copy the full harness. -->

## 🎯 Decision Points
<!-- DECISION_POINTS: Key choices that need human judgment -->

## 📋 Problem Description
[3-5 sentences: precise description of the problem]

## 🔍 Current Behavior
| File | Line | Current Logic |
|------|------|---------------|
| [path/to/file.ts] | [Lxx-Lyy] | [What happens now] |

## ✨ Expected Behavior
[What should happen after this change — testable, specific]

## 🗺️ Impact Scope
| Module | Path | Impact |
|--------|------|--------|
| [...] | [...] | [New / Modified / Removed] |

## ⚠️ Risks & Mitigations
| Risk | Severity | Mitigation |
|------|----------|------------|
| [...] | [...] | [...] |

## ✅ Acceptance Criteria
- [ ] [Criterion — mechanically checkable]
- [ ] [...]

## 🔗 References
- Proposal: [proposal.md]
- Behavioral Source: [harness.md] or [proposal.md#Behavioral-Boundaries]
- Design: [design.md]
- Tasks: [tasks.md]
- Technical Design: [technical-design.md]
- Risks: [risks.md]
