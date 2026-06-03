# Tech Constraints

## Document Contract

| Field | Value |
|-------|-------|
| Scope | Global |
| Primary Consumer | AI coding agent |
| Secondary Consumer | Human reviewer |
| Stability | Technology-level; update when stack or hard requirements change |
| Owns | Allowed technologies, forbidden patterns, and measurable requirements |
| Should Not Contain | Feature-local tradeoffs or unrelated product philosophy |

> **Spec**: Must list at least one concrete technology choice or constraint. Each entry must specify what is allowed, what is forbidden, and why.

## Technology Stack

| Layer | Choice | Constraint |
|-------|--------|------------|
| [Frontend / Backend / Database / etc.] | [Technology name] | [Version range, or specific limitation] |

## Forbidden Patterns

### Pattern: [Name]
- **What**: [Describe the forbidden approach]
- **Why**: [Why is it forbidden? Performance? Maintainability? Security?]
- **Exception**: [If any exception exists, state it clearly. Otherwise: "None."]

## Performance Requirements

- [ ] [Specific measurable requirement, e.g., "Page load < 2s on 3G"]
- [ ] [Add more]

## Security Requirements

- [ ] [Specific security requirement, e.g., "All user input must be sanitized"]
- [ ] [Add more]
