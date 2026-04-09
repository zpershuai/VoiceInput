import AppKit

/// A circular voice orb that follows the "Canvas Fluid Gradient + Pulse" effect.
public final class VoiceOrbView: NSView {

    // MARK: - Constants

    private static let attackCoefficient: CGFloat = 0.18
    private static let releaseCoefficient: CGFloat = 0.08
    private static let timerInterval: TimeInterval = 1.0 / 30.0

    // MARK: - State

    private var displayLinkTimer: Timer?
    private var displayedEnergy: CGFloat = 0.0
    private var targetEnergy: CGFloat = 0.0
    private var animationTime: CGFloat = 0.0

    // MARK: - Initialization

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = false
        layer?.backgroundColor = NSColor.clear.cgColor
        startAnimationTimer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLinkTimer?.invalidate()
    }

    public override var isOpaque: Bool {
        false
    }

    // MARK: - Public API

    /// Updates the target orb energy with the latest RMS level.
    /// - Parameter rms: The current RMS audio level (0.0 to 1.0).
    public func updateRMS(_ rms: Float) {
        let clampedRMS = clamp(CGFloat(rms), min: 0.0, max: 1.0)
        if clampedRMS > targetEnergy {
            targetEnergy += Self.attackCoefficient * (clampedRMS - targetEnergy)
        } else {
            targetEnergy += Self.releaseCoefficient * (clampedRMS - targetEnergy)
        }
        targetEnergy = clamp(targetEnergy, min: 0.0, max: 1.0)
    }

    // MARK: - Animation

    private func startAnimationTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: Self.timerInterval, repeats: true) { [weak self] _ in
            self?.stepAnimation()
        }
        RunLoop.main.add(timer, forMode: .common)
        displayLinkTimer = timer
    }

    private func stepAnimation() {
        targetEnergy *= 0.985
        displayedEnergy = lerp(displayedEnergy, targetEnergy, 0.10)
        animationTime += 0.05 + displayedEnergy * 0.08
        needsDisplay = true
    }

    // MARK: - Drawing

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.clear(bounds)
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.interpolationQuality = .high

        let rect = bounds.insetBy(dx: 1.0, dy: 1.0)
        let cx = rect.midX
        let cy = rect.midY
        let minSide = min(rect.width, rect.height)

        let orbRadius = minSide * 0.475
        let glowRadius = orbRadius + minSide * (0.16 + displayedEnergy * 0.07)

        drawOuterGlow(in: context, center: CGPoint(x: cx, y: cy), orbRadius: orbRadius, glowRadius: glowRadius)
        drawOrbBody(in: context, center: CGPoint(x: cx, y: cy), radius: orbRadius)
        drawHighlight(in: context, center: CGPoint(x: cx, y: cy), radius: orbRadius)
    }

    private func drawOuterGlow(in context: CGContext, center: CGPoint, orbRadius: CGFloat, glowRadius: CGFloat) {
        let colors = [
            color(red: 72, green: 170, blue: 255, alpha: 0.13 + displayedEnergy * 0.18).cgColor,
            color(red: 138, green: 92, blue: 255, alpha: 0.08 + displayedEnergy * 0.14).cgColor,
            color(red: 255, green: 92, blue: 182, alpha: 0.04 + displayedEnergy * 0.10).cgColor,
            color(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor
        ] as CFArray

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0.0, 0.38, 0.72, 1.0]
        ) else {
            return
        }

        context.saveGState()
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: orbRadius * 0.62,
            endCenter: center,
            endRadius: glowRadius,
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()
    }

    private func drawOrbBody(in context: CGContext, center: CGPoint, radius: CGFloat) {
        let shiftX = cos(animationTime) * radius * (0.10 + displayedEnergy * 0.04)
        let shiftY = sin(animationTime) * radius * (0.10 + displayedEnergy * 0.04)
        let gradientCenter = CGPoint(x: center.x + shiftX, y: center.y + shiftY)

        let colors = [
            color(red: 150, green: 238, blue: 255, alpha: 0.30 + displayedEnergy * 0.08).cgColor,
            color(red: 86, green: 198, blue: 255, alpha: 0.38 + displayedEnergy * 0.14).cgColor,
            color(red: 112, green: 120, blue: 255, alpha: 0.32 + displayedEnergy * 0.16).cgColor,
            color(red: 176, green: 82, blue: 255, alpha: 0.28 + displayedEnergy * 0.16).cgColor,
            color(red: 255, green: 92, blue: 182, alpha: 0.18 + displayedEnergy * 0.20).cgColor,
            color(red: 58, green: 40, blue: 140, alpha: 0.08 + displayedEnergy * 0.04).cgColor
        ] as CFArray

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0.0, 0.16, 0.36, 0.58, 0.82, 1.0]
        ) else {
            return
        }

        context.saveGState()
        let orbPath = CGPath(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2.0,
            height: radius * 2.0
        ), transform: nil)

        context.addPath(orbPath)
        context.clip()
        context.drawRadialGradient(
            gradient,
            startCenter: gradientCenter,
            startRadius: radius * 0.08,
            endCenter: center,
            endRadius: radius,
            options: [.drawsAfterEndLocation]
        )

        let rimColor = color(red: 226, green: 242, blue: 255, alpha: 0.06 + displayedEnergy * 0.03).cgColor
        context.setStrokeColor(rimColor)
        context.setLineWidth(0.8)
        context.addPath(orbPath)
        context.strokePath()

        context.restoreGState()
    }

    private func drawHighlight(in context: CGContext, center: CGPoint, radius: CGFloat) {
        let highlightAlpha = 0.10 + displayedEnergy * 0.06
        let highlightRect = CGRect(
            x: center.x - radius * 0.44,
            y: center.y + radius * 0.10,
            width: radius * 0.34,
            height: radius * 0.18
        )

        context.saveGState()
        context.translateBy(x: highlightRect.midX, y: highlightRect.midY)
        context.rotate(by: -.pi / 4.0)
        context.translateBy(x: -highlightRect.midX, y: -highlightRect.midY)
        context.setFillColor(color(red: 255, green: 255, blue: 255, alpha: highlightAlpha).cgColor)
        context.fillEllipse(in: highlightRect)
        context.restoreGState()
    }

    // MARK: - Helpers

    private func color(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> NSColor {
        NSColor(
            deviceRed: red / 255.0,
            green: green / 255.0,
            blue: blue / 255.0,
            alpha: alpha
        )
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        max(minValue, min(maxValue, value))
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}
