import Foundation

public struct VoiceSettings: Codable, Equatable {
    public var speechRate: Float
    public var speechPitch: Float
    public var voiceIdentifier: String?
    public var appLanguage: String
    public var playAttentionChime: Bool
    public var showLanguageSwitcher: Bool
    public var secondaryLanguage: String
    
    public init(
        speechRate: Float = 1.0,
        speechPitch: Float = 1.0,
        voiceIdentifier: String? = nil,
        appLanguage: String = "system",
        playAttentionChime: Bool = false,
        showLanguageSwitcher: Bool = false,
        secondaryLanguage: String = "id"
    ) {
        self.speechRate = speechRate
        self.speechPitch = speechPitch
        self.voiceIdentifier = voiceIdentifier
        self.appLanguage = appLanguage
        self.playAttentionChime = playAttentionChime
        self.showLanguageSwitcher = showLanguageSwitcher
        self.secondaryLanguage = secondaryLanguage
    }
    
    enum CodingKeys: String, CodingKey {
        case speechRate, speechPitch, voiceIdentifier, appLanguage, playAttentionChime, showLanguageSwitcher, secondaryLanguage
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.speechRate = try container.decodeIfPresent(Float.self, forKey: .speechRate) ?? 1.0
        self.speechPitch = try container.decodeIfPresent(Float.self, forKey: .speechPitch) ?? 1.0
        self.voiceIdentifier = try container.decodeIfPresent(String.self, forKey: .voiceIdentifier)
        self.appLanguage = try container.decodeIfPresent(String.self, forKey: .appLanguage) ?? "system"
        self.playAttentionChime = try container.decodeIfPresent(Bool.self, forKey: .playAttentionChime) ?? false
        self.showLanguageSwitcher = try container.decodeIfPresent(Bool.self, forKey: .showLanguageSwitcher) ?? false
        self.secondaryLanguage = try container.decodeIfPresent(String.self, forKey: .secondaryLanguage) ?? "id"
    }
}
