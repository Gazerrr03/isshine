# PR Comment: [Feature Name]

## Document Contract

| Field | Value |
|-------|-------|
| Scope | Output |
| Primary Consumer | Pull request reviewer |
| Secondary Consumer | AI coding agent |
| Stability | PR-level; update when implementation or verification changes |
| Owns | Reviewer-facing implementation summary, design alignment, risks, and verification checklist |
| Should Not Contain | Full source docs, unrelated work, or unverified claims |

> **Spec**:
> - `## What This PR Does` — must be non-empty
> - `## Design Decisions` — must reference design.md
> - `## Verification Checklist` — must list at least 1 checkable item

## What This PR Does
[2-4 sentences summarizing the changes from the reviewer's perspective]

## Design Decisions Applied
| Decision | Source | Implemented As |
|----------|--------|----------------|
| [Decision from design.md] | [design.md#section] | [How it was implemented — or "Deferred" / "Adjusted"] |

## Risks & Mitigations Addressed
| Risk | Status | Notes |
|------|--------|-------|
| [Risk from risks.md] | [Mitigated / Accepted / Not Triggered] | [...] |

## Verification Checklist
- [ ] [Specific check for reviewer]
- [ ] [...]

## Related
- Issue: #[...]
- Harness: [harness.md]
- Design: [design.md]
- Tasks: [tasks.md]

---
🤖 Generated with [isshine](https://github.com/rpamis/isshine)
