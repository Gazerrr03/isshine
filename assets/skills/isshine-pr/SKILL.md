---
name: isshine-pr
description: "isshine Phase 4: PR Comment. Invoke with /isshine-pr. Generate reviewer-friendly PR description from design artifacts."
---

# isshine Phase 4: PR Comment

Generate a reviewer-friendly PR comment by comparing design intent (from artifacts) with actual implementation. This skill is invoked when a PR is ready for review.

## Prerequisites

- `feature/<slug>/.isshine.yaml` exists with `issue_number` set
- Feature artifacts exist (at minimum: proposal.md, tasks.md)
- PR has been created on GitHub

## Steps

### 1. Locate Feature

If invoked as `/isshine-pr <slug>`, use that slug.
If invoked as `/isshine-pr` without args:
1. Check `gh pr view --json number,headRefName` for current branch
2. Search `src/index.yaml` for features matching the branch name or issue number
3. If ambiguous, ask user which feature this PR corresponds to

### 2. Load Context

```bash
ISSHINE_SCRIPTS="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
```

Read all available artifacts:
- `feature/<slug>/proposal.md`
- `feature/<slug>/design.md`
- `feature/<slug>/tasks.md`
- `feature/<slug>/technical-design.md`
- `feature/<slug>/risks.md`
- `output/<slug>/issue.md` (the published Issue)

### 3. Assess Artifact Availability

| Artifacts Available | PR Comment Quality |
|---------------------|-------------------|
| All (proposal + design + tasks + technical-design + risks) | **Full** — design intent comparison |
| proposal + design + tasks | **Standard** — approach + checklist |
| proposal + tasks only | **Light** — what + checklist |
| None | **Minimal** — pure diff summary |

If artifacts are minimal, degrade gracefully per processing strategies. Default: generate what you can, note what's missing.

### 4. Generate PR Comment

Create `output/<slug>/pr-comment.md` from template `assets/templates/output/pr-comment.md`.

#### Section: What This PR Does

Extract from proposal.md Problem + Goals. 2-4 sentences, reviewer-facing.

#### Section: Design Decisions Applied

Compare design.md/technical-design.md intent with actual implementation:

```bash
# Get the diff of changed files
git diff origin/main...HEAD --stat
```

For each design decision in design.md:
| Decision | Source | Status |
|----------|--------|--------|
| [Decision] | [design.md#section] | ✅ Implemented / ⚠️ Adjusted / ❌ Deferred |

Note any **adjustments** (implemented differently than designed) with a brief explanation why.

#### Section: Risks & Mitigations

From risks.md:

| Risk | Status | Notes |
|------|--------|-------|
| [Risk] | 🟢 Mitigated | [How it was addressed in code] |
| [Risk] | 🟡 Accepted | [Why we accepted this risk] |
| [Risk] | 🔴 Needs Attention | [What reviewer should check] |

#### Section: Verification Checklist

From tasks.md Verification section + acceptance criteria in issue.md:

```markdown
## 🔍 Verification Checklist
- [ ] [Check 1 — specific action reviewer can take]
- [ ] [Check 2]
- [ ] All tests pass (`npm test`)
- [ ] No new lint warnings
```

### 5. Post to PR

Two options (ask user):

```bash
# Option A: Update PR body
gh pr edit <pr-number> --body "$(cat output/<slug>/pr-comment.md)"

# Option B: Add as comment
gh pr comment <pr-number> --body "$(cat output/<slug>/pr-comment.md)"
```

Default: update PR body if PR has no description yet; add as comment if PR already has a description.

### 6. Confirm (Blocking Point for Full mode)

If Full mode (all artifacts available), present the PR comment preview via `AskUserQuestion`:

**Summary content:**
- Design decision alignment summary
- Risk status summary
- Verification checklist

**Options:**
- "Post to PR" — publish the comment
- "Edit first" — modify content before posting
- "Skip, I'll handle manually" — save locally only

For Standard/Light/Minimal modes, post directly (no blocking point needed).

## Exit Conditions

- PR comment generated and saved to `output/<slug>/pr-comment.md`
- (If user confirmed) PR comment posted to GitHub
- No phase transition needed (PR comment is opt-in, separate from main workflow)

## Post-PR

```
✅ PR Comment generated!

📄 output/<slug>/pr-comment.md
📋 PR: <pr-url>

The reviewer now has:
  - What this PR does (from proposal)
  - Design decisions and status (from design)
  - Risk assessment (from risks)
  - Verification checklist (from tasks)
```
