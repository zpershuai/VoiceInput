# VoiceInput

一款优雅的 macOS 菜单栏语音输入工具，支持实时语音识别、多语言切换和 AI 文本润色。

## 功能特性

- **Fn 键触发**：按住 Fn 键开始录音，松开自动输入转录文本
- **实时转录**：基于 Apple Speech Recognition 框架的流式语音识别
- **多语言支持**：简体中文、繁体中文、英语、日语、韩语
- **AI 润色**：集成 OpenAI 兼容 API，智能优化识别结果
- **精美界面**：胶囊形浮动窗口，5 段波形动画实时反馈
- **CJK 兼容**：智能检测输入法并自动切换 ASCII 模式
- **菜单栏应用**：LSUIElement 模式，无 Dock 图标

## 系统要求

- macOS 14.0+
- Apple Silicon 或 Intel Mac
- 麦克风访问权限
- 辅助功能权限（用于全局 Fn 键监听和文本注入）

## 安装

### 从源码构建

```bash
# 克隆仓库
git clone git@github.com:zpershuai/VoiceInput.git
cd VoiceInput

# 构建发布版本
make build

# 安装到应用程序文件夹
make install
```

### 首次运行

1. 将 `VoiceInput.app` 拖到应用程序文件夹
2. 首次启动时，系统会请求以下权限：
   - **麦克风**：用于语音识别
   - **辅助功能**：用于全局 Fn 键监听和文本注入（System Settings → Privacy & Security → Accessibility）
3. 如果尚未授予辅助功能权限，应用会显示阻塞式提示窗口，并提供“打开系统设置”快捷入口
4. 在系统设置中启用权限后，应用会自动检测并开始监听 Fn 键
5. 按住 Fn 键开始录音

## 使用方法

### 基本操作

| 操作 | 说明 |
|------|------|
| 按住 Fn | 开始录音，显示浮动窗口 |
| 松开 Fn | 停止录音，自动输入转录文本 |
| 菜单栏图标 | 右键打开设置菜单 |

### 语言切换

点击菜单栏图标，选择 Language 子菜单切换识别语言。

### LLM 润色配置

1. 右键菜单栏图标 → LLM Refinement → Settings
2. 填写以下信息：
   - **API Base URL**: 如 `https://api.openai.com/v1`
   - **API Key**: 你的 API 密钥
   - **Model**: 如 `gpt-4o-mini`
3. 勾选 "Enable LLM Refinement" 启用润色功能

支持任何 OpenAI 兼容的 API（OpenAI、Azure OpenAI、本地 LLM 等）。

## 项目结构

```
VoiceInput/
├── Sources/VoiceInput/       # 源代码
│   ├── main.swift           # 入口
│   ├── AppDelegate.swift    # 应用生命周期
│   ├── GlobalEventMonitor.swift  # 全局 Fn 键监听
│   ├── PermissionAlert.swift     # 辅助功能权限提示
│   ├── SpeechRecognizer.swift    # 语音识别
│   ├── FloatingWindow.swift      # 浮动 UI 窗口
│   ├── WaveformView.swift        # 波形动画
│   ├── TextInjector.swift        # 文本注入
│   ├── LLMRefiner.swift          # AI 润色
│   ├── SettingsWindow.swift      # 设置界面
│   ├── LanguageManager.swift     # 语言管理
│   └── Logger.swift              # 日志系统
├── docs/                     # 设计文档
├── Package.swift            # Swift Package Manager
├── Info.plist               # 应用配置
├── Makefile                 # 构建脚本
└── README.md                # 本文件
```

## 日志查看

日志文件保存在：

```
~/Library/Logs/VoiceInput/voiceinput_YYYY-MM-DD.log
```

包含 7 个模块的详细日志：App、Speech、Input、LLM、UI、Event、Settings。

## 开发

```bash
# 调试运行
make run

# 清理构建
make clean

# 查看构建产物
ls .build/release/
```

## 技术栈

- **语言**: Swift 5.9
- **框架**: AppKit, Speech, Carbon
- **构建**: Swift Package Manager
- **API**: OpenAI Compatible API

## 隐私说明

- 语音数据仅用于本地识别，不上传到任何服务器（除非启用 LLM 润色）
- LLM 润色功能仅在用户主动启用时才会发送文本到配置的 API
- 所有配置保存在本地 UserDefaults

## 许可证

MIT License

## 致谢

- Apple Speech Recognition 框架
- OpenAI API
