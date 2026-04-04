## Why

当前 Settings 窗口存在明显的版式问题：顶部留白过大，`General` 区块起始位置偏低，底部 `Test` / `Save` 按钮被窗口裁切，影响可读性和可操作性。同时，状态栏菜单中的 `Settings...` 目前带有前置图标，与 `Language`、`Quit` 的纯文本样式不一致，削弱了菜单整体的一致性。

## What Changes

- 优化 Settings 窗口的纵向间距，减少标题栏下方到首个 section 的空白
- 调整窗口内容区域和底部按钮区域的布局，确保 `Test` 与 `Save` 按钮完整显示且与表单保持清晰层次
- 在不大改现有结构的前提下，统一 Settings 窗口的 section 节奏与边距，使界面更简洁、克制
- 移除状态栏菜单中 `Settings...` 项目前的图标，使其与 `Language`、`Quit` 的表现一致

## Capabilities

### New Capabilities
- `settings-window-layout`: 定义 Settings 窗口的紧凑布局、合理 section 间距，以及完整可见的底部操作按钮
- `status-menu-consistency`: 定义状态栏菜单项的视觉一致性，要求 `Settings...` 使用纯文本样式且不带前置图标

### Modified Capabilities

## Impact

- **SettingsWindow.swift**: 调整窗口高度、内容 inset、section 间距和底部按钮布局
- **AppDelegate.swift**: 调整状态栏菜单中 `Settings...` 项的标题或构造方式，移除前置图标
- **手动验证**: 需要重新检查不同内容状态下窗口是否仍能完整显示底部操作按钮，以及菜单项排序与快捷键是否保持不变
