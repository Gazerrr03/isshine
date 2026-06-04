---
name: isshine-issue
description: "isshine 第 3 阶段：Issue。使用 /isshine-issue 调用。基于产物和 transcript 合成双层 GitHub Issue，运行完整性检查并发布。"
---

# isshine 第 3 阶段：Synthesize + Publish

最终阶段：从对话 transcript 中提取用户方向，组装双层 Issue（Human Consumption Layer + Agent Consumption Layer），验证完整性，并发布到 GitHub。

默认生成中文 Issue；用户原话必须保持原文，不翻译、不改写。命令、文件名、状态字段、代码标识符和 GitHub label 保持原样。

## 前置条件

- `feature/<slug>/.isshine.yaml` 存在，且 phase = `issue`
- 完整工作流的 feature 产物都存在（proposal.md、harness.md、design.md、tasks.md、technical-design.md、risks.md）
- 快速工作流可以省略 harness.md；使用 `proposal.md#Behavioral Boundaries` 作为行为来源
- `gh` CLI 已认证

## 步骤

### 0. 入口状态验证

```bash
ISSHINE_SCRIPTS="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
ISSHINE_STATE="${ISSHINE_SCRIPTS}/isshine-state.sh"
ISSHINE_CHECK="${ISSHINE_SCRIPTS}/isshine-check.sh"
ISSHINE_TRANSCRIPT="${ISSHINE_SCRIPTS}/isshine-transcript.sh"

bash "$ISSHINE_STATE" check <slug> issue
```

### 1. 运行完整性检查

```bash
bash "$ISSHINE_CHECK" <slug>
```

如果检查失败：

- 按处理策略执行：要么 **block publish**（先修复再继续），要么 **publish with warnings**（记录缺口）
- 默认行为：block，向用户展示失败项，修复后再继续

### 2. 从检查点窗口提取 Human Inputs

**这是 isshine 的关键创新。** 对话 transcript 中的用户输入通常比 AI 总结更精确。使用 feature 的检查点窗口，让 Issue 保留 define/design/issue 对齐过程中高质量的用户方向，同时避免混入无关会话。

```bash
# Close the issue-context window immediately before assembling the Issue.
START_REF=$(bash "$ISSHINE_STATE" get <slug> issue_context_start_ref)
END_REF=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
bash "$ISSHINE_STATE" set <slug> issue_context_end_ref "$END_REF"

# Locate transcript
TRANSCRIPT_PATH=$(bash "$ISSHINE_TRANSCRIPT" locate <session_ref>)

# Extract user inputs in the feature's requirement-convergence window.
# If START_REF or END_REF is unavailable, this command falls back to full transcript extraction with a warning.
bash "$ISSHINE_TRANSCRIPT" extract-window "$TRANSCRIPT_PATH" "$START_REF" "$END_REF" > /tmp/isshine-inputs-<slug>.md

# Classify as directional vs general
bash "$ISSHINE_TRANSCRIPT" classify-window "$TRANSCRIPT_PATH" "$START_REF" "$END_REF"
```

审查分类后的输入。对每条分类为 "🎯 DIRECTIONAL" 或确实高价值的 "🔍 POTENTIALLY_DIRECTIONAL" 的输入：

1. 阅读用户原话
2. 判断：这条输入是否约束范围、拒绝某个方案、设置验收标准，或表达产品/优先级/风险判断？
3. 如果是，将其 **原文逐字** 放入 `## Human Inputs`
4. 写一句 AI Summary，说明这条输入为 Issue 约束或决定了什么

**纳入标准：**

- 这句话设置了边界或方向
- 这句话表达了决策或偏好
- 这句话拒绝了某个行为或实现方向
- 这句话指定了验收标准或成功条件
- 这句话引用了原则或 anti-goals
- 如果改写会损失精确性

**过滤掉：**

- 澄清问题（"What does X do?"）
- 流程闲聊（"Let me check that..."）
- 简单确认（"OK", "Sounds good"）
- 已经完整保存在产物中，且原文不增加额外价值的输入

### 3. 组装 Issue

从模板 `assets/templates/output/issue.md` 创建 `output/<slug>/issue.md`。

#### Human Consumption Layer

```markdown
## TL;DR
[来自 proposal.md Problem section 的 1-2 句摘要。保持简短；不要把高质量用户方向压缩进 TL;DR。]

## 📖 Direction Context
> Related: [[spec/philosophy#xxx]], [[spec/anti-goals#yyy]]
> Behavioral source: [[feature/<slug>/harness.md]] or [[feature/<slug>/proposal.md#Behavioral-Boundaries]]

## Human Inputs

### Human Input 1
> [用户原话，逐字引用，来自检查点窗口 transcript 提取]

AI Summary: [一句话说明这条输入约束或决定了 Issue 的什么]

### Human Input 2
> [...]

AI Summary: [...]

## 🎯 Decision Points
- [ ] [需要人类判断的决策，来自 design.md alternatives]
- [ ] [...]

## 🧭 Behavioral Boundaries
[总结 harness.md 中关键的 In Scope、Behavioral Contract 和 Done Means。快速工作流使用 proposal.md#Behavioral Boundaries。]
```

**Human Consumption Layer 规则：**

- 用户原文 = 逐字引用，不编辑、不改写、不翻译
- AI Summary 解释约束/决策含义，不能只是复述输入
- 可以包含多个 [Human Input + AI Summary] 块
- 如果没有找到高质量输入，省略 `## Human Inputs`，并在最终审查中说明没有纳入方向性 Human Input
- Decision Points 来自 design.md alternatives 和 define 阶段对话
- Behavioral Boundaries 在完整工作流中来自 harness.md，在快速工作流中来自 proposal.md#Behavioral Boundaries
- 如果没有明确决策点，省略该 section，不要编造

#### Agent Consumption Layer

```markdown
## 📋 Problem Description
[来自 proposal.md 的 3-5 句精确描述，不要空话]

## 🔍 Current Behavior
| File | Line | Current Logic |
|------|------|---------------|
| [path] | [Lxx] | [当前逻辑，必须基于实际代码阅读] |

## ✨ Expected Behavior
[变更后应该发生什么，必须可测试、具体]

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
- [ ] [可机械验证的标准，来自 tasks.md 和 proposal.md goals]
- [ ] [...]

## 🔗 References
- Proposal: [proposal.md]
- Behavioral Source: [harness.md] or [proposal.md#Behavioral-Boundaries]
- Design: [design.md]
- Tasks: [tasks.md]
- Technical Design: [technical-design.md]
- Risks: [risks.md]
```

**Agent Consumption Layer 规则：**

- Current Behavior 必须基于 **实际代码阅读**，不能猜测
- 文件路径必须精确，行号必须具体
- Acceptance Criteria 必须 **可机械验证**（例如 "Click X → Y appears"，不要写 "UX feels good"）
- Impact table 必须列出每个会被触碰的文件
- References 必须链接到本地 artifact 文件

### 4. 选择 Label

基于 feature 和全局上下文：

**类型 label（必需）：**

| 条件 | Label |
|------|-------|
| 新功能 | `enhancement` |
| 修复破损行为 | `bug` |
| 仅文档 | `documentation` |
| UI/视觉变化 | `design` |

**辅助 label：**

- 复用现有仓库 label（`gh label list`）
- 不要发明新 label
- 如果适用，添加 `good first vibe`（信息完整到足以让 AI agent 直接执行）

### 5. 用户最终审查（阻塞点）

**必须使用 AskUserQuestion。** 这是发布前的最后检查。

展示：

- 完整渲染后的 Issue（两层都展示）
- 选定的 labels
- 完整性检查结果
- Transcript 提取摘要（找到 N 条方向性输入，纳入 M 条）

**选项：**

- "Publish Issue" — 创建 GitHub Issue
- "Edit Issue content" — 发布前修改内容
- "Save locally, don't publish" — 只保存 issue.md，不创建 GitHub Issue
- "Return to design phase" — 需要更多技术澄清

### 6. 发布到 GitHub

```bash
# Create the issue
gh issue create \
  --title "[Module] <verb phrase>" \
  --body "$(cat output/<slug>/issue.md)" \
  --label "enhancement" \
  --label "<other-labels>"
```

创建后：

```bash
bash "$ISSHINE_STATE" set <slug> issue_number "<number>"
bash "$ISSHINE_STATE" set <slug> issue_url "<url>"
```

### 7. 完成

```bash
bash "$ISSHINE_STATE" transition <slug> issue-complete
# → phase: done
```

更新 `src/index.yaml`：

```yaml
features:
  - slug: <slug>
    path: feature/<slug>/
    phase: done
    refs: [...]
```

## 退出条件

- 完整性检查通过，或用户接受 warnings
- issue.md 已创建，且两层内容完整
- Issue 已发布到 GitHub，或用户选择 local-only
- `.isshine.yaml` 已更新 issue_number 和 issue_url
- 阶段已推进到 `done`

## Issue 完成后

```text
✅ Issue Published!

📋 GitHub Issue: #<number> — <url>
📁 feature/<slug>/     — Full design context preserved
📄 output/<slug>/issue.md — Issue content (for PR comment generation)

When you create a PR for this issue, run /isshine-pr to generate
a reviewer-friendly PR comment from the design artifacts.
```
