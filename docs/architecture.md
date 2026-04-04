# 架构与模块

本文档描述 VoiceInput 的模块边界、回调关系、数据流和关键状态转换。以源码实现为事实来源。

## 1. 模块总览

```
┌─────────────────────────────────────────────────────────────────┐
│                         VoiceInput App                          │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ FloatingWindow│  │ WaveformView │  │   SettingsWindow     │  │
│  │ (胶囊浮动窗)   │  │  (波形动画)   │  │     (设置界面)        │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  Core Logic Layer                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │SpeechRecognizer│ │ TextInjector │  │     LLMRefiner       │  │
│  │   (语音识别)   │  │   (文本注入)  │  │    (AI 润色)         │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  Infrastructure Layer                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │GlobalEventMon│  │LanguageManager│  │       Logger         │  │
│  │ (全局事件监听) │  │   (语言管理)  │  │     (日志系统)        │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  System Integration                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  CGEventTap  │  │    Speech    │  │   CGEvent Unicode    │
│  │ (全局快捷键)  │  │  Framework   │  │     (文本注入)        │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 2. 模块职责与边界

### AppDelegate

**职责**: 应用生命周期管理，协调各模块工作，维护全局状态。

**关键属性**:
- `statusItem`: NSStatusItem — 菜单栏图标
- `eventMonitor`: GlobalEventMonitor — 全局快捷键监听
- `speechRecognizer`: SpeechRecognizer — 语音识别引擎
- `floatingWindow`: FloatingWindow — 浮动 UI 窗口
- `settingsWindow`: SettingsWindow — 设置界面
- `permissionAlert`: PermissionAlert? — 权限提示窗口
- `isRecording`: Bool — 防止重复录音
- `isEventMonitorRunning`: Bool — 防止重复启动监听

**关键方法**:
- `applicationDidFinishLaunching` — 初始化所有组件，连接回调
- `startRecording` — 显示窗口，启动语音识别
- `stopRecordingAndInject` — 停止录音，获取文本，LLM 润色（可选），注入文本
- `injectText` — 调用 TextInjector 注入文本
- `handleAccessibilityPermissionAtLaunch` — 启动时权限检查
- `applyStoredShortcut` — 应用存储的快捷键配置

**依赖**: 所有其他模块

**文件**: `AppDelegate.swift`

---

### GlobalEventMonitor

**职责**: 通过 CGEventTap 监听全局键盘事件，检测快捷键按下/释放。

**关键属性**:
- `onStartRecording: (() -> Void)?` — 快捷键按下回调
- `onStopRecording: (() -> Void)?` — 快捷键释放回调
- `targetKeyCode: CGKeyCode` — 目标键码（默认 63 = Fn）
- `targetModifierFlags: UInt` — 修饰键标志（默认 0 = 无修饰键）

**关键方法**:
- `start() -> Bool` — 创建 CGEventTap，注册到主运行循环
- `stop()` — 禁用并移除事件 Tap
- `updateTargetShortcut(keyCode:modifierFlags:)` — 动态更新快捷键并重启 Tap

**系统依赖**: CoreGraphics (CGEventTap), ApplicationServices (AXIsProcessTrusted)

**权限**: 辅助功能权限（Accessibility）

**文件**: `GlobalEventMonitor.swift`

---

### SpeechRecognizer

**职责**: 音频录制、流式语音识别、RMS 音量监测。

**关键属性**:
- `onPartialResult: ((String) -> Void)?` — 中间识别结果回调
- `onFinalResult: ((String) -> Void)?` — 最终识别结果回调
- `onRMSUpdate: ((Float) -> Void)?` — 音频音量回调
- `onError: ((Error) -> Void)?` — 错误回调
- `localeCode: String` — 当前识别语言代码

**关键方法**:
- `startRecording() async throws` — 请求权限，启动 AVAudioEngine 和 SFSpeechRecognizer
- `stopRecording() async -> String?` — 停止录音，返回识别文本
- `setLanguage(_ localeCode: String)` — 更新语言代码（下次录音生效）

**系统依赖**: Speech (SFSpeechRecognizer), AVFoundation (AVAudioEngine)

**权限**: 麦克风权限、语音识别权限

**文件**: `SpeechRecognizer.swift`

---

### FloatingWindow

**职责**: 显示胶囊形浮动窗口，展示波形动画和实时转录文本。

**关键属性**:
- `waveform: WaveformView` — 波形视图引用

**关键方法**:
- `show()` — 显示窗口，带缩放进入动画
- `hide()` — 隐藏窗口，带缩小退出动画
- `updateText(_ text: String)` — 更新转录文本，自动调整窗口大小
- `updateStatus(_ status: String)` — 更新状态文本（如 "Refining..."）

**布局模式**:
- `defaultSingleLine` — 默认单行（文本 < 180pt）
- `expandedSingleLine` — 扩展单行（文本 180-420pt）
- `twoLine` — 双行模式（文本 > 420pt）

**窗口类型**: NSPanel (nonactivatingPanel, borderless, fullSizeContentView)

**文件**: `FloatingWindow.swift`

---

### WaveformView

**职责**: 5 段波形动画，由 RMS 值驱动。

**关键方法**:
- `updateRMS(_ rms: Float)` — 更新音量值，触发动画

**文件**: `WaveformView.swift`

---

### TextInjector

**职责**: 将文本注入到当前焦点输入框。

**关键方法**:
- `inject(text:completion:)` — 通过 CGEvent Unicode 键盘事件注入文本

**实现方式**: 使用 `CGEvent.keyboardSetUnicodeString` 模拟键盘输入，非剪贴板方式。

**系统依赖**: CoreGraphics (CGEvent)

**权限**: 辅助功能权限

**文件**: `TextInjector.swift`

---

### LLMRefiner

**职责**: 调用 OpenAI 兼容 API 对识别文本进行保守修正。

**关键属性**:
- `apiBaseUrl: String` — API 基础 URL（UserDefaults 持久化）
- `apiKey: String` — API 密钥（UserDefaults 持久化）
- `model: String` — 模型名称（UserDefaults 持久化）
- `isEnabled: Bool` — 是否启用润色（UserDefaults 持久化）
- `isConfigured: Bool` — apiKey 和 apiBaseUrl 均非空

**关键方法**:
- `refine(text:) async throws -> String` — 发送文本到 LLM，返回修正结果
- `testConnection() async throws -> String` — 测试 API 连接

**错误类型**: `RefineError.invalidResponse`, `.httpError`, `.malformedResponse`

**文件**: `LLMRefiner.swift`

---

### SettingsWindow

**职责**: 设置界面，管理 LaunchAtLogin、快捷键、LLM 配置。

**关键方法**:
- `show()` — 显示设置窗口，刷新所有字段
- `setOnShortcutChanged` — 设置快捷键变更回调

**界面分区**:
- General: Launch at Login 复选框
- Keyboard Shortcut: ShortcutRecorderView + Reset to Default 按钮
- LLM Refinement: Enable 复选框 + API Base URL / API Key / Model 表单
- 底部: Test 按钮 + Save 按钮

**文件**: `SettingsWindow.swift`

---

### LanguageManager

**职责**: 管理支持的语言列表，持久化当前语言选择。

**关键属性**:
- `currentLanguage: String` — 当前语言代码（@Published，Combine 兼容）
- `currentLanguageName: String` — 当前语言显示名称

**支持语言**: zh-CN (简体中文), en-US (English), zh-TW (繁體中文), ja-JP (日本語), ko-KR (한국어)

**持久化**: UserDefaults key = "selectedVoiceLanguage"

**文件**: `LanguageManager.swift`

---

### Logger

**职责**: 模块化日志系统，写入文件并输出到控制台。

**日志模块**:
| 模块 | 用途 | 关键日志点 |
|------|------|-----------|
| App | 应用生命周期 | 启动、录音开始/停止、权限检查 |
| Speech | 语音识别 | 权限、识别结果、错误 |
| Input | 文本注入 | 注入成功/失败 |
| LLM | AI 润色 | API 请求/响应、错误 |
| UI | 界面事件 | 窗口显示/隐藏 |
| Event | 事件监听 | 快捷键按下/释放、Tap 创建 |
| Settings | 设置变更 | 语言切换、快捷键更新 |

**日志级别**: DEBUG < INFO < WARN < ERROR

**日志路径**: `~/Library/Logs/VoiceInput/voiceinput_YYYY-MM-DD.log`

**日志保留**: 7 天（启动时自动清理）

**文件**: `Logger.swift`

---

## 3. 回调关系图

```
GlobalEventMonitor
    ├── onStartRecording ──→ AppDelegate.startRecording()
    │                            ├── floatingWindow.show()
    │                            └── speechRecognizer.startRecording()
    │
    └── onStopRecording ──→ AppDelegate.stopRecordingAndInject()
                                 ├── speechRecognizer.stopRecording()
                                 ├── LLMRefiner.refine() (可选)
                                 ├── TextInjector.inject()
                                 └── floatingWindow.hide()

SpeechRecognizer
    ├── onPartialResult ──→ floatingWindow.updateText()
    ├── onFinalResult   ──→ floatingWindow.updateText()
    ├── onRMSUpdate     ──→ floatingWindow.waveform.updateRMS()
    └── onError         ──→ floatingWindow.hide(), isRecording = false

LanguageManager.$currentLanguage (Combine)
    └── sink ──→ speechRecognizer.setLanguage(newLanguage)

SettingsWindow
    └── onShortcutChanged ──→ AppDelegate.applyStoredShortcut()
                                   └── eventMonitor.updateTargetShortcut()
```

## 4. 关键状态转换

### 录音状态机

```
Idle ──[快捷键按下]──→ Recording ──[快捷键松开]──→ Processing ──[注入完成]──→ Idle
  │                        │
  │                        └──[识别错误]──→ Idle
  │
  └──[重复按键]──→ 忽略 (guard !isRecording)
```

### 事件监听状态

```
Stopped ──[权限已授予]──→ Running ──[快捷键变更]──→ Restart ──→ Running
    │
    └──[权限未授予]──→ PermissionAlert ──[用户授权]──→ Running
```

### 浮动窗口状态

```
Hidden ──[show()]──→ Visible ──[hide()]──→ Hidden
              │
              └──[updateText/updateStatus]──→ 可见状态内更新
```

### LLM 润色决策

```
识别文本获取
    │
    ├── isEnabled=false 或 isConfigured=false ──→ 直接注入原文
    │
    └── isEnabled=true 且 isConfigured=true
        │
        ├── API 成功 ──→ 注入润色文本
        └── API 失败 ──→ 注入原文 (fallback)
```

## 5. 数据流

### 音频数据流

```
麦克风输入
    │
    ▼
AVAudioEngine.inputNode
    │
    ├── installTap → buffer → recognitionRequest.append()
    │                      → computeRMS() → onRMSUpdate → WaveformView
    │
    ▼
SFSpeechRecognizer
    │
    ├── isFinal=false → onPartialResult → FloatingWindow.textLabel
    └── isFinal=true  → onFinalResult   → FloatingWindow.textLabel
                           │
                           ▼
                    stopRecording() 返回
```

### 文本数据流

```
SpeechRecognizer.stopRecording() → String?
    │
    ├── nil/empty ──→ floatingWindow.hide(), 结束
    │
    └── 有文本
        │
        ├── LLM 启用且已配置
        │   ├── LLMRefiner.refine() → refinedText → TextInjector.inject()
        │   └── 失败 → 原文 → TextInjector.inject()
        │
        └── LLM 未启用或未配置
            └── 原文 → TextInjector.inject()
                │
                ├── CGEvent.keyboardSetUnicodeString()
                ├── keyDown.post() → usleep(12ms) → keyUp.post()
                └── completion(success/failure)
```

### 设置数据流

```
UserDefaults (持久化存储)
    │
    ├── "selectedVoiceLanguage" ←→ LanguageManager.currentLanguage
    ├── "llmApiBaseUrl"         ←→ LLMRefiner.apiBaseUrl
    ├── "llmApiKey"             ←→ LLMRefiner.apiKey
    ├── "llmModel"              ←→ LLMRefiner.model
    ├── "llmEnabled"            ←→ LLMRefiner.isEnabled
    └── ShortcutManager         ←→ 快捷键配置
```

### 日志数据流

```
各模块调用 Logger.app/.speech/.input/.llm/.ui/.event/.settings
    │
    ▼
Logger.log() → 格式化: [timestamp] [level] [module] [file:line] function: message
    │
    ├── print() (DEBUG 模式)
    │
    └── fileHandleQueue.async → FileHandle.write()
                                   │
                                   ▼
                            ~/Library/Logs/VoiceInput/voiceinput_YYYY-MM-DD.log
```

## 6. 外部系统集成

| 系统 | 用途 | 权限 | 失败影响 |
|------|------|------|---------|
| CGEventTap | 全局快捷键监听 | 辅助功能 | 无法监听快捷键 |
| SFSpeechRecognizer | 语音识别 | 语音识别 | 无法识别语音 |
| AVAudioEngine | 音频录制 | 麦克风 | 无法录音 |
| CGEvent Unicode | 文本注入 | 辅助功能 | 无法输入文本 |
| OpenAI API | LLM 润色 | 网络 | 降级为原文 |
| UserDefaults | 配置持久化 | 无 | 配置丢失 |
