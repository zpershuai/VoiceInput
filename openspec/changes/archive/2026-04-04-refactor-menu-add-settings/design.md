## Context

当前VoiceInput应用使用三级菜单结构：Language子菜单、LLM Refinement子菜单、Quit。LLM Refinement子菜单包含"Enable Refinement"开关和"Settings..."打开设置窗口的选项。这种设计在LLM是唯一可配置项时尚可接受，但随着需要添加更多设置（如开机启动），菜单会变得臃肿。

现有的SettingsWindow仅用于配置LLM参数（API URL、API Key、Model），窗口标题也是"LLM Refinement Settings"。需要将其重构为通用的设置中心。

macOS应用的标准模式是使用集中式的Settings/Preferences窗口管理所有配置，通过菜单栏的单个入口访问。

## Goals / Non-Goals

**Goals:**
- 简化菜单栏结构，保留Language和Quit，将LLM和新增设置统一放入Settings
- 重构SettingsWindow支持多Section布局（通用设置、LLM设置）
- 实现开机自动启动功能，并在Settings窗口提供开关
- 保持现有LLM配置的数据持久化和功能不变
- 确保新用户和老用户都能直观找到设置入口

**Non-Goals:**
- 不改变LLM Refinement的核心功能和API调用逻辑
- 不添加除开机启动外的其他新设置项（为后续扩展预留架构即可）
- 不改变Language子菜单的结构和交互方式
- 不改变Quit菜单的位置和行为

## Decisions

### 1. 使用单窗口多Section而非多标签页
**Decision**: 在SettingsWindow中使用垂直滚动的Section布局，而非NSTabView。

**Rationale**:
- 当前只有2个Section（通用设置、LLM设置），内容不多，单页滚动更直观
- 减少用户点击次数，所有设置一目了然
- macOS Human Interface Guidelines推荐：简单设置用单页，复杂设置用标签页

**Alternative considered**: NSTabView - 否决，会增加不必要的复杂性

### 2. 使用ServiceManagement框架管理开机启动
**Decision**: 使用`SMLoginItemSetEnabled`配合Helper App实现可靠的开机启动

**Rationale**:
- macOS 13+推荐使用ServiceManagement框架，比旧的LaunchAgent方式更可靠
- Helper App模式是Apple推荐的标准做法，用户可在System Settings中看到并管理
- 需要创建一个小的Helper target，但代码量很小

**Alternative considered**: LaunchAgent plist - 否决，新系统不推荐，且沙盒应用受限

### 3. LLM Enable开关位置
**Decision**: 将"Enable LLM Refinement"开关移到Settings窗口的LLM Section顶部，而非保留在菜单中

**Rationale**:
- 与LLM配置参数放在一起，逻辑更连贯
- 用户打开Settings窗口可以一站式完成所有LLM相关配置
- 减少菜单栏的交互复杂度

**Alternative considered**: 保留在菜单中 - 否决，会造成设置分散在两处

### 4. 数据迁移策略
**Decision**: 保持现有的UserDefaults键不变，确保现有用户配置无缝迁移

**Rationale**:
- LLMRefiner使用的键（`llmApiBaseUrl`, `llmApiKey`, `llmModel`, `llmEnabled`）保持不变
- 新增`launchAtLoginEnabled`键存储开机启动设置
- 用户升级后无需重新配置

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 用户习惯原有菜单结构，找不到设置入口 | 在Settings窗口首次打开时显示引导提示；在菜单中使用标准"Settings..."命名和⌘,快捷键 |
| ServiceManagement需要Helper App，增加构建复杂度 | Helper App代码量<50行，使用Makefile自动化构建和打包 |
| 开机启动权限需要用户授权 | 在用户勾选"开机启动"时检测权限状态，必要时引导用户到System Settings |
| 设置窗口内容增加后可能变长 | 使用NSScrollView包装内容，确保窗口有最大高度限制 |

## Migration Plan

1. **开发阶段**:
   - 重构SettingsWindow为通用设置窗口
   - 添加LaunchAtLoginManager管理开机启动
   - 创建Helper App target
   
2. **测试阶段**:
   - 验证现有LLM配置数据正确加载
   - 测试开机启动开关的启用/禁用
   - 确认菜单栏交互正常

3. **部署阶段**:
   - 正常构建发布，无特殊迁移步骤
   - 用户升级后原有LLM配置自动保留

## Open Questions

None - 设计已确定，可以开始实现。
