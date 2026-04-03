import AppKit

/// A 5-bar vertical waveform visualization driven by real-time audio RMS levels.
/// Renders capsule-shaped bars using CAShapeLayer for performant ~30fps updates.
public class WaveformView: NSView {
    
    // MARK: - Constants
    
    private static let barCount = 5
    private static let barWeights: [Float] = [0.5, 0.8, 1.0, 0.75, 0.55]
    private static let attackCoefficient: Float = 0.4
    private static let releaseCoefficient: Float = 0.15
    private static let jitterRange: Float = 0.04  // ±4%
    private static let barColor = NSColor.white.withAlphaComponent(0.9)
    private static let animationDuration = 0.08
    private static let minimumBarHeight: CGFloat = 2.0
    private static let animationDurationSeconds: CFTimeInterval = 0.08
    
    // MARK: - State
    
    private var barLayers: [CAShapeLayer] = []
    private var currentLevels: [Float] = Array(repeating: 0, count: barCount)
    
    // MARK: - Initialization
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layer Setup
    
    public override func makeBackingLayer() -> CALayer {
        return CALayer()
    }
    
    private func setupBars() {
        let barWidth: CGFloat = 4.0
        let barGap: CGFloat = 3.0
        let totalBarsWidth = CGFloat(Self.barCount) * barWidth + CGFloat(Self.barCount - 1) * barGap
        let startX = (bounds.width - totalBarsWidth) / 2.0
        let barHeight = bounds.height
        
        for i in 0..<Self.barCount {
            let x = startX + CGFloat(i) * (barWidth + barGap)
            let barLayer = CAShapeLayer()
            barLayer.frame = CGRect(x: x, y: 0, width: barWidth, height: barHeight)
            barLayer.backgroundColor = Self.barColor.cgColor
            barLayer.cornerRadius = barWidth / 2.0
            barLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            barLayer.position = CGPoint(x: x + barWidth / 2.0, y: barHeight)
            layer?.addSublayer(barLayer)
            barLayers.append(barLayer)
        }
    }
    
    // MARK: - Public API
    
    /// Updates the waveform bars based on a new RMS audio level.
    /// - Parameter rms: The current RMS audio level (0.0 to 1.0).
    public func updateRMS(_ rms: Float) {
        guard !barLayers.isEmpty else { return }
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.animationDurationSeconds)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        
        for i in 0..<Self.barCount {
            let weight = Self.barWeights[i]
            var level = currentLevels[i]
            
            // Envelope smoothing
            if rms > level {
                level += Self.attackCoefficient * (rms - level)
            } else {
                level += Self.releaseCoefficient * (rms - level)
            }
            currentLevels[i] = level
            
            // Apply weight
            var weightedLevel = level * weight

            // Add relative random jitter (±4% of current level)
            if weightedLevel > 0.01 {
                let jitterMultiplier = Float.random(in: 1.0 - Self.jitterRange...1.0 + Self.jitterRange)
                weightedLevel *= jitterMultiplier
            }
            
            // Clamp to 0.0-1.0
            weightedLevel = max(0.0, min(1.0, weightedLevel))
            
            // Update bar height
            let barLayer = barLayers[i]
            let fullHeight = barLayer.frame.height
            var newHeight = CGFloat(weightedLevel) * fullHeight
            
            // Minimum visible height when RMS is 0
            if newHeight < Self.minimumBarHeight && weightedLevel > 0 {
                newHeight = Self.minimumBarHeight
            } else if weightedLevel == 0 {
                newHeight = Self.minimumBarHeight
            }
            
            // Update the layer frame (grows upward from bottom due to anchorPoint)
            var newFrame = barLayer.frame
            newFrame.size.height = max(Self.minimumBarHeight, newHeight)
            barLayer.frame = newFrame
        }
        
        CATransaction.commit()
    }
    
    // MARK: - Layout
    
    public override func layout() {
        super.layout()
        updateBarFrames()
    }
    
    private func updateBarFrames() {
        let barWidth: CGFloat = 4.0
        let barGap: CGFloat = 3.0
        let totalBarsWidth = CGFloat(Self.barCount) * barWidth + CGFloat(Self.barCount - 1) * barGap
        let startX = (bounds.width - totalBarsWidth) / 2.0
        let barHeight = bounds.height
        
        for i in 0..<Self.barCount {
            guard i < barLayers.count else { break }
            let barLayer = barLayers[i]
            let x = startX + CGFloat(i) * (barWidth + barGap)
            
            barLayer.frame = CGRect(x: x, y: 0, width: barWidth, height: barHeight)
            barLayer.cornerRadius = barWidth / 2.0
            barLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            barLayer.position = CGPoint(x: x + barWidth / 2.0, y: barHeight)
        }
    }
}
