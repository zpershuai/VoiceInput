## Context

VoiceInput 当前已经具备 `README.md` 和 `docs/` 目录，但两者的内容边界不稳定，且文档深度与当前代码实现不完全对齐。现有材料已经覆盖产品介绍、模块概览和部分故障排除，但缺少三类对维护者最关键的信息：

1. 真实的运行链路：从应用启动、权限校验、快捷键事件、录音识别、LLM 处理到文本注入的完整控制流。
2. 真实的数据流：音频、识别文本、配置、日志和系统事件分别从哪里来、在哪里被转换、最终影响哪个模块。
3. 真实的排障路径：当 “不能监听”“不能录音”“不能识别”“不能注入”“不能润色” 时，应优先看哪个模块、哪个权限、哪类日志。

这次变更是一个跨 README、`docs/` 和源码结构认知方式的系统性升级。它本质上不是“补几篇文档”，而是为整个项目建立一套长期可维护的文档信息架构，让新维护者可以沿着统一路径理解系统、修改功能并定位问题。

## Goals / Non-Goals

**Goals:**

- 建立清晰的文档分层，让 `README.md` 负责入口与导航，`docs/` 负责深度说明与维护参考。
- 用源码事实重建 VoiceInput 的主工作流、数据流、模块关系和关键状态。
- 建立基于日志模块、权限检查和系统集成点的排障文档，使问题定位有固定入口。
- 为后续文档演进设立规则，要求新增或变更功能时同步更新对应文档区域。

**Non-Goals:**

- 不在本次设计阶段引入新的自动化文档生成工具或外部文档站点。
- 不要求在本次变更中重构生产代码架构，仅围绕文档结构和内容升级展开。
- 不为每个 Swift 文件都生成逐行 API 手册，重点放在维护价值更高的系统级与模块级说明。

## Decisions

### 1. 采用“入口 + 地图 + 机制 + 操作”四层文档结构

`README.md` 作为入口，只保留项目简介、快速开始、核心能力、核心工作流摘要和深入阅读导航；`docs/README.md` 作为文档地图，负责把深度内容组织为几个阅读路径；其余文档再按“系统机制”和“维护操作”拆分。

选择这个结构而不是继续扩写单篇“大而全”设计文档，是因为当前问题不是文档太少，而是认知入口混乱、不同深度的信息被堆在一起。分层后可以让不同读者在不同阶段只读自己需要的信息。

考虑过的替代方案：
- 保持现有文件名不变，仅扩写内容。问题是仍然无法解决阅读路径混乱和重复信息失真。
- 只维护一个总设计文档。问题是单文档很快再次变成难维护的知识堆栈。

### 2. 以“真实执行链路”为文档主轴，而不是以文件列表为主轴

新的核心文档应优先描述以下流程：
- 应用启动与初始化
- 权限检查与监听启动
- 快捷键事件进入录音状态
- 语音识别与波形更新
- 停止录音后的识别文本收敛
- LLM 润色分支
- 文本注入与失败回传

这是因为维护者真正需要理解的是行为链路，而不是先看到一张静态文件列表。模块说明应服务于流程理解，而不是取代流程。

考虑过的替代方案：
- 先按模块逐个写职责说明，再由读者自己拼装流程。问题是排障和功能修改时成本仍然高。

### 3. 将“数据流”和“问题定位”设计为一等文档对象

文档升级必须单独说明以下几类流转：
- 控制流：事件和回调如何驱动状态切换
- 数据流：音频缓冲、识别文本、润色文本、设置项、日志文件如何流转
- 故障流：异常在哪一层首次暴露、向上如何表现、通过什么日志观察

这是因为当前故障排查难度主要不来自 API 不清楚，而来自“现象”和“源码实际落点”之间缺桥。把排障路径写成一级内容，比补更多 API 片段更有维护价值。

考虑过的替代方案：
- 继续保留 FAQ 式 troubleshooting。问题是现象导向强，但无法把问题稳定映射到模块和日志。

### 4. 用“文档覆盖矩阵”约束后续维护

设计中要求文档明确维护规则，例如：
- 新增用户可见能力时，必须更新 `README.md` 的能力摘要和对应深度文档链接。
- 修改核心运行链路时，必须更新工作流或数据流文档。
- 新增关键日志、权限依赖或外部系统交互时，必须更新排障文档。

选择显式维护矩阵，而不是依赖人工默契，是为了降低 README 与源码逐渐失真的概率。

## Risks / Trade-offs

- [文档过度扩张] 文档文件可能迅速增多，导致维护成本上升 → 通过 `docs/README.md` 提供稳定导航，并限定每篇文档的职责边界。
- [源码与文档再次偏离] 如果后续变更不更新文档，体系仍会失效 → 在文档中加入明确维护规则，并在任务中包含一次一致性校验。
- [描述过度理想化] 如果文档沿用旧设计而非当前代码，会误导维护者 → 所有关键流程必须以当前 `Sources/VoiceInput/*.swift` 实现为事实来源。
- [故障排障仍然碎片化] 如果 troubleshooting 只增加案例而不增加诊断路径，价值有限 → 强制把现象、日志模块、系统依赖和源码责任模块连起来描述。

## Migration Plan

1. 审视现有 `README.md` 和 `docs/*.md` 的职责与重复内容，建立新的文档分层方案。
2. 依据当前源码梳理完整运行链路、数据流与模块关系，形成新的核心深度文档内容。
3. 重写 `docs/README.md` 作为统一导航入口，将文档按阅读目标组织。
4. 重写或拆分现有深度文档与 troubleshooting，使其能覆盖调试和定位问题的路径。
5. 对照文档维护规则进行一次一致性检查，确认 README、深度文档和源码认知一致。

回滚策略：
- 如果新结构无法提升可读性，可以保留已补充的流程与排障内容，同时将导航重新折叠回较少文件。
- 由于本次主要变更文档，不涉及运行时代码，回滚成本主要是文件结构回退。

## Open Questions

- 是否需要在本次升级中引入“按角色阅读路径”，例如面向新开发者、排障维护者、功能扩展者的独立入口。
- 当前 `docs/` 是否继续沿用现有文件名，还是拆分成更贴近认知任务的新文件集合。
- 是否需要补充一份专门的“日志索引”文档，将 `Logger` 模块与常见故障现象建立一一映射。

<!-- opencode:openspec-agent-optimized:start -->
## Execution-Oriented Addendum

### Implementation Slices
- 1. Documentation Architecture
- 2. Workflow And Architecture Content
- 3. Troubleshooting And Maintenance Guides
- 4. Entry Documents And Consistency Validation

### Recommended Agent Routing
- `@explorer`: codebase discovery, path identification, existing-pattern analysis
- `@librarian`: external docs, framework APIs, platform behavior validation
- `@designer`: UI, layout, interaction, and visual refinement
- `@fixer`: implementation, tests, targeted refactors
- `@oracle`: architecture, security, performance, migration, and permission review

### Review Focus
- Validate permission, security, signing, and install behavior before implementation is considered complete.
- Check migration and persistence paths to avoid regressions for existing users.

### Apply Handoff
- Primary agent should continue `openspec apply` using the route-aware tasks in `tasks.md`.
- Prefer `@explorer` before `@fixer` when file boundaries remain unclear.
- Prefer `@librarian` before `@fixer` when platform or library behavior must be validated.
- Insert `@oracle` before implementation or final verification for high-risk changes.
<!-- opencode:openspec-agent-optimized:end -->
