# 详细设计文档

## 1. AppDelegate

### 职责
应用生命周期管理，协调各模块工作，维护全局状态。

### 关键设计决策

#### 1.1 全局变量模式
```swift
var appDelegate: AppDelegate?

@main
struct VoiceInputApp {
    static func main() {
        let app = NSApplication.shared
        appDelegate = AppDelegate()  // 全局保持
        app.delegate = appDelegate
        app.run()
    }
}
```

**原因**: `NSApplication.delegate` 是弱引用，使用局部变量会导致立即释放。

#### 1.2 状态机
```
Idle → Recording → Processing → Idle
```

### 接口

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    // 核心模块
    var eventMonitor: GlobalEventMonitor?
    var speechRecognizer: SpeechRecognizer?
    var floatingWindow: FloatingWindow?
    var statusItem: NSStatusItem?
    
    // 状态
    var isRecording: Bool
    var currentLanguage: String
    
    // 方法
    func startRecording()
    func stopRecording()
    func showFloatingWindow()
    func hideFloatingWindow()
    func injectText(_ text: String)
}
```

---

## 2. GlobalEventMonitor

### 职责
监听全局 Fn 键事件，支持键按下和释放检测。

### 技术实现

使用 `CGEvent.tapCreate` 创建全局事件钩子：

```swift
let eventMask = (1 << CGEventType.flagsChanged.rawValue)
let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(eventMask),
    callback: { ... },
    userInfo: ...
)
```

### Fn 键检测逻辑

```swift
let flags = event.flags
let isFnPressed = flags.contains(.maskSecondaryFn)
```

**注意**: 需要抑制 Fn 键的默认行为（表情符号选择器）。

### 事件抑制

```swift
event.type = .null  // 阻止事件传播
return Unmanaged.passUnretained(event)
```

---

## 3. SpeechRecognizer

### 职责
音频录制、语音识别、实时音量监测。

### 架构

```
AVAudioEngine → SFSpeechRecognizer → 实时结果回调
       │
       ▼
   RMS 计算 → 更新 WaveformView
```

### 关键类

```swift
class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    // 音频
    var audioEngine: AVAudioEngine
    var inputNode: AVAudioInputNode
    
    // 识别
    var speechRecognizer: SFSpeechRecognizer
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest
    var recognitionTask: SFSpeechRecognitionTask
    
    // 回调
    var onResult: ((String) -> Void)?
    var onRMSUpdate: ((Float) -> Void)?
    
    // 方法
    func startRecording(language: String)
    func stopRecording()
    func calculateRMS(buffer: AVAudioPCMBuffer) -> Float
}
```

### RMS 计算

```swift
func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
    guard let channelData = buffer.floatChannelData?[0] else { return 0 }
    let frameLength = Int(buffer.frameLength)
    
    var sum: Float = 0
    for i in 0..<frameLength {
        sum += channelData[i] * channelData[i]
    }
    
    let rms = sqrt(sum / Float(frameLength))
    return rms  // 范围 0.0 - 1.0
}
```

---

## 4. FloatingWindow

### 职责
显示胶囊形浮动窗口，展示录音状态和波形动画。

### 设计规格

| 属性 | 值 |
|------|-----|
| 高度 | 56px |
| 圆角 | 28px |
| 样式 | HUD 风格 |
| 背景 | 半透明模糊 |
| 位置 | 屏幕顶部居中 |

### 实现

使用 `NSPanel` + `NSVisualEffectView`：

```swift
class FloatingWindow: NSPanel {
    // 配置
    styleMask = [.borderless, .nonactivatingPanel]
    level = .floating
    backgroundColor = .clear
    isOpaque = false
    hasShadow = true
    
    // 视觉效果
    let visualEffectView = NSVisualEffectView()
    visualEffectView.material = .hudWindow
    visualEffectView.state = .active
    visualEffectView.wantsLayer = true
    visualEffectView.layer?.cornerRadius = 28
}
```

### 动画

使用 `CASpringAnimation` 实现弹性效果：

```swift
let animation = CASpringAnimation(keyPath: "transform.scale")
animation.initialVelocity = 0
animation.mass = 1
animation.stiffness = 200
animation.damping = 15
```

---

## 5. WaveformView

### 职责
显示 5 段音频波形动画，基于 RMS 值驱动。

### 设计

```
┌─────────────────────────────────────┐
│  ▓▓  ▓▓▓  ▓▓▓▓  ▓▓▓  ▓▓            │
│  ▓▓  ▓▓▓  ▓▓▓▓  ▓▓▓  ▓▓    识别中... │
│  ▓▓  ▓▓▓  ▓▓▓▓  ▓▓▓  ▓▓            │
└─────────────────────────────────────┘
   ↑    ↑    ↑    ↑    ↑
  Bar1 Bar2 Bar3 Bar4 Bar5
```

### 实现

```swift
class WaveformView: NSView {
    var bars: [NSView] = []
    var rmsValue: Float = 0 {
        didSet { updateBars() }
    }
    
    func setupBars() {
        for i in 0..<5 {
            let bar = NSView()
            bar.wantsLayer = true
            bar.layer?.backgroundColor = NSColor.white.cgColor
            bar.layer?.cornerRadius = 2
            bars.append(bar)
        }
    }
    
    func updateBars() {
        // 基于 RMS 值计算每段高度
        // 添加相位差创造波浪效果
        let baseHeight = CGFloat(rmsValue) * maxHeight
        for (i, bar) in bars.enumerated() {
            let phase = sin(Date().timeIntervalSince1970 * 10 + Double(i))
            let height = baseHeight * CGFloat(0.5 + 0.5 * phase)
            bar.frame.size.height = max(4, height)
        }
    }
}
```

---

## 6. TextInjector

### 职责
将文本注入到当前输入框，处理 CJK 输入法兼容性。

### CJK 输入法问题

当使用中文/日文/韩文输入法时，直接模拟按键可能导致：
- 字符被输入法拦截
- 输入异常

### 解决方案

```swift
class TextInjector {
    func injectText(_ text: String) {
        // 1. 检测当前输入法
        let isCJK = isCJKInputMethodActive()
        
        // 2. 如果是 CJK，临时切换到 ABC
        if isCJK {
            switchToASCIIInputMethod()
        }
        
        // 3. 复制到剪贴板
        copyToClipboard(text)
        
        // 4. 模拟 Cmd+V
        simulatePaste()
        
        // 5. 恢复原输入法
        if isCJK {
            restoreInputMethod()
        }
    }
    
    func isCJKInputMethodActive() -> Bool {
        // 使用 TIS 检测当前输入法
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        let id = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
        let inputMethodID = Unmanaged<CFString>.fromOpaque(id!).takeUnretainedValue() as String
        
        return inputMethodID.contains("com.apple.inputmethod.SCIM") ||
               inputMethodID.contains("com.apple.inputmethod.Kotoeri") ||
               inputMethodID.contains("com.apple.inputmethod.Korean")
    }
}
```

---

## 7. LLMRefiner

### 职责
调用 LLM API 对识别结果进行润色。

### API 格式

支持 OpenAI 兼容的 API：

```
POST {baseURL}/chat/completions
Content-Type: application/json
Authorization: Bearer {apiKey}

{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "You are a text refinement assistant..."
    },
    {
      "role": "user",
      "content": "原始文本"
    }
  ],
  "temperature": 0.3
}
```

### 系统提示词

```swift
let systemPrompt = """
You are a text refinement assistant. Your task is to improve the clarity and readability of transcribed speech text while preserving the original meaning.

Guidelines:
1. Fix obvious speech recognition errors
2. Add proper punctuation
3. Improve sentence structure if needed
4. Keep the original language
5. Do not add new information
6. Keep it concise

Input: Speech transcription that may contain errors
Output: Refined text only, no explanations
"""
```

### 实现

```swift
class LLMRefiner {
    var baseURL: String
    var apiKey: String
    var model: String
    var isEnabled: Bool
    
    func refine(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard isEnabled else {
            completion(.success(text))
            return
        }
        
        // 构建请求
        let request = buildRequest(text: text)
        
        // 发送请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            // 解析响应
            // 返回润色后的文本
        }
    }
}
```

---

## 8. SettingsWindow

### 职责
提供 LLM 配置界面，支持输入 API 信息。

### 界面布局

```
┌─────────────────────────────────────────┐
│         LLM Refinement Settings         │
├─────────────────────────────────────────┤
│  [✓] Enable LLM Refinement              │
│                                         │
│  API Base URL:                          │
│  ┌─────────────────────────────────┐    │
│  │ https://api.openai.com/v1       │    │
│  └─────────────────────────────────┘    │
│                                         │
│  API Key:                               │
│  ┌─────────────────────────────────┐    │
│  │ ••••••••••••••••••••••••••     │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Model:                                 │
│  ┌─────────────────────────────────┐    │
│  │ gpt-4o-mini                     │    │
│  └─────────────────────────────────┘    │
│                                         │
│        [Save]          [Cancel]         │
└─────────────────────────────────────────┘
```

### 配置持久化

使用 `UserDefaults`：

```swift
extension UserDefaults {
    var llmBaseURL: String? {
        get { string(forKey: "llmBaseURL") }
        set { set(newValue, forKey: "llmBaseURL") }
    }
    
    var llmAPIKey: String? {
        get { string(forKey: "llmAPIKey") }
        set { set(newValue, forKey: "llmAPIKey") }
    }
    
    var llmModel: String? {
        get { string(forKey: "llmModel") }
        set { set(newValue, forKey: "llmModel") }
    }
    
    var isLLMEnabled: Bool {
        get { bool(forKey: "isLLMEnabled") }
        set { set(newValue, forKey: "isLLMEnabled") }
    }
}
```

---

## 9. LanguageManager

### 职责
管理支持的语言列表，处理语言切换。

### 语言列表

| 语言 | 代码 | Apple Locale |
|------|------|--------------|
| English | en | en-US |
| 简体中文 | zh-Hans | zh-CN |
| 繁體中文 | zh-Hant | zh-TW |
| 日本語 | ja | ja-JP |
| 한국어 | ko | ko-KR |

### 实现

```swift
struct Language: Identifiable {
    let id: String
    let name: String
    let locale: String
}

class LanguageManager {
    static let availableLanguages: [Language] = [
        Language(id: "zh-Hans", name: "简体中文", locale: "zh-CN"),
        Language(id: "en", name: "English", locale: "en-US"),
        Language(id: "zh-Hant", name: "繁體中文", locale: "zh-TW"),
        Language(id: "ja", name: "日本語", locale: "ja-JP"),
        Language(id: "ko", name: "한국어", locale: "ko-KR")
    ]
    
    var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.id, forKey: "currentLanguage")
        }
    }
    
    init() {
        let savedID = UserDefaults.standard.string(forKey: "currentLanguage") ?? "zh-Hans"
        currentLanguage = Self.availableLanguages.first { $0.id == savedID } 
            ?? Self.availableLanguages[0]
    }
}
```

---

## 10. Logger

### 职责
提供模块化的日志系统，支持分级和文件持久化。

### 日志级别

```swift
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}
```

### 模块分类

```swift
enum LogModule: String, CaseIterable {
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
Logger.shared.log(.info, module: .speech, message: "开始语音识别")
Logger.shared.log(.error, module: .input, message: "文本注入失败: \(error)")
```

### 输出格式

```
[2025-04-03 14:30:25.123] [INFO] [Speech] 开始语音识别
[2025-04-03 14:30:26.456] [DEBUG] [UI] 显示浮动窗口
[2025-04-03 14:30:28.789] [INFO] [Speech] 识别结果: "你好世界"
```

### 文件管理

- 路径: `~/Library/Logs/VoiceInput/`
- 命名: `voiceinput_YYYY-MM-DD.log`
- 保留: 最近 7 天
- 最大: 单文件 10MB