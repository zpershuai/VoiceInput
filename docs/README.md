# VoiceInput 文档索引

本文档按维护目标组织 VoiceInput 的深度技术文档。选择你的阅读路径。

## 按阅读目标

### 我想理解系统如何运行

→ [运行工作流](workflow.md) — 从启动到文本注入的完整流程，包含状态机和关键变量

### 我想理解模块如何协作

→ [架构与模块](architecture.md) — 模块职责、回调关系图、数据流、状态转换、外部系统集成

### 我想排查问题

→ [故障排除](troubleshooting.md) — 症状→模块→日志映射表，带诊断路径和关键日志关键词

### 我想开发或调试

→ [开发指南](development-guide.md) — 构建、运行、调试技巧、测试清单、发布流程

## 按文档类型

| 文档 | 职责 | 何时更新 |
|------|------|---------|
| [运行工作流](workflow.md) | 端到端运行时流程 | 工作流变更时 |
| [架构与模块](architecture.md) | 模块边界、回调、数据流 | 架构变更时 |
| [故障排除](troubleshooting.md) | 症状→模块→日志映射 | 新增故障模式时 |
| [开发指南](development-guide.md) | 开发环境、构建、调试 | 工具链变更时 |

## 已废弃文档

以下文档已被新文档体系替代，内容已整合到上述文档中：

- `architecture-overview.md` → 整合到 [架构与模块](architecture.md)
- `detailed-design.md` → 整合到 [架构与模块](architecture.md) + [运行工作流](workflow.md)
- `api-reference.md` → 整合到 [架构与模块](architecture.md)

## 文档维护规则

当代码发生变更时，参考以下矩阵更新文档：

| 变更类型 | 必须更新的文档 |
|---------|--------------|
| 新增用户可见功能 | README.md 能力摘要 + 对应深度文档 |
| 修改核心运行链路 | [运行工作流](workflow.md) |
| 新增/修改模块职责 | [架构与模块](architecture.md) |
| 新增日志模块或修改日志行为 | [架构与模块](architecture.md) §Logger + [故障排除](troubleshooting.md) |
| 新增权限依赖 | [故障排除](troubleshooting.md) §权限清单 |
| 新增已知问题 | [故障排除](troubleshooting.md) |
