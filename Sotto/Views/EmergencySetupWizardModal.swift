import SwiftUI

public struct EmergencySetupWizardModal: View {
    public let appLanguage: String
    public let initialArea: String
    public let initialContact: String
    public let onSave: (_ visualText: String, _ spokenText: String) -> Void
    public let onSkip: () -> Void
    
    @State private var area: String
    @State private var contact: String
    
    public init(
        appLanguage: String = "system",
        initialArea: String = "",
        initialContact: String = "",
        onSave: @escaping (_ visualText: String, _ spokenText: String) -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.appLanguage = appLanguage
        self.initialArea = initialArea
        self.initialContact = initialContact
        self.onSave = onSave
        self.onSkip = onSkip
        
        _area = State(initialValue: initialArea)
        _contact = State(initialValue: initialContact)
    }
    
    private var isIndonesian: Bool {
        LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage) == LocaleHelper.langIndonesian
    }
    
    private var previewText: String {
        LocaleHelper.formatEmergencyPhrase(area: area, contact: contact, appLanguage: appLanguage)
    }
    
    private var canSave: Bool {
        !area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Guidance
                        VStack(alignment: .leading, spacing: 6) {
                            Text(isIndonesian ? "Atur Kartu Keselamatan Darurat" : "Emergency Safety Card Setup")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            Text(isIndonesian
                                 ? "Sotto memiliki kartu keselamatan untuk situasi krisis. Masukkan area tinggal dan nomor kontak agar mudah dihubungi jika diperlukan."
                                 : "Sotto includes a safety card for acute crises or shutdowns. Enter your area and emergency contact so helpers know who to reach.")
                                .font(.system(size: 14))
                                .foregroundColor(SottoTheme.textSecondary)
                                .lineSpacing(3)
                        }
                        
                        // Live Card Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isIndonesian ? "Pratinjau Kartu:" : "Card Live Preview:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(SottoTheme.textSecondary)
                            
                            VStack(spacing: 8) {
                                HStack(spacing: 6) {
                                    Text("🛡️")
                                        .font(.system(size: 16))
                                    Text(LocaleHelper.getCategoryDisplayName("EMERGENCY", appLanguage: appLanguage))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(SottoTheme.safetyBadgeText)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(SottoTheme.safetyBadgeBg)
                                .cornerRadius(6)
                                
                                Text(previewText)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SottoTheme.safetyText)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, 12)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 14)
                            .background(SottoTheme.safetyBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(SottoTheme.safetyBorder.opacity(0.8), lineWidth: 1)
                            )
                        }
                        .padding(.top, 4)
                        
                        // Form Input Fields
                        VStack(spacing: 16) {
                            // Step 1: Area
                            VStack(alignment: .leading, spacing: 6) {
                                Text(isIndonesian ? "1. Area / Lingkungan Tempat Tinggal" : "1. Area / Neighborhood / City")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(SottoTheme.textPrimary)
                                
                                TextField(
                                    isIndonesian ? "Contoh: Jakarta Selatan, Kebayoran" : "e.g., Brooklyn, NY or Capitol Hill",
                                    text: $area
                                )
                                .font(.system(size: 15))
                                .padding(12)
                                .background(SottoTheme.surfaceVariant)
                                .cornerRadius(10)
                                .foregroundColor(SottoTheme.textPrimary)
                            }
                            
                            // Step 2: Contact
                            VStack(alignment: .leading, spacing: 6) {
                                Text(isIndonesian ? "2. Nama & Nomor Kontak Darurat" : "2. Emergency Contact Name & Phone")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(SottoTheme.textPrimary)
                                
                                TextField(
                                    isIndonesian ? "Contoh: Ibu: 0812-3456-7890" : "e.g., Mom: 555-019-2831",
                                    text: $contact
                                )
                                .font(.system(size: 15))
                                .padding(12)
                                .background(SottoTheme.surfaceVariant)
                                .cornerRadius(10)
                                .foregroundColor(SottoTheme.textPrimary)
                                
                                // Phone number formatting advice
                                Text(isIndonesian
                                     ? "💡 Tips: Pisahkan nomor dengan strip (-) seperti 0812-3456-7890 agar dibaca jelas per digit oleh suara pembicara."
                                     : "💡 Tip: Separate numbers with dashes (-) like 555-019-2831 so speech reads each digit clearly as a phone number.")
                                    .font(.system(size: 12))
                                    .foregroundColor(SottoTheme.textSecondary)
                                    .padding(.top, 2)
                                
                                // Example pre-fill button
                                Button(action: {
                                    if contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        contact = isIndonesian ? "Ibu: 0812-3456-7890" : "Mom: 555-019-2831"
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 12))
                                        Text(isIndonesian ? "Gunakan format contoh: Ibu: 0812-3456-7890" : "Use example format: Mom: 555-019-2831")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(SottoTheme.primary)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.top, 4)
                        
                        // Actions
                        VStack(spacing: 12) {
                            Button(action: {
                                let spoken = LocaleHelper.formatEmergencyPhraseForSpeech(area: area, contact: contact, appLanguage: appLanguage)
                                onSave(previewText, spoken)
                            }) {
                                Text(isIndonesian ? "Simpan Kartu Keselamatan" : "Save Safety Card")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(SottoTheme.onPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(canSave ? SottoTheme.primary : SottoTheme.surfaceVariant)
                                    .cornerRadius(12)
                            }
                            .disabled(!canSave)
                            
                            Button(action: {
                                onSkip()
                            }) {
                                Text(isIndonesian ? "Atur Nanti di Pengaturan" : "Set Up Later in Settings")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SottoTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isIndonesian ? "Kartu Keselamatan" : "Safety Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isIndonesian ? "Tutup" : "Close") {
                        onSkip()
                    }
                    .foregroundColor(SottoTheme.textSecondary)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
