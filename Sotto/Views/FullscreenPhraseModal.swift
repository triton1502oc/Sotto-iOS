import SwiftUI

public struct FullscreenPhraseModal: View {
    @Environment(\.sottoPalette) private var palette
    public let phrase: Phrase
    public let voiceSettings: VoiceSettings
    public let onSpeak: (Phrase) -> Void
    public let onSpeakSecondary: ((Phrase) -> Void)?
    public let onOpenPartnerMode: (() -> Void)?
    public let onDismiss: () -> Void
    
    public init(
        phrase: Phrase,
        voiceSettings: VoiceSettings = VoiceSettings(),
        onSpeak: @escaping (Phrase) -> Void,
        onSpeakSecondary: ((Phrase) -> Void)? = nil,
        onOpenPartnerMode: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.phrase = phrase
        self.voiceSettings = voiceSettings
        self.onSpeak = onSpeak
        self.onSpeakSecondary = onSpeakSecondary
        self.onOpenPartnerMode = onOpenPartnerMode
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
            (isEmergency ? SottoTheme.emergencyBackground : palette.background)
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
                    
                    HStack(spacing: 8) {
                        Spacer()
                        Button(action: {
                            let isId = LocaleHelper.getEffectiveLanguage(appLanguage: voiceSettings.appLanguage) == LocaleHelper.langIndonesian
                            let badge = isEmergency
                                ? LocaleHelper.getCategoryDisplayName("EMERGENCY", appLanguage: voiceSettings.appLanguage)
                                : LocaleHelper.getCategoryDisplayName(phrase.category.rawValue, appLanguage: voiceSettings.appLanguage)
                            let footer = isId ? "Sotto • Komunikasi Asistif" : "Sotto • Assistive Communication"
                            let spec = ShareableCardSpec(
                                primaryText: phrase.text,
                                secondaryText: hasSpokenText ? phrase.spokenText : nil,
                                badgeLabel: badge,
                                isEmergency: isEmergency,
                                footerBrandText: footer
                            )
                            CardShareHelper.shareCard(spec, sourceTag: "fullscreen_card", voiceSettings: voiceSettings)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(isEmergency ? SottoTheme.emergencyBorder : palette.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(LocaleHelper.getEffectiveLanguage(appLanguage: voiceSettings.appLanguage) == LocaleHelper.langIndonesian ? "Bagikan kartu frasa sebagai gambar" : "Share phrase card as image")
                        .demoTarget("fullscreen_shareButton")
                        
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
                        .foregroundColor(isEmergency ? SottoTheme.emergencyText : palette.textPrimary)
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
                                .foregroundColor(palette.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(palette.surfaceVariant.opacity(0.8))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                }
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    if isEmergency, let openPartner = onOpenPartnerMode {
                        Button(action: {
                            onDismiss()
                            openPartner()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text(voiceSettings.appLanguage == "id" ? "Buka Mode Mitra (Tanya Jawab)" : "Communicate with Partner")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundColor(Color(hex: 0x1E1710))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(SottoTheme.emergencyAccent)
                            .cornerRadius(14)
                        }
                        .demoTarget("fullscreen_partnerModeCTA")
                        .accessibilityLabel(voiceSettings.appLanguage == "id" ? "Buka Mode Mitra" : "Communicate with Partner")
                        .accessibilityHint(voiceSettings.appLanguage == "id" ? "Buka Tanya Jawab Ya atau Tidak untuk berkomunikasi" : "Opens direct Yes/No check-in to communicate")
                    }

                    if hasSpokenText {
                        HStack(spacing: 12) {
                            Button(action: {
                                onSpeak(phrase)
                            }) {
                                Text("Speak (\(primaryLangLabel))")
                                    .font(.system(size: 15, weight: .bold))
                                    .lineLimit(1)
                                    .foregroundColor(isEmergency ? Color(hex: 0x1E1710) : palette.background)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(isEmergency ? SottoTheme.emergencyBorder : palette.accent)
                                    .cornerRadius(16)
                            }
                            .demoTarget("fullscreen_speakPrimary")
                            
                            Button(action: {
                                onSpeakSecondary?(phrase)
                            }) {
                                Text("Speak (\(secondaryLangLabel))")
                                    .font(.system(size: 15, weight: .bold))
                                    .lineLimit(1)
                                    .foregroundColor(palette.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(palette.surfaceVariant)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(palette.outlineVariant, lineWidth: 1)
                                    )
                            }
                            .demoTarget("fullscreen_speakSecondary")
                        }
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
                            .foregroundColor(isEmergency ? Color(hex: 0x1E1710) : palette.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(isEmergency ? SottoTheme.emergencyBorder : palette.accent)
                            .cornerRadius(16)
                        }
                        .demoTarget("fullscreen_speakButton")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
