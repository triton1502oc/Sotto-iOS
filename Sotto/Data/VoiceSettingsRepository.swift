import Foundation

public protocol VoiceSettingsRepositoryProtocol {
    func getVoiceSettings() -> VoiceSettings
    func saveVoiceSettings(_ settings: VoiceSettings)
}

public final class UserDefaultsVoiceSettingsRepository: VoiceSettingsRepositoryProtocol {
    private let userDefaults: UserDefaults
    private let keyVoiceSettings = "sotto_voice_prefs"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func getVoiceSettings() -> VoiceSettings {
        guard let data = userDefaults.data(forKey: keyVoiceSettings) else {
            return VoiceSettings()
        }
        do {
            return try JSONDecoder().decode(VoiceSettings.self, from: data)
        } catch {
            return VoiceSettings()
        }
    }
    
    public func saveVoiceSettings(_ settings: VoiceSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: keyVoiceSettings)
        } catch {
            // Ignore encoding errors
        }
    }
}
