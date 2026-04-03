# 开发指南

## 环境准备

### 系统要求

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- Git

### 克隆仓库

```bash
git clone git@github.com:zpershuai/VoiceInput.git
cd VoiceInput
```

## 构建

### 命令行构建

```bash
# 构建调试版本
swift build

# 构建发布版本
swift build -c release

# 或使用 Makefile
make build
```

### Xcode 构建

1. 打开 `Package.swift`
```bash
open Package.swift
```

2. 在 Xcode 中选择 `VoiceInput` scheme
3. 按 Cmd+R 运行

## 运行

### 从命令行

```bash
# 构建并运行
make run

# 或直接运行调试版本
.build/debug/VoiceInput
```

### 调试

由于应用需要辅助功能权限，直接运行二进制文件可能会遇到权限问题。建议：

1. 构建应用包
```bash
make build
```

2. 在 Finder 中打开 `.build/release/VoiceInput.app`
3. 右键 → 打开（首次需要确认）
4. 授予辅助功能权限

### 日志调试

实时查看日志：

```bash
# 查看今天日志
tail -f ~/Library/Logs/VoiceInput/voiceinput_$(date +%Y-%m-%d).log

# 查看所有日志
ls -la ~/Library/Logs/VoiceInput/
```

## 开发工作流

### 添加新语言

1. 编辑 `Sources/VoiceInput/LanguageManager.swift`：

```swift
static let availableLanguages: [Language] = [
    // 添加新语言
    Language(id: "fr", name: "Français", locale: "fr-FR"),
    // ...
]
```

2. 测试识别
3. 更新文档

### 修改 LLM 提示词

编辑 `Sources/VoiceInput/LLMRefiner.swift`：

```swift
private let systemPrompt = """
你的自定义提示词...
"""
```

### 调整 UI 样式

编辑 `Sources/VoiceInput/FloatingWindow.swift`：

```swift
// 修改尺寸
let windowHeight: CGFloat = 56  // 默认高度
let cornerRadius: CGFloat = 28  // 圆角半径

// 修改颜色
visualEffectView.material = .hudWindow  // 尝试其他材质
```

### 添加新日志模块

编辑 `Sources/VoiceInput/Logger.swift`：

```swift
enum LogModule: String, CaseIterable {
    // 添加新模块
    case network = "Network"
    // ...
}
```

## 调试技巧

### 1. 查看权限状态

```swift
// 麦克风权限
AVAudioSession.sharedInstance().requestRecordPermission { granted in
    print("麦克风权限: \(granted)")
}

// 语音识别权限
SFSpeechRecognizer.requestAuthorization { status in
    print("语音识别权限: \(status)")
}
```

### 2. 模拟识别结果

在 `SpeechRecognizer.swift` 中临时修改：

```swift
// 用于测试的模拟结果
func simulateResult(_ text: String) {
    onResult?(text)
}
```

### 3. 打印事件流

在 `GlobalEventMonitor.swift` 中添加：

```swift
callback: { proxy, type, event, refcon in
    print("Event type: \(type), flags: \(event.flags)")
    // ...
}
```

### 4. 检查剪贴板内容

```swift
if let content = NSPasteboard.general.string(forType: .string) {
    print("剪贴板内容: \(content)")
}
```

## 测试

### 手动测试清单

- [ ] 按住 Fn 键显示浮动窗口
- [ ] 说话后松开 Fn 键，文本正确输入
- [ ] 切换语言后识别正常
- [ ] LLM 润色功能正常工作
- [ ] 设置保存和加载正常
- [ ] 长时间录音（>30秒）不崩溃
- [ ] 快速连续按键不崩溃

### 测试 CJK 输入法

1. 切换到搜狗拼音/QQ拼音/系统拼音
2. 在文本编辑器中按住 Fn 说话
3. 确认文本正确输入，没有乱码

## 常见问题

### 编译错误：找不到 Speech 框架

确保在 `Package.swift` 中添加了：

```swift
.linkerSettings([
    .linkedFramework("Speech"),
    .linkedFramework("AVFoundation"),
])
```

### 运行时崩溃：信号 SIGSEGV

检查 `main.swift`：

```swift
// 确保使用全局变量
var appDelegate: AppDelegate?

// 不要这样：
// let delegate = AppDelegate()  // 会被立即释放
```

### 无法注入文本

检查辅助功能权限：

```bash
# 查看是否已授权
tccutil reset Accessibility com.yourcompany.VoiceInput

# 或在系统设置中手动添加
```

### 波形不显示

检查 `WaveformView` 是否正确初始化：

```swift
waveformView.frame = NSRect(x: 0, y: 0, width: 100, height: 40)
waveformView.autoresizingMask = [.width, .height]
```

## 发布

### 版本号管理

在 `Info.plist` 中更新：

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 代码签名

```bash
# 使用开发者证书签名
codesign --force --deep --sign "Developer ID Application: Your Name" \
    .build/release/VoiceInput.app

# 验证签名
codesign --verify --deep --strict .build/release/VoiceInput.app
```

### 打包 DMG

```bash
# 创建 DMG 脚本
mkdir -p build/dmg
cp -r .build/release/VoiceInput.app build/dmg/
create-dmg \
    --volname "VoiceInput Installer" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --app-drop-link 600 185 \
    "VoiceInput-1.0.0.dmg" \
    build/dmg/
```

## 贡献指南

### 提交规范

```
<type>: <subject>

<body>

<footer>
```

类型：
- `feat`: 新功能
- `fix`: 修复
- `docs`: 文档
- `style`: 格式
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建

### 示例

```
feat: 添加日语支持

- 在 LanguageManager 添加日语
- 更新语言菜单
- 添加日语系统提示词

Closes #12
```

## 参考资源

- [Apple Speech Framework](https://developer.apple.com/documentation/speech)
- [Core Graphics Event Tap](https://developer.apple.com/documentation/coregraphics/cgeventtap)
- [Text Input Sources](https://developer.apple.com/documentation/coreservices/text_input_source_services)
- [OpenAI API](https://platform.openai.com/docs/api-reference)