---
name: isshine
description: "isshine 主入口。使用 /isshine 调用。检测当前阶段并分发到子 skill，将对话生成 AI 友好、人类可读的 GitHub Issue。"
---

# isshine — 需求灵光

把对话生成 AI 友好、人类可读的 GitHub Issue。一个对话对应一个 Issue。

默认使用中文与用户沟通，并生成中文说明、Issue 内容和 PR 说明；除非用户明确要求英文或目标仓库已有强英文规范。命令、文件名、状态字段、代码标识符和 GitHub label 保持原样。

## 前置条件

- 当前位于 git 仓库中
- `gh` CLI 已认证（`gh auth status`）
- 首次使用时，先运行 `/isshine-init` 建立项目级 `spec/` 和处理策略

## 分发逻辑

当用户调用 `/isshine` 时，判断当前状态并分发：

### 优先级决策表

| # | 条件 | 动作 |
|---|------|------|
| 1 | `spec/` 目录不存在 | 先调用 `/isshine-init` |
| 2 | `feature/<slug>/.isshine.yaml` 存在，且 phase != done | 从当前阶段恢复（调用对应子 skill） |
| 3 | 没有活跃 feature，或用户想创建新 feature | 创建新 feature，调用 `/isshine-define` |
| 4 | 用户提到 "quick"、"small" 或 "fix" | 调用 `/isshine-quick` |
| 5 | Feature phase = done，且用户想生成 PR comment | 调用 `/isshine-pr` |

### 阶段到子 skill 映射

| .isshine.yaml phase | 子 skill |
|---------------------|----------|
| `init` | `/isshine-init` |
| `define` | `/isshine-define` |
| `design` | `/isshine-design` |
| `issue` | `/isshine-issue` |
| `done` | 报告完成，并建议用 `/isshine-pr` 生成 PR comment |

### 恢复流程

当 `.isshine.yaml` 存在且 phase 不是 `done`：

1. 读取 `.isshine.yaml` 理解当前状态
2. 检查哪些产物已经存在且非空
3. 从当前阶段第一个未完成步骤继续
4. 不要重复已完成的工作

### 直接调用

用户也可以直接调用子 skill：

- `/isshine-init` — 重新执行项目初始化
- `/isshine-define` — 开始新的需求定义
- `/isshine-design` — 基于已有产物执行技术深度设计
- `/isshine-issue` — 基于已有产物重新合成 Issue
- `/isshine-pr` — 基于产物生成 PR comment
- `/isshine-quick` — 快速模式：define → issue（跳过 design）

## 全局上下文加载

分发前必须：

1. 读取 `src/index.yaml`，理解可用 spec 和活跃 feature
2. 将引用到的 `spec/` 文件加载进上下文
3. 应用 init 阶段定义的处理策略

## 脚本设置

```bash
ISSHINE_ROOT="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
if [ -z "$ISSHINE_ROOT" ]; then
  echo "ERROR: isshine scripts not found. Ensure the isshine skill is installed." >&2
  return 1
fi
ISSHINE_STATE="${ISSHINE_ROOT}/isshine-state.sh"
ISSHINE_CHECK="${ISSHINE_ROOT}/isshine-check.sh"
ISSHINE_TRANSCRIPT="${ISSHINE_ROOT}/isshine-transcript.sh"
```

## 分发后

子 skill 完成后，如果阶段向前推进，报告进度：

```text
✅ Phase: [old] → [new]
📁 feature/<slug>/
🔗 Next: /isshine-<next-phase>
```
