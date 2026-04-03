# 故障排除

## 快速诊断

### 查看日志

```bash
# 实时查看日志
tail -f ~/Library/Logs/VoiceInput/voiceinput_$(date +%Y-%m-%d).log

# 查看错误
 grep "ERROR" ~/Library/Logs/VoiceInput/*.log
```

### 检查进程

```bash
# 查看是否运行
pgrep -x VoiceInput

# 强制退出
killall VoiceInput
```

---

## 常见问题

### 1. 应用无法启动

**现象**：双击应用图标无反应

**排查步骤**：

1. 检查日志
```bash
cat ~/Library/Logs/VoiceInput/voiceinput_*.log | tail -20
```

2. 检查崩溃报告
```bash
ls ~/Library/Logs/DiagnosticReports/ | grep VoiceInput
```

3. 从终端运行查看输出
```bash
/Volumes/VoiceInput/VoiceInput.app/Contents/MacOS/VoiceInput
```

**常见原因**：
- 缺少辅助功能权限
- 签名问题
- 依赖库缺失

---

### 2. 按住 Fn 键无反应

**现象**：按住 Fn 键不显示浮动窗口

**排查步骤**：

1. 检查应用是否运行
```bash
pgrep -x VoiceInput || echo "未运行"
```

2. 检查事件监听是否启动
查看日志中是否有 `[Event] 启动全局事件监听`

3. 检查 Fn 键事件
在日志中搜索 `[Event] Fn 键按下`

**可能原因**：
- CGEventTap 创建失败
- 其他应用占用了 Fn 键
- 系统设置中 Fn 键行为被修改

**解决方案**：
- 重启应用
- 检查系统设置 → 键盘 → 将 F1、F2 等键用作标准功能键
- 关闭可能冲突的应用（如 Karabiner、BetterTouchTool）

---

### 3. 无法录音

**现象**：按住 Fn 键后窗口显示，但没有波形动画

**排查步骤**：

1. 检查麦克风权限
```bash
# 查看麦克风权限状态
tccutil reset Microphone com.yourcompany.VoiceInput
```

2. 在系统设置中检查
系统设置 → 隐私与安全 → 麦克风 → 确保 VoiceInput 已启用

3. 检查语音识别权限
系统设置 → 隐私与安全 → 语音识别 → 确保 VoiceInput 已启用

4. 测试麦克风
```bash
# 使用 QuickTime 测试麦克风
open -a "QuickTime Player"
```

**可能原因**：
- 麦克风权限被拒绝
- 默认输入设备错误
- 其他应用占用麦克风

---

### 4. 识别结果不输入

**现象**：录音完成，但文本没有输入到当前应用

**排查步骤**：

1. 检查辅助功能权限
系统设置 → 隐私与安全 → 辅助功能 → 确保 VoiceInput 已启用

2. 查看日志中的错误
```bash
grep "Input" ~/Library/Logs/VoiceInput/*.log | grep "ERROR"
```

3. 测试剪贴板
手动复制一段文本，确认 Cmd+V 可以粘贴

4. 检查当前应用
某些应用（如终端）可能需要特殊的粘贴方式

**可能原因**：
- 辅助功能权限不足
- 当前应用不支持 Cmd+V
- 输入法切换失败
- 权限被拒绝

**解决方案**：
- 重新授权辅助功能权限（先移除再添加）
- 确保目标应用是前台应用
- 尝试在其他应用（如 TextEdit）中测试

---

### 5. LLM 润色不工作

**现象**：识别结果没有润色直接输入

**排查步骤**：

1. 检查是否启用
右键菜单 → LLM Refinement → 确保勾选 "Enable LLM Refinement"

2. 检查配置
右键菜单 → LLM Refinement → Settings → 确认 API 信息正确

3. 测试 API
```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o-mini", "messages": [{"role": "user", "content": "Hello"}]}'
```

4. 查看日志
```bash
grep "LLM" ~/Library/Logs/VoiceInput/*.log
```

**可能原因**：
- LLM 未启用
- API Key 无效
- 网络问题
- 超时

---

### 6. CJK 输入乱码

**现象**：使用中文输入法时，输入的文本出现乱码或重复

**排查步骤**：

1. 检查输入法切换
查看日志中 `[Input] 切换到 ASCII 输入源` 和 `[Input] 恢复输入源`

2. 手动测试
- 切换到 ABC 输入法
- 按住 Fn 说话
- 确认文本正常输入

**可能原因**：
- 输入法切换失败
- 切换时机不当
- 输入法缓存问题

**解决方案**：
- 确保系统有 ABC 输入法
- 在系统设置 → 键盘 → 输入源中添加 ABC
- 尝试手动切换到 ABC 后再使用

---

### 7. 波形动画卡顿

**现象**：录音时波形动画不流畅

**排查步骤**：

1. 检查 CPU 使用率
```bash
top -pid $(pgrep VoiceInput)
```

2. 检查日志更新频率
确认 RMS 更新日志是否连续

**可能原因**：
- CPU 负载过高
- 动画线程阻塞
- 音频缓冲区过大

**解决方案**：
- 关闭其他占用资源的应用
- 重启 VoiceInput
- 降低音频采样率（修改代码）

---

### 8. 应用崩溃

**现象**：应用意外退出

**排查步骤**：

1. 查看崩溃报告
```bash
open ~/Library/Logs/DiagnosticReports/
```

2. 查看最后日志
```bash
tail -50 ~/Library/Logs/VoiceInput/voiceinput_*.log
```

3. 识别崩溃位置
查看崩溃报告中的 `Crashed Thread` 和 `Backtrace`

**常见崩溃原因**：

| 崩溃位置 | 可能原因 | 解决方案 |
|---------|---------|---------|
| `main.swift` | AppDelegate 被释放 | 检查全局变量 |
| `LanguageManager.init` | 递归调用 | 修复初始化逻辑 |
| `CGEventTap` | 事件回调异常 | 添加异常处理 |
| `SpeechRecognizer` | 音频会话冲突 | 检查麦克风占用 |
| `TextInjector` | 权限问题 | 重新授权辅助功能 |

---

## 性能问题

### CPU 占用过高

**排查**：
```bash
# 查看 CPU 占用
ps -o pid,ppid,%cpu,%mem,command -p $(pgrep VoiceInput)
```

**可能原因**：
- 日志级别设置为 DEBUG 且频繁记录
- 波形动画过于复杂
- 音频处理频率过高

**解决方案**：
- 修改日志级别为 INFO
- 降低波形更新频率
- 检查是否有内存泄漏

### 内存泄漏

**排查**：
```bash
# 查看内存占用
ps -o pid,ppid,rss,vsz,command -p $(pgrep VoiceInput)
```

**常见泄漏点**：
- CGEventTap 未正确释放
- AVAudioEngine 未停止
- 回调闭包循环引用

---

## 权限问题

### 重置所有权限

```bash
# 重置辅助功能权限
tccutil reset Accessibility com.yourcompany.VoiceInput

# 重置麦克风权限
tccutil reset Microphone com.yourcompany.VoiceInput

# 重置语音识别权限
tccutil reset SpeechRecognition com.yourcompany.VoiceInput
```

### 手动添加权限

1. 打开系统设置 → 隐私与安全
2. 找到对应权限类别
3. 点击添加按钮，选择 VoiceInput.app

---

## 获取帮助

### 提供信息

报告问题时请提供：

1. **系统信息**
   - macOS 版本
   - Mac 型号
   - VoiceInput 版本

2. **日志文件**
   ```bash
   tar czvf voiceinput-logs.tar.gz ~/Library/Logs/VoiceInput/
   ```

3. **崩溃报告**（如有）
   ```bash
   cp ~/Library/Logs/DiagnosticReports/VoiceInput*.crash .
   ```

4. **复现步骤**
   - 详细描述问题
   - 提供稳定复现的方法

### 联系方式

- GitHub Issues: https://github.com/zpershuai/VoiceInput/issues
- 邮件：your-email@example.com

---

## 已知限制

1. **Fn 键冲突**：部分键盘或系统设置可能改变 Fn 键行为
2. **输入法兼容性**：某些第三方输入法可能无法正确切换
3. **应用兼容性**：部分应用（如远程桌面）可能无法接收文本注入
4. **LLM 延迟**：网络不佳时 LLM 润色可能有明显延迟
5. **长文本**：过长的语音可能导致识别失败

---

## 调试模式

启用详细日志：

```bash
# 设置环境变量运行
LOG_LEVEL=DEBUG /Applications/VoiceInput.app/Contents/MacOS/VoiceInput
```

或修改代码：

```swift
// Logger.swift
private let defaultLogLevel: LogLevel = .debug  // 改为 .debug
```