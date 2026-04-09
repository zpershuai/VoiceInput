import AppKit

/// A frameless capsule-shaped floating window that displays a voice orb indicator
/// and real-time transcription text during voice input.
public final class FloatingWindow {

    // MARK: - Layout State

    private enum LayoutMode {
        case defaultSingleLine
        case expandedSingleLine
        case twoLine
    }

    private struct LayoutMetrics: Equatable {
        let mode: LayoutMode
        let size: CGSize
        let textWidth: CGFloat
        let textHeight: CGFloat
    }

    private final class CapsuleView: NSVisualEffectView {
        let orbView: VoiceOrbView
        let textLabel: NSTextField

        var layoutMetrics: LayoutMetrics {
            didSet {
                applyTextBehavior(for: layoutMetrics.mode)
                needsLayout = true
            }
        }

        init(initialLayout: LayoutMetrics) {
            self.layoutMetrics = initialLayout
            self.orbView = VoiceOrbView(frame: .zero)
            self.textLabel = NSTextField(labelWithString: "")

            super.init(frame: NSRect(origin: .zero, size: initialLayout.size))

            material = .menu
            state = .active
            blendingMode = .behindWindow
            wantsLayer = true
            autoresizingMask = [.width, .height]

            layer?.masksToBounds = true
            layer?.backgroundColor = NSColor(calibratedWhite: 0.08, alpha: 0.82).cgColor
            layer?.borderColor = NSColor(calibratedWhite: 1.0, alpha: 0.12).cgColor
            layer?.borderWidth = 1
            layer?.shadowColor = NSColor.black.withAlphaComponent(0.28).cgColor
            layer?.shadowOpacity = 1.0
            layer?.shadowRadius = 18
            layer?.shadowOffset = CGSize(width: 0, height: -6)

            orbView.frame = .zero

            textLabel.isEditable = false
            textLabel.isSelectable = false
            textLabel.isBordered = false
            textLabel.drawsBackground = false
            textLabel.textColor = .white
            textLabel.font = FloatingWindow.textFont
            textLabel.alignment = .left
            textLabel.alphaValue = 0.96
            textLabel.backgroundColor = .clear
            textLabel.autoresizingMask = [.width, .height]

            addSubview(orbView)
            addSubview(textLabel)

            applyTextBehavior(for: initialLayout.mode)
            needsLayout = true
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layout() {
            super.layout()

            let capsuleRadius = bounds.height / 2.0
            layer?.cornerRadius = capsuleRadius
            layer?.shadowPath = CGPath(
                roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
                cornerWidth: capsuleRadius,
                cornerHeight: capsuleRadius,
                transform: nil
            )

            let orbY = round((bounds.height - FloatingWindow.orbHeight) / 2.0)
            orbView.frame = NSRect(
                x: FloatingWindow.paddingLeading,
                y: orbY,
                width: FloatingWindow.orbWidth,
                height: FloatingWindow.orbHeight
            )

            let textOriginX = FloatingWindow.paddingLeading + FloatingWindow.orbWidth + FloatingWindow.contentSpacing
            let textOriginY = round((bounds.height - layoutMetrics.textHeight) / 2.0)
            textLabel.frame = NSRect(
                x: textOriginX,
                y: textOriginY,
                width: layoutMetrics.textWidth,
                height: layoutMetrics.textHeight
            )
        }

        func update(text: String, layoutMetrics: LayoutMetrics) {
            textLabel.stringValue = text
            self.layoutMetrics = layoutMetrics
        }

        private func applyTextBehavior(for mode: LayoutMode) {
            let isTwoLine = mode == .twoLine
            textLabel.maximumNumberOfLines = isTwoLine ? FloatingWindow.maximumLineCount : 1
            textLabel.lineBreakMode = .byTruncatingTail

            if let textCell = textLabel.cell as? NSTextFieldCell {
                textCell.wraps = isTwoLine
                textCell.isScrollable = !isTwoLine
                textCell.lineBreakMode = .byTruncatingTail
            }
        }
    }

    // MARK: - Constants

    fileprivate static let orbWidth: CGFloat = 40
    fileprivate static let orbHeight: CGFloat = 40
    fileprivate static let paddingLeading: CGFloat = 18
    fileprivate static let paddingTrailing: CGFloat = 20
    fileprivate static let contentSpacing: CGFloat = 10
    fileprivate static let singleLineHeight: CGFloat = 64
    fileprivate static let twoLineHeight: CGFloat = 88
    fileprivate static let textMinWidth: CGFloat = 180
    fileprivate static let textMaxSingleLineWidth: CGFloat = 420
    fileprivate static let maximumLineCount = 2

    private static let bottomMargin: CGFloat = 92
    private static let textHorizontalResizeThreshold: CGFloat = 0.5
    private static let lineHeight = ceil(textFont.ascender - textFont.descender + textFont.leading)
    private static let singleLineTextHeight = ceil(lineHeight)
    private static let twoLineTextHeight = ceil(lineHeight * CGFloat(maximumLineCount))

    private static let entryAnimationDuration: TimeInterval = 0.35
    private static let textTransitionDuration: TimeInterval = 0.25
    private static let exitAnimationDuration: TimeInterval = 0.22

    fileprivate static let textFont = NSFont.monospacedSystemFont(ofSize: 15, weight: .medium)

    // MARK: - Properties

    private let panel: NSPanel
    private let capsuleView: CapsuleView
    private var currentLayout: LayoutMetrics

    // MARK: - Initialization

    public init() {
        let initialLayout = Self.layoutMetrics(for: "")
        currentLayout = initialLayout

        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: initialLayout.size),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        capsuleView = CapsuleView(initialLayout: initialLayout)

        panel.level = .statusBar
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentView = capsuleView
        panel.alphaValue = 0
    }

    // MARK: - Public Methods

    /// Shows the floating window with entry animation.
    public func show() {
        let targetFrame = panelFrame(for: currentLayout.size)
        panel.setFrame(targetFrame, display: true)
        capsuleView.update(text: capsuleView.textLabel.stringValue, layoutMetrics: currentLayout)
        capsuleView.layoutSubtreeIfNeeded()

        panel.alphaValue = 0
        NSApp.activate(ignoringOtherApps: false)
        panel.orderFrontRegardless()

        guard let capsuleLayer = capsuleView.layer else {
            panel.alphaValue = 1
            return
        }

        capsuleLayer.transform = CATransform3DMakeScale(0.88, 0.88, 1.0)
        capsuleLayer.opacity = 0.0

        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.entryAnimationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0))
        panel.animator().alphaValue = 1.0
        capsuleLayer.transform = CATransform3DIdentity
        capsuleLayer.opacity = 1.0
        CATransaction.commit()
    }

    /// Hides the floating window with exit animation.
    public func hide() {
        guard let capsuleLayer = capsuleView.layer else {
            panel.orderOut(nil)
            return
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.exitAnimationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))
        CATransaction.setCompletionBlock {
            self.panel.orderOut(nil)
            capsuleLayer.transform = CATransform3DIdentity
            capsuleLayer.opacity = 1.0
        }

        capsuleLayer.transform = CATransform3DMakeScale(0.9, 0.9, 1.0)
        capsuleLayer.opacity = 0.0
        panel.animator().alphaValue = 0.0

        CATransaction.commit()
    }

    /// Updates the transcription text and animates panel size adjustment.
    /// - Parameter text: The new transcription text to display.
    public func updateText(_ text: String) {
        updateDisplay(text, animated: panel.isVisible)
    }

    /// Updates the status text (e.g., "Refining...") in place of transcription.
    /// - Parameter status: The status text to display.
    public func updateStatus(_ status: String) {
        updateDisplay(status, animated: panel.isVisible)
    }

    /// Returns the voice orb view for RMS updates.
    public var waveform: VoiceOrbView {
        capsuleView.orbView
    }

    // MARK: - Layout Helpers

    private static var minWidth: CGFloat {
        paddingLeading + orbWidth + contentSpacing + textMinWidth + paddingTrailing
    }

    private static var maxSingleLineWidth: CGFloat {
        paddingLeading + orbWidth + contentSpacing + textMaxSingleLineWidth + paddingTrailing
    }

    private static func layoutMetrics(for text: String) -> LayoutMetrics {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLineWidth = measuredSingleLineWidth(for: normalizedText)

        if singleLineWidth <= textMinWidth {
            return LayoutMetrics(
                mode: .defaultSingleLine,
                size: CGSize(width: minWidth, height: singleLineHeight),
                textWidth: textMinWidth,
                textHeight: singleLineTextHeight
            )
        }

        if singleLineWidth <= textMaxSingleLineWidth {
            let clampedTextWidth = max(textMinWidth, min(textMaxSingleLineWidth, singleLineWidth))
            return LayoutMetrics(
                mode: .expandedSingleLine,
                size: CGSize(
                    width: paddingLeading + orbWidth + contentSpacing + clampedTextWidth + paddingTrailing,
                    height: singleLineHeight
                ),
                textWidth: clampedTextWidth,
                textHeight: singleLineTextHeight
            )
        }

        return LayoutMetrics(
            mode: .twoLine,
            size: CGSize(width: maxSingleLineWidth, height: twoLineHeight),
            textWidth: textMaxSingleLineWidth,
            textHeight: measuredTwoLineTextHeight(for: normalizedText)
        )
    }

    private static func measuredSingleLineWidth(for text: String) -> CGFloat {
        guard !text.isEmpty else { return 0 }

        let attributes: [NSAttributedString.Key: Any] = [.font: textFont]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }

    private static func measuredTwoLineTextHeight(for text: String) -> CGFloat {
        guard !text.isEmpty else { return singleLineTextHeight }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .paragraphStyle: paragraphStyle
        ]

        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: textMaxSingleLineWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )

        return min(twoLineTextHeight, max(singleLineTextHeight, ceil(boundingRect.height)))
    }

    private func updateDisplay(_ text: String, animated: Bool) {
        var newLayout = Self.layoutMetrics(for: text)

        if currentLayout.mode == newLayout.mode,
           currentLayout.size.height == newLayout.size.height,
           abs(currentLayout.size.width - newLayout.size.width) < Self.textHorizontalResizeThreshold {
            newLayout = LayoutMetrics(
                mode: newLayout.mode,
                size: CGSize(width: currentLayout.size.width, height: newLayout.size.height),
                textWidth: currentLayout.textWidth,
                textHeight: newLayout.textHeight
            )
        }

        let sizeChanged = newLayout.size != currentLayout.size
        let layoutChanged = newLayout != currentLayout

        currentLayout = newLayout
        capsuleView.update(text: text, layoutMetrics: newLayout)

        guard animated else {
            panel.setFrame(panelFrame(for: newLayout.size), display: true)
            capsuleView.layoutSubtreeIfNeeded()
            return
        }

        guard sizeChanged || layoutChanged else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.textTransitionDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(panelFrame(for: newLayout.size), display: true)
            capsuleView.layoutSubtreeIfNeeded()
        }
    }

    private func panelFrame(for size: CGSize) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(origin: .zero, size: size)
        }

        let screenFrame = screen.visibleFrame
        let x = screenFrame.origin.x + (screenFrame.width - size.width) / 2.0
        let y = screenFrame.origin.y + Self.bottomMargin

        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}
