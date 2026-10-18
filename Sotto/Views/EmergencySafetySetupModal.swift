import SwiftUI

public struct EmergencySafetySetupModal: View {
    @Environment(\.sottoPalette) private var palette
    public let phrase: Phrase
    public let voiceSettings: VoiceSettings
    public let onSavePhrase: (Phrase) -> Void
    public var onSpeakAnyway: ((Phrase) -> Void)? = nil
    public let onDismiss: () -> Void
    
    @State private var area: String = ""
    @State private var contactName: String = ""
    @State private var phone: String = ""
    
    public init(
        phrase: Phrase,
        voiceSettings: VoiceSettings,
        onSavePhrase: @escaping (Phrase) -> Void,
        onSpeakAnyway: ((Phrase) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.phrase = phrase
        self.voiceSettings = voiceSettings
        self.onSavePhrase = onSavePhrase
        self.onSpeakAnyway = onSpeakAnyway
        self.onDismiss = onDismiss
    }
    
    private var isIndonesian: Bool {
        let lang = LocaleHelper.getEffectiveLanguage(appLanguage: voiceSettings.appLanguage)
        return lang == LocaleHelper.langIndonesian || lang == "in"
    }
    
    private var canSave: Bool {
        !area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                palette.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 10) {
                            SottoIconView(.shield, size: 22, tint: SottoTheme.safetyBadgeText)
                            Text(isIndonesian
                                 ? "Tambahkan area dan nomor telepon darurat agar kartu ini membacakan detail nyata saat darurat."
                                 : "Add your area and emergency contact phone number so this card can speak your real details in distress.")
                                .font(.subheadline)
                                .foregroundColor(palette.textSecondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SottoTheme.safetyBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(SottoTheme.safetyBorder.opacity(0.7), lineWidth: 1)
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(isIndonesian ? "Area / Lingkungan" : "Area / Neighborhood")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(palette.textPrimary)
                            TextField(
                                "",
                                text: $area,
                                prompt: Text(isIndonesian ? "cth. Jakarta Selatan atau Menteng" : "e.g. South Jakarta or Brooklyn")
                                    .foregroundColor(palette.textSecondary.opacity(0.5))
                            )
                            .padding(12)
                            .background(palette.surface)
                            .foregroundColor(palette.textPrimary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(palette.outlineVariant, lineWidth: 1)
                            )
                            .accessibilityLabel(isIndonesian ? "Area atau Lingkungan" : "Area or Neighborhood")
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(isIndonesian ? "Nama Kontak / Hubungan" : "Contact Name / Relationship")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(palette.textPrimary)
                            TextField(
                                "",
                                text: $contactName,
                                prompt: Text(isIndonesian ? "cth. Ibu, dr. Alex (opsional)" : "e.g. Mom, Dr. Alex (optional)")
                                    .foregroundColor(palette.textSecondary.opacity(0.5))
                            )
                            .padding(12)
                            .background(palette.surface)
                            .foregroundColor(palette.textPrimary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(palette.outlineVariant, lineWidth: 1)
                            )
                            .accessibilityLabel(isIndonesian ? "Nama Kontak atau Hubungan" : "Contact Name or Relationship")
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(isIndonesian ? "Nomor Telepon Darurat" : "Emergency Phone Number")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(palette.textPrimary)
                            TextField(
                                "",
                                text: $phone,
                                prompt: Text(isIndonesian ? "cth. 08123456789" : "e.g. 08123456789")
                                    .foregroundColor(palette.textSecondary.opacity(0.5))
                            )
                            #if canImport(UIKit)
                            .keyboardType(.phonePad)
                            #endif
                            .padding(12)
                            .background(palette.surface)
                            .foregroundColor(palette.textPrimary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(palette.outlineVariant, lineWidth: 1)
                            )
                            .accessibilityLabel(isIndonesian ? "Nomor Telepon Darurat" : "Emergency Phone Number")
                        }
                        
                        Button(action: saveConfiguredCard) {
                            Text(isIndonesian ? "Simpan Kartu Keselamatan" : "Save Safety Card")
                                .font(.headline.weight(.bold))
                                .foregroundColor(canSave ? palette.background : palette.textSecondary.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 50)
                                .background(canSave ? palette.accent : palette.surfaceVariant)
                                .cornerRadius(12)
                        }
                        .disabled(!canSave)
                        .padding(.top, 6)
                        
                        if let onSpeakAnyway = onSpeakAnyway {
                            Button(action: {
                                onDismiss()
                                onSpeakAnyway(phrase)
                            }) {
                                HStack(spacing: 6) {
                                    SottoIconView(.volumeUp, size: 16, tint: palette.textSecondary)
                                    Text(isIndonesian ? "Bicara Tanpa Mengatur" : "Speak Unconfigured Card Anyway")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(palette.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isIndonesian ? "Atur Kontak Darurat" : "Set Up Emergency Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isIndonesian ? "Batal" : "Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(palette.textSecondary)
                }
            }
        }
    }
    
    private func saveConfiguredCard() {
        let formatted = LocaleHelper.formatSafetyPhrase(
            area: area,
            contactName: contactName,
            phone: phone,
            appLanguage: voiceSettings.appLanguage
        )
        let updated = Phrase(
            id: phrase.id,
            text: formatted.displayText,
            spokenText: formatted.spokenText,
            spokenLanguage: phrase.spokenLanguage,
            language: phrase.language,
            isEmergency: true,
            category: .emergency
        )
        onSavePhrase(updated)
        UsabilityTracker.shared.recordActivation(key: "safety_card_configured", voiceSettings: voiceSettings)
        UsabilityTracker.shared.recordSafetyCardSaved(voiceSettings: voiceSettings)
        onDismiss()
    }
}
