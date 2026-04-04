## Why

当前菜单栏的LLM Refinement配置入口较深，且缺少常见的应用设置（如开机启动）。用户需要一个集中的设置界面来管理所有应用偏好设置，而不是分散的菜单项。这不仅提升用户体验，也为后续添加更多设置项打下基础。

## What Changes

- **菜单栏重构**: 移除现有的"LLM Refinement"子菜单，替换为"Settings..."菜单项
- **设置窗口扩展**: 将现有的SettingsWindow重构为通用设置窗口，支持多Section布局
- **LLM设置迁移**: 现有的LLM配置（API URL、API Key、Model、Enable开关）作为Settings中的一个Section，用分隔线与其他设置区分
- **新增启动设置**: 添加"开机自动启动"选项到Settings窗口
- **菜单结构保留**: Language和Quit菜单项位置保持不变

## Capabilities

### New Capabilities
- `app-settings`: 集中管理应用偏好设置，包括启动项和LLM配置
- `launch-at-login`: 支持设置应用开机自动启动

### Modified Capabilities
- `llm-refinement`: 配置入口从独立的子菜单迁移到Settings窗口内的Section，移除菜单栏中的独立子菜单，但保留核心功能

## Impact

- **AppDelegate.swift**: 重构buildMenuBar()方法，移除buildLLMMenu()，添加Settings菜单项点击处理
- **SettingsWindow.swift**: 重构窗口布局，支持Section分组，添加开机启动选项，窗口标题从"LLM Refinement Settings"改为"Settings"
- **LLMRefiner.swift**: 可能需要添加新的UserDefaults键存储设置状态
- **新增依赖**: 需要引入ServiceManagement框架用于开机启动管理
