import Foundation

public struct VoiceSettings: Codable, Equatable {
    public var speechRate: Float
    public var speechPitch: Float
    public var voiceIdentifier: String?
    public var appLanguage: String
    public var playAttentionChime: Bool
    public var showLanguageSwitcher: Bool
    public var secondaryLanguage: String
    public var shareUsabilityMetrics: Bool
    public var userRole: String
    public var appTheme: String
    public var showSafetyCards: Bool
    
    public static let roleUnset = "unset"
    public static let roleCaregiver = "caregiver"
    public static let roleSelf = "self"
    public static let roleProfessional = "professional"

    public static let themeCharcoal = "charcoal"
    public static let themeOledBlack = "oled_black"
    public static let themeWarmAmber = "warm_amber"
    public static let themeSlateNavy = "slate_navy"
    public static let themeSoftParchment = "soft_parchment"
    
    public init(
        speechRate: Float = 1.0,
        speechPitch: Float = 1.0,
        voiceIdentifier: String? = nil,
        appLanguage: String = "system",
        playAttentionChime: Bool = false,
        showLanguageSwitcher: Bool = false,
        secondaryLanguage: String = "id",
        shareUsabilityMetrics: Bool = false,
        userRole: String = "unset",
        appTheme: String = VoiceSettings.themeCharcoal,
        showSafetyCards: Bool = true
    ) {
        self.speechRate = speechRate
        self.speechPitch = speechPitch
        self.voiceIdentifier = voiceIdentifier
        self.appLanguage = appLanguage
        self.playAttentionChime = playAttentionChime
        self.showLanguageSwitcher = showLanguageSwitcher
        self.secondaryLanguage = secondaryLanguage
        self.shareUsabilityMetrics = shareUsabilityMetrics
        self.userRole = userRole
        self.appTheme = appTheme
        self.showSafetyCards = showSafetyCards
    }
    
    public init(
        speechRate: Float = 1.0,
        speechPitch: Float = 1.0,
        voiceIdentifier: String? = nil,
        appLanguage: String = "system",
        playAttentionChime: Bool = false,
        showLanguageSwitcher: Bool = false,
        secondaryLanguage: String = "id"
    ) {
        self.init(
            speechRate: speechRate,
            speechPitch: speechPitch,
            voiceIdentifier: voiceIdentifier,
            appLanguage: appLanguage,
            playAttentionChime: playAttentionChime,
            showLanguageSwitcher: showLanguageSwitcher,
            secondaryLanguage: secondaryLanguage,
            shareUsabilityMetrics: false,
            userRole: "unset",
            appTheme: VoiceSettings.themeCharcoal,
            showSafetyCards: true
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case speechRate, speechPitch, voiceIdentifier, appLanguage, playAttentionChime, showLanguageSwitcher, secondaryLanguage, shareUsabilityMetrics, userRole, appTheme, showSafetyCards
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
        self.shareUsabilityMetrics = try container.decodeIfPresent(Bool.self, forKey: .shareUsabilityMetrics) ?? false
        self.userRole = try container.decodeIfPresent(String.self, forKey: .userRole) ?? "unset"
        self.appTheme = try container.decodeIfPresent(String.self, forKey: .appTheme) ?? VoiceSettings.themeCharcoal
        self.showSafetyCards = try container.decodeIfPresent(Bool.self, forKey: .showSafetyCards) ?? true
    }
}
