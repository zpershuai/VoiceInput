# VoiceInput

一款优雅的 macOS 菜单栏语音输入工具，支持实时语音识别、多语言切换和 AI 文本润色。

## 功能特性

- **快捷键触发**：按住快捷键（默认 Fn）开始录音，松开自动输入转录文本
- **实时转录**：基于 Apple Speech Recognition 框架的流式语音识别
- **多语言支持**：简体中文、繁体中文、英语、日语、韩语
- **AI 润色**：集成 OpenAI 兼容 API，智能优化识别结果
- **精美界面**：胶囊形浮动窗口，波形动画实时反馈
- **菜单栏应用**：LSUIElement 模式，无 Dock 图标

## 快速开始

### 安装

```bash
git clone git@github.com:zpershuai/VoiceInput.git
cd VoiceInput
make build && make install
```

### 首次运行

1. 授予 **麦克风** 和 **辅助功能** 权限（系统会提示）
2. 按住快捷键（默认 Fn）开始录音
3. 松开快捷键，文本自动输入到当前焦点位置

### 配置

右键菜单栏麦克风图标：
- **Language** — 切换识别语言
- **Settings** — 配置快捷键、LLM 润色、开机启动

## 核心工作流

```
按住快捷键 → 显示浮动窗口 → 实时识别 + 波形动画
    → 松开快捷键 → 获取识别文本
    → LLM 润色（可选）→ 注入文本到当前输入框
    → 隐藏窗口，回到待命状态
```

详细流程见 → [运行工作流](docs/workflow.md)

## 深入阅读

| 目标 | 文档 |
|------|------|
| 理解完整运行流程 | [运行工作流](docs/workflow.md) |
| 了解模块职责与数据流 | [架构与模块](docs/architecture.md) |
| 定位问题与排查故障 | [故障排除](docs/troubleshooting.md) |
| 开发环境与调试 | [开发指南](docs/development-guide.md) |
| 文档导航总览 | [文档索引](docs/README.md) |

## 系统要求

- macOS 14.0+
- 麦克风访问权限
- 辅助功能权限（用于全局快捷键监听和文本注入）

## 技术栈

- **语言**: Swift 5.9
- **框架**: AppKit, Speech, AVFoundation, CoreGraphics
- **构建**: Swift Package Manager + Makefile

## 隐私

- 语音数据仅在本地处理（Apple Speech API）
- LLM 润色仅在主动启用时发送文本到配置的 API
- 所有配置保存在本地 UserDefaults

## 许可证

MIT License
