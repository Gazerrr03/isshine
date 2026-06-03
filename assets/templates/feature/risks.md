# Risks: [Feature Name]

## Document Contract

| Field | Value |
|-------|-------|
| Scope | Feature |
| Primary Consumer | Human reviewer |
| Secondary Consumer | AI coding agent |
| Stability | Review-level; update when risks or mitigations change |
| Owns | Concrete failure modes, mitigations, triggers, and fallback paths |
| Should Not Contain | Generic concerns, implementation tasks, or unrelated product rationale |

> **Spec**:
> - Must list at least 2 risks
> - Each risk must have: description, severity, likelihood, mitigation, trigger

## Risk Matrix

### Risk 1: [Short Name]
- **Description**: [What could go wrong?]
- **Severity**: [Critical / High / Medium / Low]
- **Likelihood**: [High / Medium / Low]
- **Mitigation**: [What are we doing to prevent or reduce this?]
- **Trigger**: [What early signal indicates this risk is materializing?]
- **Fallback**: [If this risk materializes, what do we do?]

### Risk 2: [Short Name]
- **Description**: [...]
- **Severity**: [...]
- **Likelihood**: [...]
- **Mitigation**: [...]
- **Trigger**: [...]
- **Fallback**: [...]

## Risk Dependencies
[Do any risks compound each other? If Risk 1 happens, does Risk 2 become more likely?]
