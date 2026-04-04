# 故障排除

本文档将常见故障症状映射到可能的原因模块、所需权限、相关日志模块和源码文件，使问题定位有固定入口。

## 快速诊断

### 查看日志

```bash
# 实时查看今天的日志
tail -f ~/Library/Logs/VoiceInput/voiceinput_$(date +%Y-%m-%d).log

# 只看错误
grep "ERROR" ~/Library/Logs/VoiceInput/*.log

# 按模块过滤
grep "\[App\]" ~/Library/Logs/VoiceInput/*.log | tail -20
grep "\[Speech\]" ~/Library/Logs/VoiceInput/*.log | tail -20
grep "\[Input\]" ~/Library/Logs/VoiceInput/*.log | tail -20
grep "\[LLM\]" ~/Library/Logs/VoiceInput/*.log | tail -20
grep "\[Event\]" ~/Library/Logs/VoiceInput/*.log | tail -20
```

### 检查进程

```bash
# 查看是否运行
pgrep -x VoiceInput

# 强制退出
killall VoiceInput
```

---

## 症状 → 模块 → 日志映射表

| 症状 | 可能模块 | 日志模块 | 所需权限 | 源码文件 |
|------|---------|---------|---------|---------|
| 按住快捷键无反应 | GlobalEventMonitor | Event | 辅助功能 | GlobalEventMonitor.swift |
| 窗口显示但无波形 | SpeechRecognizer | Speech | 麦克风、语音识别 | SpeechRecognizer.swift |
| 识别结果不准确 | SpeechRecognizer | Speech | 麦克风 | SpeechRecognizer.swift |
| 文本未注入 | TextInjector | Input | 辅助功能 | TextInjector.swift |
| LLM 润色不生效 | LLMRefiner | LLM | 网络 | LLMRefiner.swift |
| 设置不保存 | SettingsWindow | Settings | 无 | SettingsWindow.swift |
| 应用无法启动 | AppDelegate | App | 辅助功能 | AppDelegate.swift |
| 语言切换无效 | LanguageManager | Settings | 无 | LanguageManager.swift |
| 窗口动画卡顿 | FloatingWindow | UI | 无 | FloatingWindow.swift |

---

## 详细排障路径

### 1. 按住快捷键无反应

**症状**: 按住快捷键（默认 Fn）不显示浮动窗口

**诊断路径**:

```
1. 检查应用是否运行
   pgrep -x VoiceInput
   └── 未运行 → 启动应用

2. 检查辅助功能权限
   系统设置 → 隐私与安全 → 辅助功能 → VoiceInput 是否启用
   └── 未启用 → 启用后重启应用

3. 查看 Event 日志
   grep "\[Event\]" ~/Library/Logs/VoiceInput/*.log | tail -20
   ├── 无日志输出 → 事件监听未启动 → 检查 AppDelegate 初始化
   ├── "Failed to create event tap" → CGEventTap 创建失败 → 权限问题
   └── "Event tap started" → 监听已启动 → 检查快捷键配置

4. 检查快捷键配置
   打开 Settings → Keyboard Shortcut → 确认快捷键设置
   └── 重置为默认 → Reset to Default 按钮

5. 排查冲突
   └── 关闭 Karabiner、BetterTouchTool 等可能占用事件的应用
```

**关键日志关键词**: `Event tap started`, `Failed to create event tap`, `Fn key pressed`

**相关文档**: [运行工作流](workflow.md) §3, [架构与模块](architecture.md) §GlobalEventMonitor

---

### 2. 窗口显示但无波形动画

**症状**: 按住快捷键后浮动窗口出现，但波形区域无动画

**诊断路径**:

```
1. 查看 Speech 日志
   grep "\[Speech\]" ~/Library/Logs/VoiceInput/*.log | tail -20
   ├── "Failed to start recording" → 权限或设备问题
   ├── "SpeechRecognizer error" → 识别引擎错误
   └── 无 Speech 日志 → startRecording 未被调用

2. 检查麦克风权限
   系统设置 → 隐私与安全 → 麦克风 → VoiceInput 是否启用

3. 检查语音识别权限
   系统设置 → 隐私与安全 → 语音识别 → VoiceInput 是否启用

4. 测试麦克风
   系统设置 → 声音 → 输入 → 对着麦克风说话，观察输入电平
```

**关键日志关键词**: `Recording started`, `notAuthorized`, `recognizerUnavailable`

**相关文档**: [运行工作流](workflow.md) §4, [架构与模块](architecture.md) §SpeechRecognizer

---

### 3. 识别结果不输入到应用

**症状**: 录音完成，松开快捷键后文本没有出现在当前输入框

**诊断路径**:

```
1. 查看 Input 日志
   grep "\[Input\]" ~/Library/Logs/VoiceInput/*.log | tail -20
   ├── "Text injection successful" → 注入成功但目标应用未接收
   ├── "Text injection failed" → CGEvent 注入失败
   └── 无 Input 日志 → 识别文本为空，未进入注入流程

2. 检查辅助功能权限
   系统设置 → 隐私与安全 → 辅助功能 → VoiceInput 是否启用
   └── 尝试：先移除再重新添加

3. 测试目标应用
   └── 在 TextEdit 中测试 → 如果正常 → 目标应用兼容性问题

4. 查看完整流程日志
   grep -E "\[(Speech|LLM|Input)\]" ~/Library/Logs/VoiceInput/*.log | tail -30
   ├── 有识别结果但无注入 → 检查 stopRecordingAndInject 流程
   ├── 有 LLM 错误 → 润色失败，应 fallback 到原文
   └── 无识别结果 → 回到问题 2 排查
```

**关键日志关键词**: `Text injection successful`, `Text injection failed`, `Captured text`

**相关文档**: [运行工作流](workflow.md) §7, [架构与模块](architecture.md) §TextInjector

---

### 4. LLM 润色不工作

**症状**: 识别结果没有经过润色直接输入

**诊断路径**:

```
1. 检查 LLM 是否启用
   右键菜单栏 → 确认 "Enable LLM Refinement" 已勾选

2. 检查 LLM 配置
   右键菜单栏 → Settings → LLM Refinement 区域
   ├── API Base URL 非空
   ├── API Key 非空
   └── Model 已设置

3. 查看 LLM 日志
   grep "\[LLM\]" ~/Library/Logs/VoiceInput/*.log | tail -20
   ├── "LLM refinement skipped" → 未启用或未配置
   ├── "LLM refinement failed" → API 请求失败
   ├── "LLM request failed with HTTP" → 网络或认证错误
   └── "LLM refinement completed successfully" → 润色成功

4. 测试 API 连接
   Settings → Test 按钮
   └── 失败 → 检查 URL、Key、Model 是否正确

5. 手动测试 API
   curl -s https://api.openai.com/v1/chat/completions \
     -H "Authorization: Bearer YOUR_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hi"}]}'
```

**关键日志关键词**: `LLM refinement skipped`, `LLM request failed`, `LLM refinement completed successfully`

**相关文档**: [运行工作流](workflow.md) §6, [架构与模块](architecture.md) §LLMRefiner

---

### 5. 应用无法启动

**症状**: 双击应用图标无反应

**诊断路径**:

```
1. 检查进程
   pgrep -x VoiceInput
   └── 已运行 → 菜单栏应显示麦克风图标 → 可能被其他窗口遮挡

2. 查看 App 日志
   grep "\[App\]" ~/Library/Logs/VoiceInput/*.log | tail -20
   ├── "Application launched successfully" → 启动成功
   ├── "Accessibility permission missing" → 权限弹窗应出现
   └── 无日志 → 应用未正常启动

3. 从终端运行
   .build/debug/VoiceInput
   └── 观察控制台输出

4. 检查崩溃报告
   ls ~/Library/Logs/DiagnosticReports/ | grep VoiceInput
```

**关键日志关键词**: `Application launching`, `Application launched successfully`, `Accessibility permission`

**相关文档**: [运行工作流](workflow.md) §1-2, [架构与模块](architecture.md) §AppDelegate

---

### 6. 语言切换无效

**症状**: 菜单栏切换语言后，识别语言未改变

**诊断路径**:

```
1. 查看 Settings 日志
   grep "\[Settings\]" ~/Library/Logs/VoiceInput/*.log | tail -10
   └── "Language changed to: xx-XX" → 切换已记录

2. 确认语言已勾选
   菜单栏 → Language → 确认目标语言前有勾选标记

3. 测试识别
   按住快捷键说话 → 观察识别结果是否为目标语言
```

**关键日志关键词**: `Language changed to`, `Applied shortcut`

**相关文档**: [架构与模块](architecture.md) §LanguageManager

---

### 7. 应用崩溃

**症状**: 应用意外退出

**诊断路径**:

```
1. 查看崩溃报告
   open ~/Library/Logs/DiagnosticReports/
   └── 查找 VoiceInput_*.crash

2. 查看最后日志
   tail -50 ~/Library/Logs/VoiceInput/voiceinput_$(date +%Y-%m-%d).log

3. 常见崩溃原因
```

| 崩溃位置 | 可能原因 | 解决方案 |
|---------|---------|---------|
| AppDelegate 初始化 | 组件初始化失败 | 检查权限和系统依赖 |
| GlobalEventMonitor | CGEventTap 创建失败 | 重新授权辅助功能 |
| SpeechRecognizer | 音频会话冲突 | 关闭其他使用麦克风的应用 |
| FloatingWindow | UI 线程问题 | 确保 UI 操作在主线程 |

---

## 权限问题

### 权限清单

| 权限 | 用途 | 请求时机 | 失败影响 |
|------|------|---------|---------|
| 辅助功能 (Accessibility) | 全局快捷键监听、文本注入 | 启动时 | 核心功能不可用 |
| 麦克风 (Microphone) | 音频录制 | 首次录音 | 无法录音 |
| 语音识别 (Speech Recognition) | Apple 语音识别 | 首次录音 | 无法识别 |

### 手动添加权限

1. 打开系统设置 → 隐私与安全
2. 找到对应权限类别（辅助功能、麦克风、语音识别）
3. 点击 + 添加 VoiceInput.app

---

## 获取帮助

### 提供信息

报告问题时请提供：

1. **系统信息**: macOS 版本、Mac 型号
2. **日志文件**: `tar czvf voiceinput-logs.tar.gz ~/Library/Logs/VoiceInput/`
3. **崩溃报告**（如有）: `~/Library/Logs/DiagnosticReports/VoiceInput*.crash`
4. **复现步骤**: 详细描述问题和稳定复现方法

### 联系方式

- GitHub Issues: https://github.com/zpershuai/VoiceInput/issues

---

## 文档维护规则

本文档是 VoiceInput 文档体系的一部分。以下规则确保文档与源码长期一致。

### 变更触发矩阵

| 变更类型 | 必须更新的文档 |
|---------|--------------|
| 新增用户可见功能 | `README.md` 能力摘要 + 对应深度文档 |
| 修改核心运行链路 | [运行工作流](workflow.md) |
| 新增/修改模块职责 | [架构与模块](architecture.md) |
| 新增日志模块或修改日志行为 | [架构与模块](architecture.md) §Logger + 本文件 |
| 新增权限依赖 | 本文件 §权限清单 + [运行工作流](workflow.md) |
| 修改快捷键默认值 | [运行工作流](workflow.md) §3 |
| 新增/修改 LLM 配置 | [架构与模块](architecture.md) §LLMRefiner |
| 新增已知问题或限制 | 本文件 |

### 维护检查清单

每次代码变更后检查：

- [ ] 运行工作流是否仍然准确（新增/删除步骤）
- [ ] 模块职责是否变化（新增/合并/拆分文件）
- [ ] 回调关系是否更新（新增/删除回调）
- [ ] 排障路径是否有效（症状是否仍然可能出现）
- [ ] README.md 的能力摘要是否需要更新

### 文档分层职责

| 文档 | 职责 | 更新频率 |
|------|------|---------|
| `README.md` | 项目入口、快速开始、能力摘要 | 新增功能时 |
| `docs/README.md` | 文档导航、按目标组织 | 新增文档时 |
| `docs/workflow.md` | 端到端运行时流程 | 工作流变更时 |
| `docs/architecture.md` | 模块边界、回调、数据流 | 架构变更时 |
| `docs/troubleshooting.md` | 症状→模块→日志映射 | 新增故障模式时 |
| `docs/development-guide.md` | 开发环境、构建、调试 | 工具链变更时 |
