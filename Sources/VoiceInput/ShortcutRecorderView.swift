import AppKit

protocol ShortcutRecorderViewDelegate: AnyObject {
    func shortcutRecorderView(_ view: ShortcutRecorderView, didCaptureShortcut shortcut: Shortcut)
    func shortcutRecorderViewDidCancelRecording(_ view: ShortcutRecorderView)
}

final class ShortcutRecorderView: NSView {
    
    weak var delegate: ShortcutRecorderViewDelegate?
    
    private var isRecording = false {
        didSet {
            updateAppearance()
        }
    }
    
    private var capturedShortcut: Shortcut?
    private var localEventMonitor: Any?
    
    private let textField: NSTextField = {
        let field = NSTextField(labelWithString: "Click to Record")
        field.alignment = .center
        field.font = NSFont.systemFont(ofSize: 13)
        field.textColor = .secondaryLabelColor
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let containerView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 6
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.separatorColor.cgColor
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        containerView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 150),
            containerView.heightAnchor.constraint(equalToConstant: 28),
            
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(viewClicked))
        addGestureRecognizer(clickGesture)
    }
    
    func setShortcut(_ shortcut: Shortcut?) {
        capturedShortcut = shortcut
        updateDisplay()
    }
    
    func currentShortcut() -> Shortcut? {
        return capturedShortcut
    }
    
    private func updateDisplay() {
        if isRecording {
            textField.stringValue = "Press shortcut..."
            textField.textColor = .controlAccentColor
        } else if let shortcut = capturedShortcut {
            textField.stringValue = shortcut.displayString
            textField.textColor = .labelColor
        } else {
            textField.stringValue = "Click to Record"
            textField.textColor = .secondaryLabelColor
        }
    }
    
    private func updateAppearance() {
        updateDisplay()
        
        if isRecording {
            containerView.layer?.borderColor = NSColor.controlAccentColor.cgColor
            containerView.layer?.borderWidth = 2
            startLocalEventMonitoring()
        } else {
            containerView.layer?.borderColor = NSColor.separatorColor.cgColor
            containerView.layer?.borderWidth = 1
            stopLocalEventMonitoring()
        }
    }
    
    @objc private func viewClicked() {
        guard !isRecording else { return }
        isRecording = true
    }
    
    private func startLocalEventMonitoring() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            if let self = self, !self.bounds.contains(self.convert(event.locationInWindow, from: nil)) {
                self.cancelRecording()
            }
            return event
        }
    }
    
    private func stopLocalEventMonitoring() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        guard isRecording else { return }
        
        if event.type == .keyDown {
            let keyCode = event.keyCode
            
            if keyCode == 53 {
                cancelRecording()
                return
            }
            
            let deviceIndependentFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let hasModifier = deviceIndependentFlags.contains([.command, .option, .shift, .control])
            let isModifierOnly = isModifierKey(keyCode)
            
            if isModifierOnly && !hasModifier {
                return
            }
            
            let shortcut = Shortcut(keyCode: keyCode, modifierFlags: deviceIndependentFlags.rawValue)
            captureShortcut(shortcut)
        }
    }
    
    private func isModifierKey(_ keyCode: UInt16) -> Bool {
        let modifierKeyCodes: [UInt16] = [55, 56, 57, 58, 59, 60, 61, 62]
        return modifierKeyCodes.contains(keyCode)
    }
    
    private func captureShortcut(_ shortcut: Shortcut) {
        capturedShortcut = shortcut
        isRecording = false
        delegate?.shortcutRecorderView(self, didCaptureShortcut: shortcut)
    }
    
    private func cancelRecording() {
        isRecording = false
        delegate?.shortcutRecorderViewDidCancelRecording(self)
    }
    
    deinit {
        stopLocalEventMonitoring()
    }
}
