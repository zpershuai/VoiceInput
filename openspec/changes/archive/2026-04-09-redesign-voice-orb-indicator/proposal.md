## Why

当前浮窗左侧语音指示器仍然使用 5 个竖向条形点阵，虽然能表达音量变化，但视觉语言偏工具化，和已经收敛成单一胶囊表面的浮窗不完全匹配。用户希望把这一区域升级为更具质感的单体动画，例如类似 Siri 能量核心的表现，但保留本产品自己的玻璃球风格，并通过颜色从蓝到红的变化直接反馈说话强弱。

这个改动的目标不是单纯更换图标，而是把左侧语音反馈升级为一个持续存在、可呼吸、可升温的圆形动态体，让录音态 UI 看起来更完整、更高级，也更容易传达“正在聆听”和“声音强度”的状态。

## What Changes

- Replace the current five-bar waveform indicator with a single circular orb-style voice indicator inside the floating capsule
- Keep the orb in a stable glass-like resting state when audio input is idle instead of collapsing to discrete bars
- Map RMS intensity to color energy so the orb moves from cool blue tones toward hot red tones as the user speaks louder
- Use internal motion, glow, and pulse changes to express energy while keeping the overall orb silhouette visually circular and stable
- Introduce a dedicated effect description document so the visual behavior can be reviewed independently from the implementation design

## Capabilities

### New Capabilities
- `voice-orb-indicator`: Present recording activity as a circular glass-orb animation whose motion and color respond continuously to live RMS input

### Modified Capabilities
- `floating-window-capsule-layout`: May need minor sizing adjustments so the left indicator area can accommodate a near-circular orb without distorting the integrated capsule layout

## Impact

- **WaveformView.swift**: Will be redesigned or replaced to render an orb-style indicator instead of five vertical bars
- **FloatingWindow.swift**: May need left content sizing updates so the indicator area supports a visually circular orb
- **AppDelegate.swift**: Existing `onRMSUpdate` wiring should remain usable, but the rendering semantics will change from bar height to orb energy
- **User experience**: Recording state will feel more premium and expressive, with a clearer mapping between speaking intensity and visual feedback
- **Documentation**: A standalone effect description file will define the intended motion language, color mapping, and visual constraints
