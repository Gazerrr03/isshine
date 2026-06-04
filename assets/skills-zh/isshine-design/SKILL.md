---
name: isshine-design
description: "isshine 第 2 阶段：Design。使用 /isshine-design 调用。技术深度设计：生成 technical-design 文档，识别风险与缓解方案。"
---

# isshine 第 2 阶段：Deep Design

技术深度设计：基于 proposal.md、harness.md 和 design.md 中的高层方向，产出详细技术规格、边界情况分析和风险识别。

默认使用中文与用户沟通，并生成中文技术设计与风险文档；命令、文件名、状态字段、代码标识符保持原样。

## 前置条件

- `feature/<slug>/.isshine.yaml` 存在，且 phase = `design`
- proposal.md、harness.md、design.md、tasks.md 存在且非空

## 步骤

### 0. 入口状态验证

```bash
ISSHINE_SCRIPTS="$(find . "$HOME"/.*/skills "$HOME/.config" -path '*/isshine/scripts' -type d -print -quit 2>/dev/null)"
ISSHINE_STATE="${ISSHINE_SCRIPTS}/isshine-state.sh"

bash "$ISSHINE_STATE" check <slug> design
```

验证通过后才能继续。

### 1. 加载上下文

读取所有已有产物：

- `spec/` — 全局约束和项目哲学
- `feature/<slug>/proposal.md` — 问题、目标、范围
- `feature/<slug>/harness.md` — 行为约束
- `feature/<slug>/design.md` — 高层方案
- `feature/<slug>/tasks.md` — 实施计划
- `spec/.processing-strategies.md` — 阶段约定

### 2. 进入 Plan Mode

**必须使用 Plan Mode** 做深度设计（遵守处理策略）。设计阶段需要思考空间来推理：

- 架构模式和权衡
- 边界情况和失败模式
- 风险面和缓解策略

如果用户在本阶段给出高质量技术约束，将其保留为最终 Issue 的候选 Human Input。好的候选通常会拒绝某个技术方向、约束依赖、设置不可协商行为，或明确风险容忍度。

### 3. 生成 Technical Design

从模板 `assets/templates/feature/technical-design.md` 创建 `feature/<slug>/technical-design.md`。

将 `harness.md` 视为硬性行为约束。如果某个技术选择与 harness 冲突，必须标记冲突，不要静默推进。

关键部分：

#### Data Flow

追踪数据如何流经系统：

- Input → Processing → Output
- 会发生哪些状态变化？
- 涉及哪些外部系统？

#### Interfaces

定义每个接口/API contract：

- 函数签名
- REST endpoint
- 数据库 schema 变化
- 事件/消息格式
- 每个接口的错误处理

#### Edge Cases

至少列出 3 个边界情况：

- 空输入 / null / undefined
- 并发访问 / race condition
- 网络失败 / timeout
- 鉴权失败
- 限流 / throttling
- 数据量极端情况

每个边界情况都要给出预期行为和处理策略。

#### Performance Considerations

- 是否存在 N+1 查询？
- 是否有内存压力点？
- 是否有阻塞操作？

### 4. 识别风险

从模板 `assets/templates/feature/risks.md` 创建 `feature/<slug>/risks.md`。

必须至少识别 **3 个风险**（或遵守处理策略中的最小数量）。

风险识别方式：

1. **Security scan**：攻击者可能利用什么？
2. **Dependency scan**：哪些上游失败会级联？
3. **Data scan**：哪些数据可能丢失或损坏？
4. **UX scan**：哪些用户流程可能被破坏？
5. **Performance scan**：什么在负载下会变慢？

每个风险必须包含：

- **Description**：具体场景，不是抽象担忧
- **Severity**：Critical / High / Medium / Low
- **Likelihood**：High / Medium / Low
- **Mitigation**：现在采取什么措施预防
- **Trigger**：早期预警信号
- **Fallback**：风险发生后怎么处理

### 5. 交叉引用检查

验证产物之间是否一致：

- technical-design.md 是否实现了 design.md 中的方案？如果偏离，说明原因。
- technical-design.md 是否保持 harness.md 承诺的行为？
- technical-design.md 是否避免了 harness.md 明确排除的行为？
- risks.md 是否覆盖了 technical-design.md 中的边界情况？
- 基于技术设计，tasks.md 是否缺少任务？

将不一致之处提示给用户。

### 6. 运行完整性检查

```bash
bash "$ISSHINE_CHECK" <slug>
```

审查结果。如果检查失败：

- 填补缺失章节
- 替换占位内容
- 重新运行检查

### 7. 用户审查与确认（阻塞点）

**必须使用 AskUserQuestion。** 展示：

**摘要内容：**

- **Technical Design**：架构方向、关键接口、关键边界情况
- **Risks**：按严重度排序的 Top 3 风险及缓解摘要
- **Completeness**：检查结果（X/Y 通过）
- **Cross-Reference**：发现的不一致

**选项：**

- "Confirm, proceed to next phase"
- "Adjust technical design" — 修改 technical-design.md
- "Adjust risks" — 修改 risks.md
- "Return to define phase" — 需求需要进一步明确

### 8. 回退到 Define

如果用户或模型判断 design.md 不足以支撑深度技术设计：

1. 告知用户："The high-level design needs more clarity before deep design can proceed."
2. 运行 `bash "$ISSHINE_STATE" set <slug> phase define` 回退
3. 调用 `/isshine-define` 重新执行 define 阶段

## 退出条件

- technical-design.md 已创建，且所有 Spec section 已填写
- risks.md 已创建，且风险数量达到最小要求
- 完整性检查通过
- 用户已确认
- 运行 `bash "$ISSHINE_STATE" transition <slug> design-complete`，推进到 `issue`

## Design 完成后

```text
✅ Phase: design → issue
📁 feature/<slug>/
   ├── proposal.md
   ├── design.md
   ├── tasks.md
   ├── technical-design.md  — Deep design
   └── risks.md              — Risk matrix

🔗 Next: /isshine-issue (auto-transitioning...)
```

**立即调用 `/isshine-issue`** 来合成并发布 Issue。
