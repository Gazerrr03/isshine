# Architecture Constraints

> **Spec**: Optional template. If activated, must contain at least one architecture rule or boundary.

## Module Boundaries

### [Module Name]
- **Responsibility**: [What this module owns]
- **Depends On**: [What it can use]
- **Must NOT Depend On**: [What it cannot use]
- **Public API**: [How other modules interact with it]

## Data Flow Rules

### [Rule Name]
- **Direction**: [Which way does data flow?]
- **Constraint**: [What restriction applies?]
- **Reason**: [Why this rule exists?]

## Integration Points

### [Integration Name]
- **Protocol**: [REST / GraphQL / gRPC / Event / etc.]
- **Contract**: [Where is the contract defined?]
- **Breaking Change Policy**: [What happens when the contract changes?]
