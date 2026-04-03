import Foundation

/// Centralized logging system for VoiceInput app.
/// Logs are written to ~/Library/Logs/VoiceInput/ with module-based categorization.
final class Logger {
    
    // MARK: - Module Definitions
    
    enum Module: String, CaseIterable {
        case app = "App"
        case speech = "Speech"
        case input = "Input"
        case llm = "LLM"
        case ui = "UI"
        case event = "Event"
        case settings = "Settings"
    }
    
    // MARK: - Log Level
    
    enum Level: String, Comparable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        
        static func < (lhs: Level, rhs: Level) -> Bool {
            let order: [Level] = [.debug, .info, .warning, .error]
            guard let lhsIndex = order.firstIndex(of: lhs),
                  let rhsIndex = order.firstIndex(of: rhs) else {
                return false
            }
            return lhsIndex < rhsIndex
        }
    }
    
    // MARK: - Singleton
    
    static let shared = Logger()
    
    // MARK: - Properties
    
    private let logDirectory: URL
    private let logFile: URL
    private let dateFormatter: DateFormatter
    private let fileHandleQueue = DispatchQueue(label: "com.voiceinput.logger.file", qos: .utility)
    private var fileHandle: FileHandle?
    private let minimumLogLevel: Level = .debug
    
    // MARK: - Initialization
    
    private init() {
        // Setup log directory: ~/Library/Logs/VoiceInput/
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        self.logDirectory = libraryURL.appendingPathComponent("Logs/VoiceInput", isDirectory: true)
        
        // Create log filename with date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        self.logFile = logDirectory.appendingPathComponent("voiceinput_\(dateString).log")
        
        // Setup timestamp formatter
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Initialize log directory and file
        setupLogDirectory()
        setupLogFile()
    }
    
    deinit {
        fileHandleQueue.sync {
            fileHandle?.closeFile()
        }
    }
    
    // MARK: - Setup
    
    private func setupLogDirectory() {
        do {
            try FileManager.default.createDirectory(
                at: logDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("[Logger] Failed to create log directory: \(error)")
        }
    }
    
    private func setupLogFile() {
        fileHandleQueue.sync {
            // Create file if it doesn't exist
            if !FileManager.default.fileExists(atPath: logFile.path) {
                FileManager.default.createFile(atPath: logFile.path, contents: nil, attributes: nil)
            }
            
            // Open file handle
            do {
                self.fileHandle = try FileHandle(forWritingTo: logFile)
                // Seek to end for appending
                self.fileHandle?.seekToEndOfFile()
            } catch {
                print("[Logger] Failed to open log file: \(error)")
            }
        }
    }
    
    // MARK: - Public API
    
    func log(_ message: String, level: Level = .info, module: Module, file: String = #file, function: String = #function, line: Int = #line) {
        guard level >= minimumLogLevel else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let filename = (file as NSString).lastPathComponent
        let logEntry = "[\(timestamp)] [\(level.rawValue)] [\(module.rawValue)] [\(filename):\(line)] \(function): \(message)\n"
        
        // Write to file on background queue
        fileHandleQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let data = logEntry.data(using: .utf8) {
                self.fileHandle?.write(data)
            }
        }
        
        // Also print to console for debugging
        #if DEBUG
        print(logEntry.trimmingCharacters(in: .newlines))
        #endif
    }
    
    // MARK: - Convenience Methods
    
    func debug(_ message: String, module: Module, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, module: module, file: file, function: function, line: line)
    }
    
    func info(_ message: String, module: Module, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, module: module, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, module: Module, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, module: module, file: file, function: function, line: line)
    }
    
    func error(_ message: String, module: Module, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, module: module, file: file, function: function, line: line)
    }
    
    // MARK: - Log File Management
    
    func getLogFilePath() -> String {
        return logFile.path
    }
    
    func getAllLogFiles() -> [URL] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: logDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            return files.filter { $0.pathExtension == "log" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            return []
        }
    }
    
    func clearOldLogs(keepingDays: Int = 7) {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -keepingDays, to: Date()) ?? Date.distantPast
        
        let oldFiles = getAllLogFiles().filter { url in
            if let creationDate = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate {
                return creationDate < cutoffDate
            }
            return false
        }
        
        for file in oldFiles {
            do {
                try FileManager.default.removeItem(at: file)
                info("Removed old log file: \(file.lastPathComponent)", module: .app)
            } catch let removalError {
                self.error("Failed to remove old log file: \(removalError)", module: .app)
            }
        }
    }
}

// MARK: - Module-Specific Loggers

extension Logger {
    /// Logger for App lifecycle events
    static let app = ModuleLogger(module: .app)
    
    /// Logger for Speech recognition events
    static let speech = ModuleLogger(module: .speech)
    
    /// Logger for Text input injection events
    static let input = ModuleLogger(module: .input)
    
    /// Logger for LLM refinement events
    static let llm = ModuleLogger(module: .llm)
    
    /// Logger for UI events
    static let ui = ModuleLogger(module: .ui)
    
    /// Logger for Event monitoring events
    static let event = ModuleLogger(module: .event)
    
    /// Logger for Settings events
    static let settings = ModuleLogger(module: .settings)
}

/// Convenience wrapper for module-specific logging
struct ModuleLogger {
    let module: Logger.Module
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.debug(message, module: module, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.info(message, module: module, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.warning(message, module: module, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.error(message, module: module, file: file, function: function, line: line)
    }
}
