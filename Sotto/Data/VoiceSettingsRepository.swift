import Foundation

public protocol VoiceSettingsRepositoryProtocol {
    func getVoiceSettings() -> VoiceSettings
    func saveVoiceSettings(_ settings: VoiceSettings)
    func getLastPromptedMetricsVersion() -> Int
    func setLastPromptedMetricsVersion(_ versionCode: Int)
    func getInstallId() -> String?
    func getOrGenerateInstallId() -> String
    func clearInstallId()
    func hasPromptedRole() -> Bool
    func setPromptedRole(_ prompted: Bool)
    func getFirstInstalledAt() -> Int64
    func recordActiveDay(_ todayDate: String)
    func getActiveDayCount() -> Int
    func hasPromptedPmfSurvey() -> Bool
    func setPromptedPmfSurvey(_ prompted: Bool)
    func shouldPromptPmfSurvey() -> Bool
}

public final class UserDefaultsVoiceSettingsRepository: VoiceSettingsRepositoryProtocol {
    private let userDefaults: UserDefaults
    private let keyVoiceSettings = "sotto_voice_prefs"
    private let keyMetricsPromptVersion = "metrics_prompt_version_code"
    private let keyInstallId = "telemetry_install_id"
    private let keyRolePrompted = "role_prompted"
    private let keyFirstInstalledAt = "first_installed_at"
    private let keyActiveDays = "active_days"
    private let keyPmfSurveyPrompted = "pmf_survey_prompted"
    
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
        let wasMetricsEnabled = getVoiceSettings().shareUsabilityMetrics
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: keyVoiceSettings)
            userDefaults.set(settings.appTheme, forKey: "sotto_app_theme")
        } catch {
            // Ignore encoding errors
        }
        
        if settings.shareUsabilityMetrics {
            _ = getOrGenerateInstallId()
        } else if wasMetricsEnabled {
            clearInstallId()
            UsabilityTracker.shared.clearBuffer()
        }
    }
    
    public func getLastPromptedMetricsVersion() -> Int {
        return userDefaults.integer(forKey: keyMetricsPromptVersion)
    }
    
    public func setLastPromptedMetricsVersion(_ versionCode: Int) {
        userDefaults.set(versionCode, forKey: keyMetricsPromptVersion)
    }
    
    public func getInstallId() -> String? {
        return userDefaults.string(forKey: keyInstallId)
    }
    
    public func getOrGenerateInstallId() -> String {
        if let existing = userDefaults.string(forKey: keyInstallId), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: keyInstallId)
        return newId
    }
    
    public func clearInstallId() {
        userDefaults.removeObject(forKey: keyInstallId)
    }
    
    public func hasPromptedRole() -> Bool {
        return userDefaults.bool(forKey: keyRolePrompted)
    }
    
    public func setPromptedRole(_ prompted: Bool) {
        userDefaults.set(prompted, forKey: keyRolePrompted)
    }
    
    public func getFirstInstalledAt() -> Int64 {
        let existing = userDefaults.object(forKey: keyFirstInstalledAt) as? Int64
        if let existing = existing, existing > 0 {
            return existing
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        userDefaults.set(now, forKey: keyFirstInstalledAt)
        return now
    }
    
    public func recordActiveDay(_ todayDate: String) {
        var days = Set(userDefaults.stringArray(forKey: keyActiveDays) ?? [])
        if !days.contains(todayDate) {
            days.insert(todayDate)
            userDefaults.set(Array(days), forKey: keyActiveDays)
        }
    }
    
    public func getActiveDayCount() -> Int {
        return (userDefaults.stringArray(forKey: keyActiveDays) ?? []).count
    }
    
    public func hasPromptedPmfSurvey() -> Bool {
        return userDefaults.bool(forKey: keyPmfSurveyPrompted)
    }
    
    public func setPromptedPmfSurvey(_ prompted: Bool) {
        userDefaults.set(prompted, forKey: keyPmfSurveyPrompted)
    }
    
    public func shouldPromptPmfSurvey() -> Bool {
        let settings = getVoiceSettings()
        guard settings.shareUsabilityMetrics else { return false }
        guard !hasPromptedPmfSurvey() else { return false }
        let installAge = Int64(Date().timeIntervalSince1970 * 1000) - getFirstInstalledAt()
        let days14Ms: Int64 = 14 * 24 * 60 * 60 * 1000
        return installAge >= days14Ms && getActiveDayCount() >= 5
    }
}
