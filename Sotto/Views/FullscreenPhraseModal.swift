import SwiftUI

public struct FullscreenPhraseModal: View {
    public let phrase: Phrase
    public let voiceSettings: VoiceSettings
    public let onSpeak: (Phrase) -> Void
    public let onSpeakSecondary: ((Phrase) -> Void)?
    public let onDismiss: () -> Void
    
    public init(
        phrase: Phrase,
        voiceSettings: VoiceSettings = VoiceSettings(),
        onSpeak: @escaping (Phrase) -> Void,
        onSpeakSecondary: ((Phrase) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.phrase = phrase
        self.voiceSettings = voiceSettings
        self.onSpeak = onSpeak
        self.onSpeakSecondary = onSpeakSecondary
        self.onDismiss = onDismiss
    }
    
    private var isEmergency: Bool {
        phrase.isEmergency
    }
    
    private var hasSpokenText: Bool {
        guard voiceSettings.showLanguageSwitcher,
              let spoken = phrase.spokenText?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !spoken.isEmpty
    }
    
    private var primaryLangLabel: String {
        let locale = LocaleHelper.resolvePhraseLocale(
            phraseLang: phrase.language,
            phraseText: phrase.text,
            appLanguage: voiceSettings.appLanguage
        )
        let name = locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
        return name.capitalized
    }
    
    private var secondaryLangLabel: String {
        let spokenLang = phrase.spokenLanguage ?? voiceSettings.secondaryLanguage
        let locale = LocaleHelper.resolvePhraseLocale(
            phraseLang: spokenLang,
            phraseText: phrase.spokenText ?? "",
            appLanguage: voiceSettings.appLanguage
        )
        let name = locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
        return name.capitalized
    }
    
    public var body: some View {
        ZStack {
            (isEmergency ? Color(hex: 0x1E1710) : SottoTheme.background)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top Bar with Optional Emergency Badge and Dismiss Button
                ZStack {
                    if isEmergency {
                        HStack(spacing: 6) {
                            Text("🛡️")
                            Text(LocaleHelper.getCategoryDisplayName("EMERGENCY", appLanguage: voiceSettings.appLanguage))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(SottoTheme.safetyBadgeText)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(SottoTheme.safetyBadgeBg)
                        .cornerRadius(8)
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isEmergency ? SottoTheme.emergencyBorder : SottoTheme.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .demoTarget("fullscreen_dismissButton")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Giant High-Contrast Phrase Text
                Spacer()
                VStack(spacing: 16) {
                    Text(phrase.text)
                        .font(.system(size: (isEmergency && phrase.text.count > 60) ? 36 : 48, weight: .bold))
                        .foregroundColor(isEmergency ? SottoTheme.emergencyText : SottoTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 24)
                    
                    if hasSpokenText, let spoken = phrase.spokenText {
                        HStack(spacing: 8) {
                            Text("🗣️")
                                .font(.system(size: 20))
                            Text(spoken)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(SottoTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(SottoTheme.surfaceVariant.opacity(0.6))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                }
                Spacer()
                
                // Action Buttons
                if hasSpokenText {
                    HStack(spacing: 12) {
                        Button(action: {
                            onSpeak(phrase)
                        }) {
                            Text("Speak (\(primaryLangLabel))")
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1)
                                .foregroundColor(isEmergency ? Color(hex: 0x1E1710) : SottoTheme.onPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(isEmergency ? SottoTheme.emergencyBorder : SottoTheme.primary)
                                .cornerRadius(16)
                        }
                        .demoTarget("fullscreen_speakPrimary")
                        
                        Button(action: {
                            onSpeakSecondary?(phrase)
                        }) {
                            Text("Speak (\(secondaryLangLabel))")
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1)
                                .foregroundColor(SottoTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(SottoTheme.surfaceVariant)
                                .cornerRadius(16)
                        }
                        .demoTarget("fullscreen_speakSecondary")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                } else {
                    Button(action: {
                        onSpeak(phrase)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 22, weight: .bold))
                            Text("Speak Aloud")
                                .font(.system(size: 22, weight: .bold))
                        }
                        .foregroundColor(isEmergency ? Color(hex: 0x1E1710) : SottoTheme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(isEmergency ? SottoTheme.emergencyBorder : SottoTheme.primary)
                        .cornerRadius(16)
                    }
                    .demoTarget("fullscreen_speakButton")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .overlay(
            Group {
                if isEmergency {
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(SottoTheme.emergencyBorder, lineWidth: 2)
                        .ignoresSafeArea()
                }
            }
        )
    }
}
