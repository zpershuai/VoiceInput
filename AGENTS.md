# AGENTS.md

## Project Overview

VoiceInput is a macOS menu bar application for voice-to-text input with AI refinement capabilities.

- **Language**: Swift 5.9
- **Platform**: macOS 14.0+
- **Build System**: Swift Package Manager + Makefile
- **Frameworks**: AppKit, Speech, AVFoundation, Carbon, CoreGraphics
- **Architecture**: Single-target executable with class-based components

## Build Commands

```bash
# Build debug version
swift build

# Build release version (creates .app bundle)
make build

# Build and run
make run

# Install to /Applications
make install

# Clean build artifacts
make clean

# Debug run
.build/debug/VoiceInput
```

## Project Structure

```
Sources/VoiceInput/
├── main.swift              # Entry point
├── AppDelegate.swift       # App lifecycle & orchestration
├── GlobalEventMonitor.swift # Fn key event monitoring
├── SpeechRecognizer.swift  # Speech recognition engine
├── FloatingWindow.swift    # UI window with animations
├── WaveformView.swift      # Audio visualization
├── TextInjector.swift      # Text input simulation
├── LLMRefiner.swift        # OpenAI API client
├── SettingsWindow.swift    # Preferences UI
├── LanguageManager.swift   # Language switching
└── Logger.swift            # File-based logging
```

## Code Style Guidelines

### Formatting
- **Indentation**: 4 spaces (no tabs)
- **Line length**: ~120 characters
- **Trailing whitespace**: Trimmed
- **Braces**: Opening brace on same line (K&R style)

### Imports
- Group by framework: Foundation first, then Apple frameworks, then external
- Alphabetize within groups
- Example:
```swift
import AppKit
import AVFoundation
import Carbon
import Combine
import CoreGraphics
import Foundation
import Speech
```

### Naming Conventions
- **Types**: PascalCase (`FloatingWindow`, `SpeechRecognizerError`)
- **Variables/Functions**: camelCase (`onStartRecording`, `currentLanguage`)
- **Constants**: camelCase with descriptive names (`waveformWidth`, `entryAnimationDuration`)
- **Files**: PascalCase matching primary type (`FloatingWindow.swift`)
- **Private**: Prefix with `private`/`fileprivate`, use descriptive names

### Types
- Prefer `final class` for singletons and managers
- Use `struct` for simple data models (Codable)
- Strong typing with enums for errors and modules
- Avoid `Any` and force unwrapping

```swift
// Error enum with LocalizedError
enum SpeechRecognizerError: LocalizedError {
    case notAuthorized
    var errorDescription: String? { ... }
}

// Observable singleton
final class LanguageManager: NSObject, ObservableObject {
    static let shared = LanguageManager()
}
```

### Comments
- Use `// MARK: - Section Name` to organize code sections
- Doc comments for public APIs (`/// Description`)
- Inline comments for complex logic
- Keep comments current with code

### Error Handling
- Use `Result` or `throws` for operations that can fail
- Define custom `Error` types with descriptive messages
- Log errors with context using the Logger module
- Prefer `guard` with early returns over nested `if`

```swift
guard authStatus == .authorized else {
    throw SpeechRecognizerError.notAuthorized
}
```

### Concurrency
- Use `async/await` for async operations
- Use `@MainActor` for UI updates
- Use `[weak self]` in closures to avoid retain cycles
- Dispatch to background queues for heavy work

```swift
Task {
    do {
        try await speechRecognizer.startRecording()
    } catch {
        Logger.app.error("Failed: \(error)")
    }
}
```

### Memory Management
- Use `[weak self]` in all closures that capture self
- Keep global references to prevent deallocation:
```swift
var appDelegate: AppDelegate?  // Global to keep alive
```

### Logging
Use the module-specific loggers defined in Logger.swift:
```swift
Logger.app.info("Application launched")
Logger.speech.debug("Partial result: \(text)")
Logger.llm.error("API request failed")
```

## Testing

This project uses manual testing (no automated test suite). Testing checklist:
- [ ] Fn key triggers recording
- [ ] Speech recognition works
- [ ] Text injection succeeds
- [ ] Language switching works
- [ ] LLM refinement (if configured)
- [ ] Settings persist

## Architecture Patterns

- **Delegate Pattern**: `AppDelegate`, `NSApplicationDelegate`
- **Observer Pattern**: Combine framework (`@Published`, `sink`)
- **Callback Pattern**: Closure-based event handling (`onStartRecording`)
- **Singleton Pattern**: `Logger.shared`, `LanguageManager.shared`
- **Repository Pattern**: UserDefaults for persistence

## Key Implementation Notes

1. **Event Monitoring**: Uses CoreGraphics event taps (requires Accessibility permission)
2. **Text Injection**: Simulates Cmd+V via Carbon, handles CJK input method switching
3. **Speech Recognition**: Apple Speech framework with streaming recognition
4. **LLM Refinement**: OpenAI-compatible API with conservative correction prompt
5. **UI**: Frameless NSPanel with CAAnimations for smooth transitions
