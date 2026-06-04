---
name: isshine-define
description: "isshine 第 1 阶段：Define。使用 /isshine-define 调用。需求定义：读取 spec、探索代码、进入 Plan Mode 对话，并生成 proposal/harness/design/tasks。"
---

# isshine 第 1 阶段：Define

定义需求：读取全局上下文，探索相关代码，进入 Plan Mode 进行人机对齐，并生成四个基础产物，包括行为约束 harness。

默认使用中文与用户沟通，并生成中文需求产物；命令、文件名、状态字段、代码标识符保持原样。

## 前置条件

- `spec/` 目录存在（先运行 `/isshine-init`）
- `src/index.yaml` 存在
- 满足其一：没有活跃 feature，或 `.isshine.yaml` phase = `define`

## 步骤

### 0. 加载全局上下文

**必须先执行。** 读取项目上下文：

1. 读取 `src/index.yaml` 获取路由信息
2. 读取 `spec/.project-context.md` 获取检查点和策略摘要
3. 读取 `spec/.processing-strategies.md` 获取阶段约定
4. 读取所有启用的 `spec/*.md` 文件（philosophy、anti-goals、tech-constraints 等）

### 1. 理解需求

与用户对话，理解：

- **What**：要做什么（feature、fix 或 change）
- **Why**：为什么现在要做（紧急性或背景）
- **Where**：代码库中哪里会受影响（模块、文件、系统）

根据处理策略进入 Plan Mode。Plan Mode 为模型推理需求提供思考空间。

### 2. 探索相关上下文

按任务复杂度收集上下文：

**总是执行：**

- `git log --oneline -10` — 最近变更
- `gh issue list --limit 10` — 相关 Issue
- `gh pr list --limit 5` — 可能冲突的进行中 PR

**按范围决定：**

| 复杂度 | 探索深度 |
|--------|----------|
| 简单（bug fix、小改动） | 读取用户提到的 1-2 个文件 |
| 中等（feature、refactor） | 读取受影响文件 + 一层依赖 |
| 复杂（新模块、架构变更） | 完整追踪：文件、依赖、测试、配置 |

遵守处理策略中的代码探索深度限制。

### 3. 生成 Feature Slug

为 feature 创建简短、描述性的 slug：

- 小写，空格用连字符
- 示例：`search-function`、`fix-login-timeout`、`user-auth-refactor`
- 如果自动生成的 slug 不确定，向用户确认

### 4. 初始化 Feature 目录

```bash
# Locate isshine scripts
ISSHINE_SCRIPTS="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
ISSHINE_STATE="${ISSHINE_SCRIPTS}/isshine-state.sh"

# Initialize state
bash "$ISSHINE_STATE" init <slug> full

# Set session reference (current conversation)
bash "$ISSHINE_STATE" set <slug> session_ref "<current-session-id>"
```

`init` 会自动在 `.isshine.yaml` 中记录 `issue_context_start_ref`。这个检查点标记 feature 的需求收敛窗口起点，后续用于提取 Human Inputs。

创建的目录：

```text
feature/<slug>/
└── .isshine.yaml    # phase: init
```

然后推进阶段：

```bash
bash "$ISSHINE_STATE" transition <slug> init-complete
# → phase: define
```

### 5. 需求定义对话（Plan Mode）

**这是 Define 阶段的核心。** 进入 Plan Mode，并与用户对齐：

1. **问题边界**：问题到底是什么？什么不是这个问题？
2. **成功标准**：如何判断完成？
3. **范围**：会改哪些文件/模块？哪些明确不做？
4. **约束**：适用哪些技术约束？不能违反哪些 anti-goals？
5. **方案方向**：高层架构方向（用于 design.md）

对话过程中：

- 在相关时引用 `spec/` 原则
- 当用户给出高质量、定方向的表述时，将其保留为最终 Issue 的候选 Human Input。好的候选通常会定义范围、拒绝某个方案、设置验收标准，或表达产品/优先级/风险判断。
- 范围不清时提出澄清问题
- 不要跳到实现细节，细节属于第 2 阶段（design）

### 6. 生成产物

基于对话，在 `feature/<slug>/` 中生成四个文件：

#### proposal.md

使用模板：`assets/templates/feature/proposal.md`

要填写的关键部分：

- **Problem**：来自对话，说明问题和为什么现在做
- **Goals**：具体、可衡量的结果
- **Scope**：In scope + Out of scope
- **Related**：链接已有 Issue/PR

#### harness.md

使用模板：`assets/templates/feature/harness.md`

要填写的关键部分：

- **What It Is**：feature 的行为定义，不是实现计划
- **In Scope / Out of Scope**：必须支持什么、不能承担什么
- **Behavioral Contract**：后续阶段必须保持的具体规则
- **Done Means**：可检查的 feature 级成功条件

#### design.md

使用模板：`assets/templates/feature/design.md`

要填写的关键部分：

- **Approach**：选定的高层方向（不是详细实现）
- **Harness Alignment**：方案必须保持 `harness.md`
- **Alternatives Considered**：讨论过什么替代方案，为什么拒绝
- **Architecture Impact**：哪些模块/文件会受影响
- **Dependencies**：需要的新库、服务或上游变化

#### tasks.md

使用模板：`assets/templates/feature/tasks.md`

关键规则：

- 任务必须按依赖顺序排列（前面的任务解锁后面的任务）
- 每个任务都是一个可验证的工作单元
- 将任务分组为阶段（Foundation → Core Logic → Integration & Polish）
- 每个任务都必须使用 checkbox：`- [ ]`

### 7. 更新路由

将 feature 添加到 `src/index.yaml`：

```yaml
features:
  - slug: <slug>
    path: feature/<slug>/
    phase: define
    refs:
      - spec/philosophy.md#<relevant-section>
      - spec/anti-goals.md#<relevant-section>
```

### 8. 用户审查与确认（阻塞点）

**必须使用 AskUserQuestion 暂停。** 展示摘要：

**摘要内容：**

- **proposal.md**：Problem、goals、scope 摘要（每项 2-3 句）
- **harness.md**：行为边界、feature 规则和完成信号
- **design.md**：方案摘要、关键架构决策
- **tasks.md**：任务数量、阶段拆分

**选项：**

- "Confirm, proceed to next phase" — 产物符合预期
- "Needs adjustment" — 修改后重新展示

用户确认后，进入退出条件。

## 退出条件

- proposal.md、harness.md、design.md、tasks.md 都已创建且非空
- `src/index.yaml` 已更新 feature 路由
- 用户已确认产物
- **阶段保护**：运行 `bash "$ISSHINE_STATE" check <slug> define`，确认 phase 为 `define`
- 运行 `bash "$ISSHINE_STATE" transition <slug> define-complete`，推进到 `design`

## Define 完成后

```text
✅ Phase: define → design
📁 feature/<slug>/
   ├── proposal.md    — Why + What
   ├── harness.md     — Behavioral boundaries
   ├── design.md      — How (high-level)
   └── tasks.md       — Implementation checklist

🔗 Next: /isshine-design (auto-transitioning...)
```

**立即调用 `/isshine-design`** 继续工作流。
