import AppKit

/// A frameless capsule-shaped floating window that displays waveform animation
/// and real-time transcription text during voice input.
public class FloatingWindow {
    
    // MARK: - Constants
    
    private static let waveformWidth: CGFloat = 44
    private static let waveformHeight: CGFloat = 32
    private static let paddingLeading: CGFloat = 16
    private static let paddingTrailing: CGFloat = 16
    private static let panelHeight: CGFloat = 56
    private static let textMinWidth: CGFloat = 160
    private static let textMaxWidth: CGFloat = 560
    private static let bottomMargin: CGFloat = 80
    private static let cornerRadius: CGFloat = 28
    
    private static let entryAnimationDuration: TimeInterval = 0.35
    private static let textTransitionDuration: TimeInterval = 0.25
    private static let exitAnimationDuration: TimeInterval = 0.22
    
    private static let textFont = NSFont.systemFont(ofSize: 14, weight: .medium)
    
    // MARK: - Properties
    
    private let panel: NSPanel
    private let waveformView: WaveformView
    private let textLabel: NSTextField
    private var currentWidth: CGFloat
    
    // MARK: - Initialization
    
    public init() {
        let initialWidth = Self.minWidth
        currentWidth = initialWidth
        
        // Create the panel
        let contentRect = NSRect(x: 0, y: 0, width: initialWidth, height: Self.panelHeight)
        panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        
        // Create visual effect view
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = Self.cornerRadius
        visualEffectView.layer?.masksToBounds = true
        
        // Create waveform view
        waveformView = WaveformView(
            frame: NSRect(x: 0, y: 0, width: Self.waveformWidth, height: Self.waveformHeight)
        )
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create text label
        textLabel = NSTextField(labelWithString: "")
        textLabel.isEditable = false
        textLabel.isSelectable = false
        textLabel.isBordered = false
        textLabel.drawsBackground = false
        textLabel.textColor = .white
        textLabel.font = Self.textFont
        textLabel.alignment = .left
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.maximumNumberOfLines = 1
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Build layout
        visualEffectView.addSubview(waveformView)
        visualEffectView.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            // Waveform constraints
            waveformView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: Self.paddingLeading),
            waveformView.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor),
            waveformView.widthAnchor.constraint(equalToConstant: Self.waveformWidth),
            waveformView.heightAnchor.constraint(equalToConstant: Self.waveformHeight),
            
            // Text label constraints
            textLabel.leadingAnchor.constraint(equalTo: waveformView.trailingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -Self.paddingTrailing),
            textLabel.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor),
            textLabel.heightAnchor.constraint(equalToConstant: Self.panelHeight),
        ])
        
        panel.contentView = visualEffectView
        
        // Start hidden with zero scale for entry animation
        panel.alphaValue = 0
    }
    
    // MARK: - Computed Properties
    
    private static var minWidth: CGFloat {
        Self.waveformWidth + Self.paddingLeading + Self.textMinWidth + Self.paddingTrailing
    }
    
    private static var maxWidth: CGFloat {
        Self.waveformWidth + Self.paddingLeading + Self.textMaxWidth + Self.paddingTrailing
    }
    
    // MARK: - Public Methods
    
    /// Shows the floating window with entry animation.
    public func show() {
        positionPanel()

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)

        if let contentView = panel.contentView {
            contentView.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            contentView.layer?.transform = CATransform3DMakeScale(0.8, 0.8, 1.0)
            contentView.layer?.opacity = 0.0

            CATransaction.begin()
            CATransaction.setAnimationDuration(Self.entryAnimationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0))
            contentView.layer?.transform = CATransform3DIdentity
            contentView.layer?.opacity = 1.0
            CATransaction.commit()
        }
    }
    
    /// Hides the floating window with exit animation.
    public func hide() {
        guard let contentView = panel.contentView else {
            panel.orderOut(nil)
            return
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.exitAnimationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))
        CATransaction.setCompletionBlock {
            self.panel.orderOut(nil)
            contentView.layer?.transform = CATransform3DIdentity
            contentView.layer?.opacity = 1.0
        }

        contentView.layer?.transform = CATransform3DMakeScale(0.8, 0.8, 1.0)
        contentView.layer?.opacity = 0.0

        CATransaction.commit()
    }
    
    /// Updates the transcription text and animates panel width adjustment.
    /// - Parameter text: The new transcription text to display.
    public func updateText(_ text: String) {
        textLabel.stringValue = text
        adjustPanelWidth()
    }
    
    /// Updates the status text (e.g., "Refining...") in place of transcription.
    /// - Parameter status: The status text to display.
    public func updateStatus(_ status: String) {
        textLabel.stringValue = status
        adjustPanelWidth()
    }
    
    /// Returns the waveform view for RMS updates.
    public var waveform: WaveformView {
        waveformView
    }
    
    // MARK: - Private Methods
    
    /// Positions the panel centered horizontally at the bottom of the main screen.
    private func positionPanel() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let x = (screenFrame.width - currentWidth) / 2.0 + screenFrame.origin.x
        let y = screenFrame.origin.y + Self.bottomMargin
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    /// Measures text width and adjusts the panel width with smooth animation.
    private func adjustPanelWidth() {
        let text = textLabel.stringValue as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: Self.textFont]
        let constraintSize = CGSize(width: Self.textMaxWidth, height: Self.panelHeight)
        let textSize = text.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, attributes: attributes)
        
        var measuredWidth = textSize.width
        measuredWidth = max(Self.textMinWidth, min(Self.textMaxWidth, measuredWidth))
        
        let newWidth = Self.waveformWidth + Self.paddingLeading + measuredWidth + Self.paddingTrailing
        let clampedWidth = max(Self.minWidth, min(Self.maxWidth, newWidth))
        
        guard abs(clampedWidth - currentWidth) > 0.5 else { return }
        
        currentWidth = clampedWidth
        
        // Reposition for new width
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let newX = (screenFrame.width - clampedWidth) / 2.0 + screenFrame.origin.x
        let newY = screenFrame.origin.y + Self.bottomMargin
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.textTransitionDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            panel.animator().setFrame(
                NSRect(x: newX, y: newY, width: clampedWidth, height: Self.panelHeight),
                display: true
            )
        } completionHandler: {
            // Animation complete
        }
    }
}
