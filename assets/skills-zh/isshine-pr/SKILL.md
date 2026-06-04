---
name: isshine-pr
description: "isshine 第 4 阶段：PR Comment。使用 /isshine-pr 调用。基于设计产物生成 reviewer-friendly 的 PR description。"
---

# isshine 第 4 阶段：PR Comment

通过比较设计意图（来自 artifacts）和实际实现，生成便于 reviewer 审查的 PR comment。该 skill 在 PR 准备好审查时调用。

默认生成中文 PR 说明；命令、文件名、状态字段、代码标识符和 GitHub label 保持原样。

## 前置条件

- `feature/<slug>/.isshine.yaml` 存在，且已设置 `issue_number`
- Feature artifacts 存在（至少 proposal.md、tasks.md）
- PR 已在 GitHub 创建

## 步骤

### 1. 定位 Feature

如果以 `/isshine-pr <slug>` 调用，使用该 slug。

如果以 `/isshine-pr` 且无参数调用：

1. 检查 `gh pr view --json number,headRefName` 获取当前分支
2. 在 `src/index.yaml` 中搜索与分支名或 issue number 匹配的 feature
3. 如果存在歧义，询问用户该 PR 对应哪个 feature

### 2. 加载上下文

```bash
ISSHINE_SCRIPTS="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
```

读取所有可用产物：

- `feature/<slug>/proposal.md`
- `feature/<slug>/design.md`
- `feature/<slug>/tasks.md`
- `feature/<slug>/technical-design.md`
- `feature/<slug>/risks.md`
- `output/<slug>/issue.md`（已发布的 Issue）

### 3. 评估产物可用性

| 可用产物 | PR Comment 质量 |
|----------|----------------|
| 全部（proposal + design + tasks + technical-design + risks） | **Full**：设计意图对比 |
| proposal + design + tasks | **Standard**：方案 + checklist |
| 只有 proposal + tasks | **Light**：what + checklist |
| 无 | **Minimal**：纯 diff summary |

如果产物很少，按处理策略降级。默认：能生成多少就生成多少，并说明缺失项。

### 4. 生成 PR Comment

从模板 `assets/templates/output/pr-comment.md` 创建 `output/<slug>/pr-comment.md`。

#### Section: What This PR Does

从 proposal.md 的 Problem + Goals 中提取。写 2-4 句，面向 reviewer。

#### Section: Design Decisions Applied

比较 design.md/technical-design.md 的设计意图和实际实现：

```bash
# Get the diff of changed files
git diff origin/main...HEAD --stat
```

对 design.md 中每个设计决策：

| Decision | Source | Status |
|----------|--------|--------|
| [Decision] | [design.md#section] | ✅ Implemented / ⚠️ Adjusted / ❌ Deferred |

如果有 **adjustments**（实现方式与设计不同），简要说明原因。

#### Section: Risks & Mitigations

来自 risks.md：

| Risk | Status | Notes |
|------|--------|-------|
| [Risk] | 🟢 Mitigated | [代码中如何处理] |
| [Risk] | 🟡 Accepted | [为什么接受该风险] |
| [Risk] | 🔴 Needs Attention | [reviewer 应重点检查什么] |

#### Section: Verification Checklist

来自 tasks.md 的 Verification section + issue.md 的 acceptance criteria：

```markdown
## 🔍 Verification Checklist
- [ ] [Check 1 — reviewer 可以执行的具体动作]
- [ ] [Check 2]
- [ ] All tests pass (`npm test`)
- [ ] No new lint warnings
```

### 5. 发布到 PR

两个选项（询问用户）：

```bash
# Option A: Update PR body
gh pr edit <pr-number> --body "$(cat output/<slug>/pr-comment.md)"

# Option B: Add as comment
gh pr comment <pr-number> --body "$(cat output/<slug>/pr-comment.md)"
```

默认：如果 PR body 为空，更新 PR body；如果已有描述，则添加 comment。

### 6. 确认（Full mode 的阻塞点）

如果是 Full mode（所有 artifacts 都可用），通过 `AskUserQuestion` 展示 PR comment preview：

**摘要内容：**

- 设计决策对齐摘要
- 风险状态摘要
- 验证 checklist

**选项：**

- "Post to PR" — 发布 comment
- "Edit first" — 先修改内容
- "Skip, I'll handle manually" — 只保存本地

Standard/Light/Minimal 模式可以直接发布（不需要阻塞点）。

## 退出条件

- PR comment 已生成并保存到 `output/<slug>/pr-comment.md`
- 如果用户确认，PR comment 已发布到 GitHub
- 不需要阶段转换（PR comment 是 opt-in，独立于主工作流）

## PR 完成后

```text
✅ PR Comment generated!

📄 output/<slug>/pr-comment.md
📋 PR: <pr-url>

The reviewer now has:
  - What this PR does (from proposal)
  - Design decisions and status (from design)
  - Risk assessment (from risks)
  - Verification checklist (from tasks)
```
