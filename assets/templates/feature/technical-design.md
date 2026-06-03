# Technical Design: [Feature Name]

## Document Contract

| Field | Value |
|-------|-------|
| Scope | Feature |
| Primary Consumer | AI coding agent |
| Secondary Consumer | Human reviewer |
| Stability | Technical design-level; update when interfaces, data flow, or edge cases change |
| Owns | Data flow, interfaces, state changes, edge cases, and technical implications |
| Should Not Contain | Product philosophy, high-level persuasion, or implementation task sequencing |

> **Spec**:
> - `## Data Flow` — must describe how data moves through the system
> - `## Interfaces` — must list at least 1 interface/API contract
> - `## Edge Cases` — must list at least 2 edge cases

## Data Flow
[Describe how data flows through the system for this feature. Include diagrams in text if helpful.]

## Interfaces

### [Interface Name]
- **Type**: [REST endpoint / Function signature / Event / Database schema]
- **Contract**:
```
[Code or schema definition]
```
- **Error Handling**: [What errors can occur, how are they handled?]

## State Changes
[What state does this feature introduce or modify?]

## Edge Cases
| Case | Expected Behavior | Handling Strategy |
|------|-------------------|-------------------|
| [Edge case 1] | [What should happen] | [How we handle it] |
| [Edge case 2] | [What should happen] | [How we handle it] |

## Performance Considerations
- [Any performance implications]
