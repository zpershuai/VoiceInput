import Foundation
import Combine

final class LanguageManager: NSObject, ObservableObject {
    
    static let shared = LanguageManager()
    
    private static let userDefaultsKey = "selectedVoiceLanguage"
    
    static let availableLanguages: [(code: String, name: String)] = [
        ("zh-CN", "简体中文"),
        ("en-US", "English"),
        ("zh-TW", "繁體中文"),
        ("ja-JP", "日本語"),
        ("ko-KR", "한국어"),
    ]
    
    @Published private(set) var currentLanguage: String
    
    var currentLanguageName: String {
        Self.availableLanguages.first { $0.code == currentLanguage }?.name ?? "简体中文"
    }
    
    private override init() {
        let persisted = UserDefaults.standard.string(forKey: Self.userDefaultsKey)
        let validCodes = Self.availableLanguages.map { $0.code }
        
        if let persisted, validCodes.contains(persisted) {
            self.currentLanguage = persisted
        } else {
            self.currentLanguage = "zh-CN"
        }
        
        super.init()
    }
    
    func setLanguage(_ code: String) {
        guard Self.availableLanguages.contains(where: { $0.code == code }) else {
            return
        }
        
        currentLanguage = code
        UserDefaults.standard.set(code, forKey: Self.userDefaultsKey)
    }
}
