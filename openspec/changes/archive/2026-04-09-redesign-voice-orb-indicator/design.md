## Context

The current recording indicator is implemented as `WaveformView`, a compact five-bar animation driven by live RMS updates. This achieves basic responsiveness but produces a utilitarian equalizer look. The surrounding floating window has already been refined into a single integrated capsule, so the remaining mismatch is that the left-side voice indicator still reads as a generic meter rather than a premium listening state.

The approved direction is:
- one circular orb instead of five discrete bars
- a default idle state that still feels alive
- a glass-like, fluid energy aesthetic rather than a literal equalizer
- RMS-driven color and motion intensity
- a stable circular silhouette that does not visibly deform into an irregular blob

## Goals / Non-Goals

**Goals:**
- Replace the current bar-based indicator with a single orb-style visual language
- Keep the orb readable at the current floating window scale while preserving a circular impression
- Express voice intensity through both color temperature and motion energy
- Preserve the existing RMS input pipeline so the change remains localized to floating-window presentation
- Document the effect separately so visual review can happen without scanning implementation details

**Non-Goals:**
- Recreate Siri exactly or clone Apple-specific artwork
- Introduce a heavy rendering stack such as Metal shaders unless later validation proves Core Animation insufficient
- Change recording triggers, speech recognition behavior, or transcript update logic
- Turn the floating window into a large freeform visualizer

## Decisions

### Decision 1: Keep one stable circular silhouette
**Choice:** The orb should keep an externally stable circular outline, with expressiveness carried by internal flow, glow, and subtle scale pulsing rather than by large contour deformation.

**Rationale:**
- The floating capsule already contains transcript text on the right, so a violently deforming indicator would make the whole control feel noisy.
- A stable outline reads as a designed object, while internal animation carries the “living” quality.

**Alternatives considered:**
- Organic blob deformation: rejected because it risks looking unstable and pulling too much attention from the transcript text.
- Static circle with color-only changes: rejected because it would not sufficiently communicate live audio energy.

### Decision 2: Express energy through layered motion, not bar geometry
**Choice:** The orb should be built from layered visual components such as base sphere, inner fluid glow, highlight, and outer aura, each reacting differently to the same RMS input.

**Rationale:**
- The current bar view encodes energy through geometry height only. The new orb needs richer expression without becoming visually chaotic.
- Layered motion allows calm idle behavior and stronger speaking behavior while remaining legible at small sizes.

**Alternatives considered:**
- Single solid fill color with scale pulse: rejected because it would feel flat and toy-like.
- Direct translation of bars into radial segments: rejected because it preserves the meter metaphor instead of introducing a new one.

### Decision 3: Use a cool-to-hot color ramp tied to smoothed RMS
**Choice:** Map low RMS to blue/cyan tones, mid RMS to violet/magenta, and high RMS to orange-red or red accents, using smoothing to avoid abrupt flicker.

**Rationale:**
- The user explicitly wants the orb to become redder as voice intensity increases.
- A staged cool-to-hot ramp feels like energy building up rather than a binary state switch.

**Alternatives considered:**
- Blue-only intensity variation: rejected because it weakens loudness readability.
- Immediate blue-to-red hard switch: rejected because it would feel alarm-like and visually cheap.

### Decision 4: Keep the existing RMS pipeline and reinterpret it visually
**Choice:** Continue using the current `onRMSUpdate -> waveform.updateRMS(rms)` integration, but reinterpret the RMS value as orb energy rather than bar height.

**Rationale:**
- The speech pipeline already emits a continuous RMS value and is isolated from the rendering layer.
- This keeps scope focused and avoids touching unrelated recording logic.

**Alternatives considered:**
- Introduce a richer audio analysis pipeline with spectral bands: rejected for this scope because the design does not require frequency analysis.

### Decision 5: Separate effect intent from engineering design
**Choice:** Add a standalone `effect.md` file inside the change to capture appearance, motion language, and RMS-to-color behavior independently of proposal/design/spec content.

**Rationale:**
- The user explicitly asked for a separate file to describe the effect.
- Visual review often needs a more art-directed description than a standard engineering design document provides.

**Alternatives considered:**
- Fold the effect description into `design.md`: rejected because it mixes product intent with implementation structure.

## Risks / Trade-offs

- [Small rendering area limits richness] → Slightly increase or rebalance the left indicator area so the orb can read as circular rather than squeezed
- [Color transitions may look noisy with raw RMS] → Reuse or extend smoothing behavior before mapping to hue and glow intensity
- [Overly aggressive red states may feel like warning/error] → Treat red as a peak-energy accent layered over the core blue family, not as a permanent flat fill
- [Glass effects may become muddy on translucent backgrounds] → Define highlight, contrast, and alpha values against the existing floating capsule material
- [Core Animation may not achieve the exact desired fluidity] → Start with layered Core Animation; escalate to a more advanced rendering approach only if visual validation fails

## Migration Plan

No data or settings migration is required. This is a local visual behavior change to the recording indicator and adjacent floating-window layout.

## Open Questions

None for proposal stage. The requested direction is specific enough to define a concrete visual contract.
