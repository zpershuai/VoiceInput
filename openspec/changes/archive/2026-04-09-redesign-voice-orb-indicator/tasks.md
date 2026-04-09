## 1. Define Orb Visual Contract

- [x] 1.1 Capture the target visual language for the orb in a dedicated effect description file
- [x] 1.2 Confirm idle, speaking, and peak-energy states with explicit color and motion expectations
- [x] 1.3 Define acceptable layout changes required to keep the indicator visually circular inside the capsule

## 2. Rework Indicator Rendering

- [x] 2.1 Replace the existing five-bar rendering model with a single orb-based rendering model
- [x] 2.2 Introduce layered visual elements for core sphere, internal energy, highlight, and glow
- [x] 2.3 Preserve smooth idle animation even when RMS input is near zero

## 3. Map Audio Energy to Orb Behavior

- [x] 3.1 Apply smoothed RMS input to internal motion intensity
- [x] 3.2 Map RMS ranges to a cool-to-hot color transition from blue through violet to red accents
- [x] 3.3 Add subtle scale or glow pulsing that increases with speaking intensity without breaking the circular silhouette

## 4. Integrate with Floating Window Layout

- [x] 4.1 Adjust the left indicator slot dimensions if needed so the orb reads as circular rather than compressed
- [x] 4.2 Keep the orb vertically centered with the transcript text block across all capsule states
- [x] 4.3 Verify that show, resize, and hide animations preserve the orb's visual stability

## 5. Manual Verification

- [ ] 5.1 Verify idle recording state shows a calm blue glass-like orb instead of five bars
- [ ] 5.2 Verify normal speaking causes visible internal motion and color warming without abrupt flicker
- [ ] 5.3 Verify louder speech drives stronger red accents, brighter glow, and stronger pulse
- [ ] 5.4 Verify the orb remains visually circular and premium-looking in default, expanded, and two-line capsule layouts
- [ ] 5.5 Verify the redesigned indicator does not regress transcript readability or floating window stability

(End of file - total 31 lines)
