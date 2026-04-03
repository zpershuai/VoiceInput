# API 文档

本文档描述 VoiceInput 各模块的公共接口。

## 目录

- [AppDelegate](#appdelegate)
- [GlobalEventMonitor](#globaleventmonitor)
- [SpeechRecognizer](#speechrecognizer)
- [FloatingWindow](#floatingwindow)
- [WaveformView](#waveformview)
- [TextInjector](#textinjector)
- [LLMRefiner](#llmrefiner)
- [SettingsWindow](#settingswindow)
- [LanguageManager](#languagemanager)
- [Logger](#logger)

---

## AppDelegate

### 概述

应用生命周期管理类，协调各模块工作。

### 属性

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    // 核心模块实例
    var eventMonitor: GlobalEventMonitor?       // 全局事件监听
    var speechRecognizer: SpeechRecognizer?     // 语音识别
    var floatingWindow: FloatingWindow?         // 浮动窗口
    var textInjector: TextInjector?             // 文本注入
    var llmRefiner: LLMRefiner?                 // LLM 润色
    var settingsWindow: SettingsWindow?         // 设置窗口
    var languageManager: LanguageManager        // 语言管理
    var statusItem: NSStatusItem?               // 菜单栏图标
    
    // 状态
    var isRecording: Bool                       // 是否正在录音
    var currentTranscription: String            // 当前识别文本
}
```

### 方法

#### applicationDidFinishLaunching

```swift
func applicationDidFinishLaunching(_ notification: Notification)
```

应用启动完成回调，初始化所有模块。

#### startRecording

```swift
func startRecording()
```

开始录音流程，显示浮动窗口，启动语音识别。

#### stopRecording

```swift
func stopRecording()
```

停止录音，获取识别结果，执行 LLM 润色（如启用），注入文本。

#### showFloatingWindow

```swift
func showFloatingWindow()
```

显示浮动录音窗口。

#### hideFloatingWindow

```swift
func hideFloatingWindow()
```

隐藏浮动窗口。

#### injectText

```swift
func injectText(_ text: String)
```

通过 TextInjector 将文本注入当前输入框。

**参数：**
- `text`: 要注入的文本

---

## GlobalEventMonitor

### 概述

全局键盘事件监听器，监听 Fn 键按下/释放。

### 初始化

```swift
init(callback: @escaping (Bool) -> Void)
```

**参数：**
- `callback`: 事件回调，参数为 `true` 表示按下，`false` 表示释放

### 方法

#### start

```swift
func start()
```

开始监听全局键盘事件。

#### stop

```swift
func stop()
```

停止监听。

### 使用示例

```swift
let monitor = GlobalEventMonitor { isPressed in
    if isPressed {
        print("Fn 键按下")
    } else {
        print("Fn 键释放")
    }
}
monitor.start()
```

---

## SpeechRecognizer

### 概述

语音识别管理器，处理音频录制和实时识别。

### 属性

```swift
class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    var onResult: ((String) -> Void)?       // 识别结果回调
    var onRMSUpdate: ((Float) -> Void)?     // RMS 更新回调
    var onError: ((Error) -> Void)?         // 错误回调
    var isRecording: Bool { get }           // 是否正在录音
}
```

### 方法

#### startRecording

```swift
func startRecording(language: String)
```

开始录音和识别。

**参数：**
- `language`: 语言代码（如 "zh-CN", "en-US"）

**错误：**
- `SpeechError.microphonePermissionDenied`: 麦克风权限被拒绝
- `SpeechError.recognitionPermissionDenied`: 语音识别权限被拒绝
- `SpeechError.alreadyRecording`: 已经在录音中

#### stopRecording

```swift
func stopRecording()
```

停止录音，返回最终识别结果。

---

## FloatingWindow

### 概述

胶囊形浮动窗口，显示录音状态和波形。

### 初始化

```swift
init()
```

### 属性

```swift
var waveformView: WaveformView { get }      // 波形视图
var statusLabel: NSTextField { get }        // 状态标签
```

### 方法

#### show

```swift
func show()
```

显示窗口，带动画效果。

#### hide

```swift
func hide()
```

隐藏窗口，带动画效果。

#### updateStatus

```swift
func updateStatus(_ text: String)
```

更新状态文本（如 "Listening...", "Processing..."）。

**参数：**
- `text`: 状态文本

#### setRMS

```swift
func setRMS(_ value: Float)
```

设置 RMS 值更新波形。

**参数：**
- `value`: RMS 值（0.0 - 1.0）

---

## WaveformView

### 概述

5 段波形动画视图。

### 初始化

```swift
init(frame: NSRect)
```

### 属性

```swift
var rmsValue: Float { get set }     // 当前 RMS 值（0.0 - 1.0）
var barCount: Int { get }           // 段数（默认 5）
var barColor: NSColor { get set }   // 波形颜色
```

### 方法

#### startAnimating

```swift
func startAnimating()
```

开始波形动画。

#### stopAnimating

```swift
func stopAnimating()
```

停止动画。

---

## TextInjector

### 概述

文本注入器，将文本粘贴到当前输入框。

### 初始化

```swift
init()
```

### 方法

#### inject

```swift
func inject(_ text: String) -> Bool
```

将文本注入当前焦点输入框。

**参数：**
- `text`: 要注入的文本

**返回：**
- `true`: 注入成功
- `false`: 注入失败

**注意：** 需要辅助功能权限。

#### injectWithPasteboard

```swift
func injectWithPasteboard(_ text: String) -> Bool
```

使用剪贴板方式注入文本（带 CJK 输入法处理）。

---

## LLMRefiner

### 概述

LLM 文本润色器。

### 初始化

```swift
init(baseURL: String, apiKey: String, model: String)
```

**参数：**
- `baseURL`: API 基础 URL（如 "https://api.openai.com/v1"）
- `apiKey`: API 密钥
- `model`: 模型名称（如 "gpt-4o-mini"）

### 属性

```swift
var isEnabled: Bool { get set }     // 是否启用
var timeout: TimeInterval { get set }  // 超时时间（默认 10 秒）
```

### 方法

#### refine

```swift
func refine(text: String, completion: @escaping (Result<String, Error>) -> Void)
```

对文本进行润色。

**参数：**
- `text`: 原始文本
- `completion`: 完成回调

**成功结果：** 润色后的文本

**错误类型：**
- `LLMError.notEnabled`: LLM 未启用
- `LLMError.invalidURL`: URL 无效
- `LLMError.invalidResponse`: 响应格式错误
- `LLMError.apiError(String)`: API 返回错误
- `LLMError.timeout`: 请求超时

### 使用示例

```swift
let refiner = LLMRefiner(
    baseURL: "https://api.openai.com/v1",
    apiKey: "sk-...",
    model: "gpt-4o-mini"
)
refiner.isEnabled = true

refiner.refine(text: "你好世介") { result in
    switch result {
    case .success(let refined):
        print("润色结果: \(refined)")
    case .failure(let error):
        print("润色失败: \(error)")
    }
}
```

---

## SettingsWindow

### 概述

设置窗口控制器。

### 初始化

```swift
init()
```

### 方法

#### show

```swift
func show()
```

显示设置窗口。

#### close

```swift
func close()
```

关闭设置窗口。

### 配置持久化

设置自动保存到 `UserDefaults`：

- `llmBaseURL`: API 基础 URL
- `llmAPIKey`: API 密钥
- `llmModel`: 模型名称
- `isLLMEnabled`: 是否启用 LLM

---

## LanguageManager

### 概述

语言管理器。

### 静态属性

```swift
static let availableLanguages: [Language]
```

支持的语言列表。

### 属性

```swift
var currentLanguage: Language { get set }
```

当前语言，修改后自动持久化。

### 方法

#### setLanguage

```swift
func setLanguage(id: String) -> Bool
```

通过 ID 设置语言。

**参数：**
- `id`: 语言 ID（如 "zh-Hans", "en"）

**返回：**
- `true`: 设置成功
- `false`: 语言 ID 无效

### Language 结构体

```swift
struct Language {
    let id: String        // 语言标识（如 "zh-Hans"）
    let name: String      // 显示名称（如 "简体中文"）
    let locale: String    // Locale 代码（如 "zh-CN"）
}
```

---

## Logger

### 概述

日志管理器，单例模式。

### 获取实例

```swift
Logger.shared
```

### 方法

#### log

```swift
func log(_ level: LogLevel, module: LogModule, message: String)
```

记录日志。

**参数：**
- `level`: 日志级别
- `module`: 模块名称
- `message`: 日志内容

#### debug

```swift
func debug(module: LogModule, message: String)
```

记录 DEBUG 级别日志。

#### info

```swift
func info(module: LogModule, message: String)
```

记录 INFO 级别日志。

#### warning

```swift
func warning(module: LogModule, message: String)
```

记录 WARN 级别日志。

#### error

```swift
func error(module: LogModule, message: String)
```

记录 ERROR 级别日志。

### 枚举

#### LogLevel

```swift
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}
```

#### LogModule

```swift
enum LogModule: String {
    case app = "App"
    case speech = "Speech"
    case input = "Input"
    case llm = "LLM"
    case ui = "UI"
    case event = "Event"
    case settings = "Settings"
}
```

### 使用示例

```swift
Logger.shared.info(module: .app, message: "应用启动")
Logger.shared.error(module: .speech, message: "识别失败: \(error)")
```

---

## 错误类型

### SpeechError

```swift
enum SpeechError: Error {
    case microphonePermissionDenied
    case recognitionPermissionDenied
    case alreadyRecording
    case notRecording
    case recognitionFailed(String)
}
```

### LLMError

```swift
enum LLMError: Error {
    case notEnabled
    case invalidURL
    case invalidResponse
    case apiError(String)
    case timeout
    case networkError(Error)
}
```

### InjectionError

```swift
enum InjectionError: Error {
    case accessibilityPermissionDenied
    case pasteboardFailure
    case simulationFailed
}
```