import AppKit

/// A circular voice orb that follows the "Canvas Fluid Gradient + Pulse" effect.
public final class VoiceOrbView: NSView {

    // MARK: - Constants

    private static let attackCoefficient: CGFloat = 0.18
    private static let releaseCoefficient: CGFloat = 0.08
    private static let timerInterval: TimeInterval = 1.0 / 30.0
    private static let idleRadiusRatio: CGFloat = 0.42
    private static let pulseAmplitudeRatio: CGFloat = 0.03
    private static let energyRadiusBoostRatio: CGFloat = 0.11
    private static let energyScaleBoost: CGFloat = 0.08

    // MARK: - State

    private var displayLinkTimer: Timer?
    private var displayedEnergy: CGFloat = 0.0
    private var targetEnergy: CGFloat = 0.0
    private var animationTime: CGFloat = 0.0

    // MARK: - Initialization

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = false
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
        targetEnergy *= 0.99
        displayedEnergy = lerp(displayedEnergy, targetEnergy, 0.08)
        animationTime += 0.015 + displayedEnergy * 0.04
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

        let baseRadius = minSide * Self.idleRadiusRatio
        let pulseRadius = baseRadius
            + sin(animationTime * 2.0) * minSide * Self.pulseAmplitudeRatio
            + displayedEnergy * minSide * Self.energyRadiusBoostRatio
        let orbScale = 1.0 + displayedEnergy * Self.energyScaleBoost
        let glowRadius = pulseRadius + minSide * (0.08 + displayedEnergy * 0.10)
        let center = CGPoint(x: cx, y: cy)

        drawOuterGlow(in: context, center: center, orbRadius: pulseRadius, glowRadius: glowRadius)
        drawOrbBody(in: context, center: center, radius: pulseRadius, scale: orbScale)
        drawHighlight(in: context, center: center, radius: pulseRadius, scale: orbScale)
    }

    private func drawOuterGlow(in context: CGContext, center: CGPoint, orbRadius: CGFloat, glowRadius: CGFloat) {
        let colors = [
            color(red: 80, green: 180, blue: 255, alpha: 0.25 + displayedEnergy * 0.35).cgColor,
            color(red: 160, green: 80, blue: 255, alpha: 0.15 + displayedEnergy * 0.25).cgColor,
            color(red: 255, green: 92, blue: 182, alpha: 0.07 + displayedEnergy * 0.14).cgColor,
            color(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor
        ] as CFArray

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0.0, 0.4, 0.72, 1.0]
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

    private func drawOrbBody(in context: CGContext, center: CGPoint, radius: CGFloat, scale: CGFloat) {
        let shiftX = cos(animationTime) * radius * 0.14
        let shiftY = sin(animationTime) * radius * 0.14
        let gradientCenter = CGPoint(x: center.x + shiftX, y: center.y + shiftY)

        let colors = [
            color(red: 200, green: 255, blue: 255, alpha: 0.85 + displayedEnergy * 0.15).cgColor,
            color(red: 100, green: 200, blue: 255, alpha: 0.60 + displayedEnergy * 0.20).cgColor,
            color(red: 160, green: 80, blue: 255, alpha: 0.45 + displayedEnergy * 0.25).cgColor,
            color(red: 255, green: 80, blue: 180, alpha: 0.25 + displayedEnergy * 0.30).cgColor,
            color(red: 40, green: 0, blue: 100, alpha: 0.35).cgColor
        ] as CFArray

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0.0, 0.25, 0.55, 0.85, 1.0]
        ) else {
            return
        }

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -center.x, y: -center.y)

        let orbPath = CGPath(
            ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2.0,
                height: radius * 2.0
            ),
            transform: nil
        )

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

        let rimColor = color(red: 235, green: 245, blue: 255, alpha: 0.12 + displayedEnergy * 0.06).cgColor
        context.setStrokeColor(rimColor)
        context.setLineWidth(0.8)
        context.addPath(orbPath)
        context.strokePath()

        context.restoreGState()
    }

    private func drawHighlight(in context: CGContext, center: CGPoint, radius: CGFloat, scale: CGFloat) {
        let highlightAlpha = 0.35 + displayedEnergy * 0.20
        let highlightRect = CGRect(
            x: center.x - radius * 0.47,
            y: center.y + radius * 0.13,
            width: radius * 0.44,
            height: radius * 0.24
        )

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -center.x, y: -center.y)
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
