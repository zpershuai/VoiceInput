# 运行工作流

本文档描述 VoiceInput 从启动到文本注入的完整运行时流程。所有流程以 `Sources/VoiceInput/*.swift` 的实际实现为事实来源。

## 1. 应用启动与初始化

**入口**: `main.swift` → `AppDelegate.applicationDidFinishLaunching`

```
main.swift (全局 appDelegate 变量保持引用)
    │
    ▼
AppDelegate.applicationDidFinishLaunching
    │
    ├── 清理 7 天前的旧日志 (Logger.clearOldLogs)
    │
    ├── 1. 创建菜单栏状态项 (NSStatusBar, mic.fill 图标)
    │
    ├── 2. 构建菜单栏 (Language 子菜单, Settings, Quit)
    │   └── 注册 Cmd+, 本地快捷键打开设置
    │
    ├── 3. 初始化核心组件
    │   ├── GlobalEventMonitor()
    │   ├── SpeechRecognizer(localeCode: LanguageManager.shared.currentLanguage)
    │   ├── FloatingWindow()
    │   └── SettingsWindow()
    │
    ├── 4. 应用存储的快捷键配置 (applyStoredShortcut)
    │
    ├── 5. 连接回调链路
    │   ├── eventMonitor.onStartRecording → startRecording()
    │   ├── eventMonitor.onStopRecording  → stopRecordingAndInject()
    │   ├── speechRecognizer.onPartialResult → floatingWindow.updateText()
    │   ├── speechRecognizer.onRMSUpdate   → floatingWindow.waveform.updateRMS()
    │   ├── speechRecognizer.onFinalResult → floatingWindow.updateText()
    │   └── speechRecognizer.onError       → floatingWindow.hide()
    │
    ├── 6. 监听语言切换 (Combine sink on LanguageManager.$currentLanguage)
    │
    ├── 7. 同步 LaunchAtLogin 状态
    │
    └── 8. 检查辅助功能权限
        ├── 已授权 → startEventMonitorIfNeeded()
        └── 未授权 → 显示 PermissionAlert 自定义窗口
```

**关键文件**: `AppDelegate.swift:25-105`

## 2. 权限检查与监听启动

### 辅助功能权限

```
handleAccessibilityPermissionAtLaunch
    │
    ├── GlobalEventMonitor.checkAccessibilityPermission()
    │   └── AXIsProcessTrusted()
    │
    ├── 已授权
    │   └── startEventMonitorIfNeeded()
    │       └── eventMonitor.start()
    │           ├── CGEvent.tapCreate (eventsOfInterest: keyDown, keyUp, flagsChanged)
    │           ├── CFRunLoopAddSource (main run loop, commonModes)
    │           └── CGEvent.tapEnable (enable: true)
    │
    └── 未授权
        └── PermissionAlert.showAccessibilityPermissionAlert()
            └── 用户授权回调 → startEventMonitorIfNeeded()
```

**关键文件**: `AppDelegate.swift:230-269`, `GlobalEventMonitor.swift:43-73`

### 麦克风与语音识别权限

在首次 `startRecording()` 时由 `SFSpeechRecognizer.requestAuthorization` 和 `AVAudioApplication.requestRecordPermission` 触发系统弹窗。

## 3. 快捷键事件进入录音状态

```
用户按下快捷键 (默认 Fn 键, keyCode=63)
    │
    ▼
CGEventTap 捕获 flagsChanged 事件
    │
    ▼
globalEventTapCallback (GlobalEventMonitor.swift:101-151)
    │
    ├── 检测 .maskSecondaryFn 标志
    ├── monitor.isShortcutPressed = true
    ├── monitor.onStartRecording?()  ← 回调到 AppDelegate
    └── return nil (抑制事件传播，阻止系统默认行为)
    │
    ▼
AppDelegate.startRecording()
    │
    ├── isRecording = true
    ├── floatingWindow.show() (带动画)
    └── Task { speechRecognizer.startRecording() }
```

**快捷键可配置**: 通过 `ShortcutManager` 和 `SettingsWindow` 中的 `ShortcutRecorderView` 修改。

**关键文件**: `GlobalEventMonitor.swift:118-144`, `AppDelegate.swift:285-306`

## 4. 语音识别与波形更新

```
SpeechRecognizer.startRecording() (async)
    │
    ├── 请求权限: SFSpeechRecognizer.requestAuthorization
    ├── 请求麦克风: AVAudioApplication.requestRecordPermission
    ├── 创建 SFSpeechRecognizer(locale: localeCode)
    ├── 创建 SFSpeechAudioBufferRecognitionRequest(shouldReportPartialResults: true)
    │
    ├── 创建 AVAudioEngine
    │   └── inputNode.installTap (bus:0, bufferSize:1024)
    │       ├── buffer → recognitionRequest.append(buffer)
    │       └── computeRMS(buffer) → onRMSUpdate(rms)
    │
    ├── recognizer.recognitionTask(with: request) { result, error in
    │   ├── result.isFinal == false
    │   │   └── onPartialResult(transcription) → floatingWindow.updateText()
    │   │
    │   └── result.isFinal == true
    │       ├── finalTranscription = transcription
    │       ├── finishStoppingIfNeeded(with: transcription)
    │       └── onFinalResult(transcription) → floatingWindow.updateText()
    │
    └── engine.start()
```

**RMS 计算**: `computeRMS` 遍历 `AVAudioPCMBuffer.floatChannelData` 计算均方根值 (0.0-1.0)，通过 `onRMSUpdate` 回调驱动 `WaveformView` 动画。

**关键文件**: `SpeechRecognizer.swift:41-119`

## 5. 停止录音后的识别文本收敛

```
用户松开快捷键
    │
    ▼
globalEventTapCallback 检测 flagsChanged 失去 .maskSecondaryFn
    │
    ▼
monitor.onStopRecording?() → AppDelegate.stopRecordingAndInject()
    │
    ├── isRecording = false
    │
    └── Task {
        │
        ├── speechRecognizer.stopRecording() (async)
        │   ├── audioEngine.stop()
        │   ├── inputNode.removeTap(onBus: 0)
        │   ├── recognitionRequest.endAudio()
        │   ├── 等待 800ms flush (Task.sleep)
        │   └── 返回 finalTranscription 或 lastTranscription
        │
        └── 检查文本是否为空
            └── 空 → floatingWindow.hide(), 结束
```

**关键文件**: `AppDelegate.swift:308-323`, `SpeechRecognizer.swift:121-170`

## 6. LLM 润色分支

```
获取识别文本后
    │
    ├── 检查 LLMRefiner.isEnabled && LLMRefiner.isConfigured
    │
    ├── 已启用且已配置
    │   ├── floatingWindow.updateStatus("Refining...")
    │   │
    │   ├── LLMRefiner.refine(text:) (async throws)
    │   │   ├── 构建 ChatCompletionRequest
    │   │   │   ├── system: 保守修正提示词
    │   │   │   └── user: 原始识别文本
    │   │   ├── POST {apiBaseUrl}/v1/chat/completions
    │   │   └── 解析 ChatCompletionResponse.choices[0].message.content
    │   │
    │   ├── 成功 → injectText(refinedText)
    │   └── 失败 → catch → injectText(originalText) (fallback)
    │
    └── 未启用或未配置
        └── injectText(originalText)
```

**关键文件**: `AppDelegate.swift:327-346`, `LLMRefiner.swift:96-148`

## 7. 文本注入与失败回传

```
injectText(text)
    │
    ▼
TextInjector.inject(text: completion:)
    │
    ├── DispatchQueue.global(qos: .userInitiated).async
    │   └── performInjection(text:)
    │       └── simulateTyping(text)
    │           ├── 将 text 转为 UTF-16 数组
    │           ├── 创建 CGEvent(keyboardEventSource, virtualKey: 0, keyDown: true)
    │           ├── keyDown.keyboardSetUnicodeString(utf16)
    │           ├── keyDown.post(tap: .cgSessionEventTap)
    │           ├── usleep(12_000) (12ms 延迟)
    │           ├── keyUp.keyboardSetUnicodeString(utf16)
    │           └── keyUp.post(tap: .cgSessionEventTap)
    │
    └── completion(success)
        ├── 成功 → Logger.input.info("Text injection successful")
        └── 失败 → Logger.input.error("Text injection failed")
    │
    ▼
floatingWindow.hide() (带动画)
```

**关键文件**: `AppDelegate.swift:356-364`, `TextInjector.swift:7-61`

## 8. 完整状态机

```
                    ┌─────────────┐
                    │   Idle      │
                    │ (初始状态)   │
                    └──────┬──────┘
                           │
              快捷键按下     │
                           ▼
                    ┌─────────────┐
                    │  Recording  │
                    │ (录音中)     │
                    └──────┬──────┘
                           │
              快捷键松开     │
                           ▼
                    ┌─────────────┐
                    │ Processing  │
                    │ (识别/润色)  │
                    └──────┬──────┘
                           │
              文本注入完成   │
                           ▼
                    ┌─────────────┐
                    │   Idle      │
                    │ (回到初始)   │
                    └─────────────┘

异常路径:
  Recording → Error → Idle (speechRecognizer.onError)
  Processing → Fallback → Idle (LLM 失败时注入原文)
```

## 9. 关键状态变量

| 变量 | 位置 | 作用 |
|------|------|------|
| `isRecording` | `AppDelegate` | 防止重复录音 |
| `isEventMonitorRunning` | `AppDelegate` | 防止重复启动监听 |
| `isShortcutPressed` | `GlobalEventMonitor` | 跟踪快捷键按下状态 |
| `finalTranscription` | `SpeechRecognizer` | 最终识别结果 (isFinal=true) |
| `lastTranscription` | `SpeechRecognizer` | 最新识别结果 (含中间结果) |
| `stopContinuation` | `SpeechRecognizer` | async/await 桥接 |
| `currentLanguage` | `LanguageManager` | 当前识别语言 |
