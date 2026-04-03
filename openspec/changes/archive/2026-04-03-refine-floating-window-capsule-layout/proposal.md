## Why

`FloatingWindow` 目前首次展示和文本扩展时会暴露一个与胶囊分离的半透明方形底板，导致胶囊、文本和背景容器在视觉上脱节。这个问题已经直接影响核心录音态 UI 的稳定感，需要把浮窗收敛成单一胶囊组件，并明确单行到双行时的扩展规则。

## What Changes

- Redesign the floating transcription window as a single capsule surface instead of a capsule layered over a larger translucent panel
- Fix the initial presentation geometry so the visible shape, hit area, and animated frame are aligned from the first frame
- Keep waveform and text vertically centered as one integrated content block in both single-line and multi-line states
- Introduce a predictable sizing behavior: start at a default width, grow horizontally up to a cap, then grow taller to support exactly two lines
- Remove the current detached second-row ellipsis layout so overflow remains visually contained within the capsule

## Capabilities

### New Capabilities
- `floating-window-capsule-layout`: Present the voice input floating window as a single capsule that expands smoothly from default width to a two-line integrated layout

### Modified Capabilities
<!-- No existing capabilities modified - this change introduces a new UI behavior contract -->

## Impact

- **FloatingWindow.swift**: Primary layout, sizing, and animation logic will be reworked
- **WaveformView.swift**: May need minor alignment validation to keep visual centering consistent inside the capsule
- **AppDelegate.swift**: No behavioral change expected, but window show/update timing should continue to work with the new sizing model
- **User experience**: The recording/transcription window will appear as a single stable control rather than a capsule layered over a square panel
