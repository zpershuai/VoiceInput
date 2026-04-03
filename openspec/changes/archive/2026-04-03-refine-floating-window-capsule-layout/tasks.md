## 1. Rework Capsule Geometry

- [x] 1.1 Audit `FloatingWindow` frame, content view, and background view sizing to identify the source of the detached square backing
- [x] 1.2 Refactor the panel/background view setup so the visible window bounds always match the capsule shape from the first frame
- [x] 1.3 Preserve the current visual material, border, and shadow while keeping the capsule as the only visible surface

## 2. Implement State-Based Sizing

- [x] 2.1 Introduce explicit layout states for default single-line, expanded single-line, and two-line capsule modes
- [x] 2.2 Add text measurement logic that widens the capsule before allowing it to become multi-line
- [x] 2.3 Add a capped two-line layout path with in-capsule truncation for overflow

## 3. Fix Integrated Content Alignment

- [x] 3.1 Update text label configuration so single-line and two-line modes use the correct line break and line count behavior
- [x] 3.2 Rework constraints or manual layout so waveform and text remain vertically centered together in every capsule state
- [x] 3.3 Verify the integrated layout visually during initial show, live transcription updates, and status text updates

## 4. Stabilize Resizing and Presentation

- [x] 4.1 Update resize calculations so width and height transitions keep the floating window spatially stable on screen
- [x] 4.2 Adjust entry and exit animations so they operate on the unified capsule geometry without exposing a rectangular backing
- [x] 4.3 Validate that state transitions do not jitter around threshold boundaries during rapid transcription updates

## 5. Manual Verification

- [x] 5.1 Verify first-show appearance presents a single capsule with no visible square base
- [x] 5.2 Verify short text stays centered in the default-width capsule
- [x] 5.3 Verify medium text expands width without wrapping
- [x] 5.4 Verify long text switches to a taller two-line capsule with centered waveform and text
- [x] 5.5 Verify text longer than two lines truncates inside the capsule without detached overflow UI
