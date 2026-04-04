import Foundation
import ServiceManagement

// MARK: - LaunchAtLoginManager

/// Manages the application's launch-at-login state using ServiceManagement framework.
///
/// Uses SMAppService (macOS 13+) for modern launch agent management,
/// with fallback support for older systems.
final class LaunchAtLoginManager {
    
    // MARK: - UserDefaults Keys
    
    private static let keyLaunchAtLoginEnabled = "launchAtLoginEnabled"
    
    // MARK: - Properties
    
    /// Whether launch at login is currently enabled.
    /// This property is backed by UserDefaults for persistence.
    static var isEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: keyLaunchAtLoginEnabled) as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: keyLaunchAtLoginEnabled)
        }
    }
    
    /// Returns the current registration state from the system.
    /// This checks the actual SMAppService status, which may differ from `isEnabled`
    /// if the user manually disabled the service in System Settings.
    static var isRegistered: Bool {
        guard #available(macOS 13.0, *) else {
            // For older macOS, rely on UserDefaults
            return isEnabled
        }
        
        let service = SMAppService.mainApp
        return service.status == .enabled
    }
    
    // MARK: - Registration
    
    /// Registers the application to launch at login.
    /// - Throws: An error if registration fails (e.g., user denied permission).
    static func register() throws {
        guard #available(macOS 13.0, *) else {
            // For older macOS versions, we would need to use SMLoginItemSetEnabled
            // with a helper app. For now, we just store the preference.
            Logger.settings.info("Launch at login registration not supported on this macOS version")
            isEnabled = true
            return
        }
        
        let service = SMAppService.mainApp
        
        if service.status == .enabled {
            Logger.settings.debug("Launch at login already registered")
            isEnabled = true
            return
        }
        
        do {
            try service.register()
            isEnabled = true
            Logger.settings.info("Launch at login registered successfully")
        } catch {
            Logger.settings.error("Failed to register launch at login: \(error.localizedDescription)")
            throw LaunchAtLoginError.registrationFailed(underlying: error)
        }
    }
    
    /// Unregisters the application from launching at login.
    static func unregister() {
        guard #available(macOS 13.0, *) else {
            isEnabled = false
            return
        }
        
        let service = SMAppService.mainApp
        
        guard service.status == .enabled else {
            Logger.settings.debug("Launch at login not registered")
            isEnabled = false
            return
        }
        
        do {
            try service.unregister()
            isEnabled = false
            Logger.settings.info("Launch at login unregistered successfully")
        } catch {
            Logger.settings.error("Failed to unregister launch at login: \(error.localizedDescription)")
            // Even if unregister fails, update the preference
            isEnabled = false
        }
    }
    
    /// Updates the launch-at-login state based on the current `isEnabled` value.
    /// Call this at app launch to ensure the system state matches the preference.
    static func synchronizeState() {
        let shouldBeEnabled = isEnabled
        let isCurrentlyRegistered = isRegistered
        
        Logger.settings.debug("Synchronizing launch-at-login state: shouldBeEnabled=\(shouldBeEnabled), isRegistered=\(isCurrentlyRegistered)")
        
        if shouldBeEnabled && !isCurrentlyRegistered {
            do {
                try register()
            } catch {
                Logger.settings.error("Failed to synchronize launch-at-login state: \(error.localizedDescription)")
            }
        } else if !shouldBeEnabled && isCurrentlyRegistered {
            unregister()
        }
    }
    
    // MARK: - Errors
    
    enum LaunchAtLoginError: LocalizedError {
        case registrationFailed(underlying: Error)
        
        var errorDescription: String? {
            switch self {
            case .registrationFailed(let error):
                return "Failed to register launch at login: \(error.localizedDescription)"
            }
        }
    }
}
