# Harness: [Feature Name]

## Document Contract

| Field | Value |
|-------|-------|
| Scope | Feature |
| Primary Consumer | AI coding agent |
| Secondary Consumer | Human decision-maker |
| Stability | Requirement iteration-level; update when behavior, allowed scope, or forbidden scope changes |
| Owns | Behavioral boundaries and feature-level success conditions |
| Should Not Contain | Low-level technical design, implementation tasks, or risk matrix details |

> **Spec**:
> - `## What It Is` — must define the feature in 2-4 sentences
> - `## In Scope` — must list what behavior is explicitly allowed
> - `## Behavioral Contract` — must define at least 3 concrete rules
> - `## Done Means` — must list checkable success conditions

## What It Is
[Describe what this feature is from the user's and product's point of view. Keep this behavioral, not technical.]

## Why It Exists
[Explain why this feature should exist and what product or workflow gap it closes.]

## In Scope
- [Behavior or capability this feature must support]
- [...]

## Out of Scope
- [Behavior or adjacent problem this feature must not take on]
- [...]

## Behavioral Contract
- [Rule the implementation must preserve]
- [Boundary that prevents over-expansion]
- [Expected behavior in an important case]

## Done Means
- [Checkable condition showing the feature behaves correctly]
- [Success condition visible to a user, maintainer, or agent]

## Dependencies
- [Spec, system, or feature dependency]
- [...]
