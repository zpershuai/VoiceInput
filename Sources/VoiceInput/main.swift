import AppKit

// Keep delegate alive - NSApplication.delegate is a weak reference
var appDelegate: AppDelegate?

let app = NSApplication.shared
appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
