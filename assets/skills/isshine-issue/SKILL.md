---
name: isshine-issue
description: "isshine Phase 3: Issue. Invoke with /isshine-issue. Synthesize dual-layer GitHub Issue from artifacts + transcript, run completeness check, publish."
---

# isshine Phase 3: Synthesize + Publish

The culmination: extract user direction from the conversation transcript, assemble the dual-layer Issue (Human Consumption Layer + Agent Consumption Layer), validate completeness, and publish to GitHub.

## Prerequisites

- `feature/<slug>/.isshine.yaml` exists with phase = `issue`
- All feature artifacts exist (proposal.md, design.md, tasks.md, technical-design.md, risks.md)
- `gh` CLI authenticated

## Steps

### 0. Entry State Verification

```bash
ISSHINE_SCRIPTS="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
ISSHINE_STATE="${ISSHINE_SCRIPTS}/isshine-state.sh"
ISSHINE_CHECK="${ISSHINE_SCRIPTS}/isshine-check.sh"
ISSHINE_TRANSCRIPT="${ISSHINE_SCRIPTS}/isshine-transcript.sh"

bash "$ISSHINE_STATE" check <slug> issue
```

### 1. Run Completeness Check

```bash
bash "$ISSHINE_CHECK" <slug>
```

If the check fails:
- Per processing strategies: either **block publish** (fix before proceeding) or **publish with warnings** (document gaps)
- Default behavior: block — present failures to user, fix before continuing

### 2. Extract Human Direction from Transcript

**This is the key innovation of isshine.** The conversation transcript contains user inputs that are more precise than any AI summary could be.

```bash
# Locate transcript
TRANSCRIPT_PATH=$(bash "$ISSHINE_TRANSCRIPT" locate <session_ref>)

# Extract user inputs
bash "$ISSHINE_TRANSCRIPT" extract "$TRANSCRIPT_PATH" > /tmp/isshine-inputs-<slug>.md

# Classify as directional vs general
bash "$ISSHINE_TRANSCRIPT" classify "$TRANSCRIPT_PATH"
```

Review the classified inputs. For each input classified as "🎯 DIRECTIONAL":
1. Read the original user words
2. Assess: is this a direction-setting statement?
3. If yes → include in the Issue's Human Consumption Layer **verbatim**
4. Write a 1-2 sentence AI summary for context

**Quality criteria for inclusion:**
- The statement sets a boundary or direction
- The statement expresses a decision or preference
- The statement references principles or anti-goals
- The statement would lose precision if paraphrased

**Filter out:**
- Clarification questions ("What does X do?")
- Procedural chat ("Let me check that...")
- Simple acknowledgments ("OK", "Sounds good")

### 3. Assemble the Issue

Create `output/<slug>/issue.md` from template `assets/templates/output/issue.md`.

#### Human Consumption Layer

```
## TL;DR
[1-2 sentences from proposal.md Problem section]

## 📖 Direction Context
> Related: [[spec/philosophy#xxx]], [[spec/anti-goals#yyy]]

### 💬 Direction Input 1
> **原文**: [User's exact words, verbatim — from transcript extraction]
>
> *AI Summary*: [1-2 sentence summary of what this direction means]

### 💬 Direction Input 2
> **原文**: [...]
>
> *AI Summary*: [...]

## 🎯 Decision Points
- [ ] [Decision that needs human judgment — from design.md alternatives]
- [ ] [...]
```

**Rules for Human Consumption Layer:**
- User original text = verbatim, no editing, no paraphrasing
- AI summary = brief index for scanning
- Multiple [原文 + AI summary] blocks allowed
- Decision Points extracted from design.md alternatives and define-phase dialogue
- If no clear decision points exist, omit the section (do not fabricate)

#### Agent Consumption Layer

```
## 📋 Problem Description
[3-5 sentences from proposal.md — precise, no fluff]

## 🔍 Current Behavior
| File | Line | Current Logic |
|------|------|---------------|
| [path] | [Lxx] | [what happens now — based on actual code reading] |

## ✨ Expected Behavior
[What should happen — testable, specific]

## 🗺️ Impact Scope
| Module | Path | Impact |
|--------|------|--------|
| [...] | [...] | [New / Modified / Removed] |

## ⚠️ Risks & Mitigations
| Risk | Severity | Mitigation |
|------|----------|------------|
| [Top risk from risks.md] | [...] | [...] |
| [Second risk] | [...] | [...] |

## ✅ Acceptance Criteria
- [ ] [Mechanically checkable criterion — from tasks.md and proposal.md goals]
- [ ] [...]

## 🔗 References
- Proposal: [proposal.md]
- Design: [design.md]
- Tasks: [tasks.md]
- Technical Design: [technical-design.md]
- Risks: [risks.md]
```

**Rules for Agent Consumption Layer:**
- Current Behavior must be based on **actual code reading**, not guessing
- File paths must be exact, line numbers specific
- Acceptance Criteria must be **mechanically checkable** ("Click X → Y appears", NOT "UX feels good")
- Impact table must list every file that will be touched
- References must link to local artifact files

### 4. Label Selection

Based on the feature and global context:

**Type labels (required):**
| Condition | Label |
|-----------|-------|
| New functionality | `enhancement` |
| Fixing broken behavior | `bug` |
| Documentation only | `documentation` |
| UI/visual change | `design` |

**Auxiliary labels:**
- Reuse existing repo labels (`gh label list`)
- Do NOT invent new labels
- If applicable, add `good first vibe` (information is complete enough for an AI agent to execute directly)

### 5. User Final Review (Blocking Point)

**Must use AskUserQuestion.** This is the final check before publishing.

Present:
- Complete rendered Issue (both layers)
- Selected labels
- Completeness check results
- Transcript extraction summary (N directional inputs found, M included)

**Options:**
- "Publish Issue" — create on GitHub
- "Edit Issue content" — modify before publishing
- "Save locally, don't publish" — save issue.md but don't create GitHub Issue
- "Return to design phase" — need more technical clarity

### 6. Publish to GitHub

```bash
# Create the issue
gh issue create \
  --title "[Module] <verb phrase>" \
  --body "$(cat output/<slug>/issue.md)" \
  --label "enhancement" \
  --label "<other-labels>"
```

After creation:
```bash
bash "$ISSHINE_STATE" set <slug> issue_number "<number>"
bash "$ISSHINE_STATE" set <slug> issue_url "<url>"
```

### 7. Finalize

```bash
bash "$ISSHINE_STATE" transition <slug> issue-complete
# → phase: done
```

Update `src/index.yaml`:
```yaml
features:
  - slug: <slug>
    path: feature/<slug>/
    phase: done
    refs: [...]
```

## Exit Conditions

- Completeness check passes (or user accepts warnings)
- issue.md created with both layers complete
- Issue published to GitHub (or user chose local-only)
- `.isshine.yaml` updated with issue_number and issue_url
- Phase transitioned to `done`

## Post-Issue

```
✅ Issue Published!

📋 GitHub Issue: #<number> — <url>
📁 feature/<slug>/     — Full design context preserved
📄 output/<slug>/issue.md — Issue content (for PR comment generation)

When you create a PR for this issue, run /isshine-pr to generate
a reviewer-friendly PR comment from the design artifacts.
```
