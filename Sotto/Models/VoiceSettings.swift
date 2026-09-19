import Foundation

public struct VoiceSettings: Codable, Equatable {
    public var speechRate: Float
    public var speechPitch: Float
    public var voiceIdentifier: String?
    public var appLanguage: String
    public var playAttentionChime: Bool
    
    public init(
        speechRate: Float = 1.0,
        speechPitch: Float = 1.0,
        voiceIdentifier: String? = nil,
        appLanguage: String = "system",
        playAttentionChime: Bool = false
    ) {
        self.speechRate = speechRate
        self.speechPitch = speechPitch
        self.voiceIdentifier = voiceIdentifier
        self.appLanguage = appLanguage
        self.playAttentionChime = playAttentionChime
    }
}
