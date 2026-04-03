## Context

`FloatingWindow` currently creates a borderless `NSPanel` with a `NSVisualEffectView` background, but the sizing model assumes a fixed-height text row and a single width-only expansion path. In practice, the first rendered frame can show a square-ish translucent backing area before the content settles, and longer text causes the content to look stacked inside a larger panel rather than integrated inside one capsule.

The approved target behavior is:
- one visible capsule only
- default compact width for short text
- horizontal growth first
- a taller two-line capsule only after width reaches its cap
- waveform and text block kept vertically centered together in every state

## Goals / Non-Goals

**Goals:**
- Eliminate the detached square/translucent backing effect from the visible UI
- Define a deterministic size model for default, expanded single-line, and two-line states
- Keep text and waveform aligned as one component during show, update, and resize animations
- Constrain long text to a maximum of two visible lines

**Non-Goals:**
- Redesign the waveform artwork itself
- Introduce scrolling, marquee, or more than two lines of transcript text
- Change app-level trigger behavior, recording state management, or transcription logic

## Decisions

### Decision 1: Treat the panel and the capsule as the same visible shape
**Choice:** Make the panel frame always match the capsule bounds, and keep the background effect view pinned to those exact bounds with matching corner radius.

**Rationale:**
- The current visual bug is fundamentally a geometry mismatch between the visible capsule concept and the backing view/panel frame seen during animation and resizing.
- Matching the panel frame to the rendered capsule removes the possibility of exposing a larger rectangular substrate.

**Alternatives considered:**
- Keep the larger panel and hide the mismatch with clipping: rejected because the bug can still surface during animation and makes sizing logic harder to reason about.
- Draw a custom capsule layer separate from the panel background: possible, but unnecessary for this scope.

### Decision 2: Model layout as discrete presentation states
**Choice:** Use three presentation states driven by text measurement: `defaultSingleLine`, `expandedSingleLine`, and `twoLine`.

**Rationale:**
- The user-defined behavior is stateful, not a continuous free-form layout.
- Explicit states make animation thresholds and vertical alignment rules simpler to implement and verify.

**Alternatives considered:**
- Use a single continuous auto-layout pass with no explicit states: rejected because it obscures when the control should widen versus become taller.

### Decision 3: Measure text against single-line and two-line constraints separately
**Choice:** First evaluate whether text fits within the default width, then whether it fits within the maximum single-line width, and only after that compute the two-line height-constrained result.

**Rationale:**
- This directly encodes the approved interaction rule: widen first, wrap second.
- Separate measurement paths avoid accidental early wrapping caused by label configuration.

**Alternatives considered:**
- Let `NSTextField` wrap automatically from the start: rejected because it can jump to a taller layout too early.

### Decision 4: Center the waveform against the text block, not a fixed row height
**Choice:** Replace the current fixed text height assumption with constraints or sizing logic that center the waveform relative to the actual text container in both one-line and two-line modes.

**Rationale:**
- The current text label uses a fixed height equal to the panel height, which makes the row visually brittle once the capsule height changes.
- Centering against the text block preserves the “single integrated capsule” feel.

**Alternatives considered:**
- Keep fixed-height label and tweak insets: rejected because it would still couple alignment to the old single-row geometry.

### Decision 5: Cap overflow at two lines with in-capsule truncation
**Choice:** Limit text to two lines and truncate in place within the capsule.

**Rationale:**
- This preserves the compact floating-control character of the UI.
- It matches the approved design direction and prevents the window from turning into a general transcript panel.

**Alternatives considered:**
- Allow three or more lines: rejected because it recreates the “panel” feeling the redesign is trying to remove.

## Risks / Trade-offs

- [Text measurement differs from actual label rendering] → Use the same font and paragraph settings for measurement and displayed label configuration
- [Switching line-break behavior may cause threshold jitter near the width cap] → Use explicit state thresholds and avoid resizing when the delta is negligible
- [Changing height could shift the window visually relative to the screen edge] → Define frame updates from a stable anchored position instead of blindly replacing the full frame
- [NSVisualEffectView corner rendering could still expose artifacts during animation] → Keep layer masking enabled and ensure the content view fills the panel bounds exactly

## Migration Plan

No migration is required. This is a local UI behavior change inside the existing floating transcription window.

## Open Questions

None. The visual behavior and overflow policy were confirmed during brainstorming.
