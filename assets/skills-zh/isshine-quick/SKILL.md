---
name: isshine-quick
description: "isshine 快速模式。使用 /isshine-quick 调用。精简工作流：define → issue（跳过 design）。适用于小改动和 bug fix。"
---

# isshine Quick Mode

面向小改动的精简工作流，不需要完整技术深度设计。直接跳过 `design` 阶段。

默认使用中文与用户沟通，并生成中文产物；命令、文件名、状态字段、代码标识符保持原样。

## 适用场景

- 根因明确的 bug fix
- 小调整（文案、样式、配置更新）
- 依赖更新
- 用户明确要求 "quick" 或 "small change"

## 工作流

```text
define → issue → done
```

## 步骤

### 1. Quick Define

与 `/isshine-define` 相同，但减少仪式感：

- **更短的探索**：只读取直接受影响的文件
- **Behavioral Boundaries 写入 proposal.md**：不创建独立 `harness.md`；在 `proposal.md` 中添加简洁的 `## Behavioral Boundaries` section
- **更简单的 design.md**：只写 approach 段落，不做完整 alternatives analysis
- **更简单的 tasks.md**：平铺 checklist，不需要阶段分组

初始化状态：

```bash
bash "$ISSHINE_STATE" init <slug> quick
bash "$ISSHINE_STATE" transition <slug> init-complete
# → phase: define (quick workflow)
```

### 2. 生成最小产物

只生成必要内容：

- `proposal.md` — Problem + Goals（必需）
- `design.md` — 一段 lightweight approach
- `tasks.md` — 平铺 checklist

跳过：

- `harness.md`（quick mode 使用 `proposal.md#Behavioral Boundaries`）
- `technical-design.md`
- `risks.md`

### 3. 用户审查（阻塞点）

对所有产物做一次统一确认。

### 4. 直接推进到 Issue

```bash
bash "$ISSHINE_STATE" transition <slug> define-complete
# Quick workflow: define-complete → issue (skips design)
```

### 5. 合成并发布

与 `/isshine-issue` 相同，但：

- 使用 `proposal.md#Behavioral Boundaries` 作为行为来源
- 跳过风险提取（没有 risks.md）
- 跳过技术设计引用
- Human Consumption Layer 和 Agent Consumption Layer 仍然必需

## 退出条件

- Issue 已发布到 GitHub
- 阶段已推进到 `done`

## Quick Mode 限制

如果在 quick define 期间发现：

- 变更比预期更大
- 架构决策需要深度分析
- 多个模块受到非平凡影响

→ **升级到完整工作流**：

```bash
bash "$ISSHINE_STATE" set <slug> workflow full
```

然后先继续 `/isshine-design`，再执行 `/isshine-issue`。
