import SwiftUI

public struct WelcomeOnboardingModal: View {
    @Environment(\.sottoPalette) private var palette
    public let initialRole: String
    public let emergencyPhrase: Phrase?
    public let voiceSettings: VoiceSettings
    public let onSaveEmergencyPhrase: (Phrase) -> Void
    public let onFinish: (String) -> Void
    
    @State private var currentStep: Int = 1
    @State private var selectedRole: String
    @State private var area: String = ""
    @State private var contactName: String = ""
    @State private var phone: String = ""
    
    public init(
        initialRole: String = VoiceSettings.roleUnset,
        emergencyPhrase: Phrase?,
        voiceSettings: VoiceSettings,
        onSaveEmergencyPhrase: @escaping (Phrase) -> Void,
        onFinish: @escaping (String) -> Void
    ) {
        self.initialRole = initialRole
        self.emergencyPhrase = emergencyPhrase
        self.voiceSettings = voiceSettings
        self.onSaveEmergencyPhrase = onSaveEmergencyPhrase
        self.onFinish = onFinish
        let defaultRole = (initialRole != VoiceSettings.roleUnset && !initialRole.isEmpty)
            ? initialRole
            : VoiceSettings.roleSelf
        _selectedRole = State(initialValue: defaultRole)
    }
    
    private var isIndonesian: Bool {
        let lang = LocaleHelper.getEffectiveLanguage(appLanguage: voiceSettings.appLanguage)
        return lang == LocaleHelper.langIndonesian || lang == "in"
    }
    
    private var canSaveSafety: Bool {
        !area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Row: Step indicator & Skip
                HStack {
                    Text(isIndonesian ? "Langkah \(currentStep) dari 3" : "Step \(currentStep) of 3")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(palette.accent)
                    
                    Spacer()
                    
                    Button(action: skipAndFinish) {
                        Text(isIndonesian ? "Lewati" : "Skip")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(palette.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel(isIndonesian ? "Lewati pengenalan" : "Skip onboarding")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if currentStep == 1 {
                            step1RoleSelection
                        } else if currentStep == 2 {
                            step2SafetySetup
                        } else {
                            step3ReadySummary
                        }
                    }
                    .padding(24)
                }
            }
        }
        .onAppear {
            UsabilityTracker.shared.recordActivation(key: "onboarding_started", voiceSettings: voiceSettings)
        }
    }
    
    @ViewBuilder
    private var step1RoleSelection: some View {
        Text(isIndonesian ? "Selamat Datang di Sotto" : "Welcome to Sotto")
            .font(.title2.weight(.bold))
            .foregroundColor(palette.textPrimary)
        
        Text(isIndonesian
             ? "Untuk siapa Sotto digunakan pada perangkat ini?"
             : "Who is Sotto for on this device?")
            .font(.body)
            .foregroundColor(palette.textSecondary)
        
        let roles: [(key: String, title: String, desc: String)] = [
            (
                VoiceSettings.roleSelf,
                isIndonesian ? "Untuk Saya / AAC" : "For myself / AAC",
                isIndonesian ? "Komunikasi mandiri dengan kartu wicara kontras tinggi" : "Direct communication with high-contrast speech tiles"
            ),
            (
                VoiceSettings.roleCaregiver,
                isIndonesian ? "Pendamping / Mitra" : "Caregiver / Partner",
                isIndonesian ? "Komunikasi terbantu dengan Mode Pendamping & Why Finder" : "Assisted communication with Partner Mode & Why Finder"
            ),
            (
                VoiceSettings.roleProfessional,
                isIndonesian ? "Tenaga Kesehatan / Terapis" : "Healthcare / Therapist",
                isIndonesian ? "Terapi wicara dan dukungan klinis AAC" : "Speech therapy and clinical AAC support"
            )
        ]
        
        ForEach(roles, id: \.key) { item in
            let isSelected = selectedRole == item.key
            Button(action: {
                selectedRole = item.key
                UsabilityTracker.shared.recordRoleSet(role: item.key, voiceSettings: voiceSettings)
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentStep = 2
                }
            }) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(palette.textPrimary)
                    Text(item.desc)
                        .font(.subheadline)
                        .foregroundColor(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 72)
                .background(isSelected ? palette.surfaceVariant : palette.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? palette.accent : palette.outlineVariant, lineWidth: isSelected ? 1.5 : 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
        }
    }
    
    @ViewBuilder
    private var step2SafetySetup: some View {
        Text(isIndonesian ? "Kartu Kontak Darurat" : "Emergency Safety Card")
            .font(.title2.weight(.bold))
            .foregroundColor(palette.textPrimary)
        
        Text(isIndonesian
             ? "Atur kartu darurat agar penolong atau pendamping tahu lokasi dan kontak darurat Anda."
             : "Set up your emergency card so first responders or caregivers know where you live and who to contact.")
            .font(.body)
            .foregroundColor(palette.textSecondary)
        
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
        }
        
        Button(action: {
            let formatted = LocaleHelper.formatSafetyPhrase(
                area: area,
                contactName: contactName,
                phone: phone,
                appLanguage: voiceSettings.appLanguage
            )
            let updated = Phrase(
                id: emergencyPhrase?.id ?? UUID(),
                text: formatted.displayText,
                spokenText: formatted.spokenText,
                spokenLanguage: emergencyPhrase?.spokenLanguage,
                language: emergencyPhrase?.language ?? LocaleHelper.langAuto,
                isEmergency: true,
                category: .emergency
            )
            onSaveEmergencyPhrase(updated)
            UsabilityTracker.shared.recordActivation(key: "safety_card_configured", voiceSettings: voiceSettings)
            UsabilityTracker.shared.recordSafetyCardSaved(voiceSettings: voiceSettings)
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStep = 3
            }
        }) {
            Text(isIndonesian ? "Simpan Kartu Darurat" : "Save Emergency Card")
                .font(.headline.weight(.bold))
                .foregroundColor(canSaveSafety ? palette.background : palette.textSecondary.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(canSaveSafety ? palette.accent : palette.surfaceVariant)
                .cornerRadius(12)
        }
        .disabled(!canSaveSafety)
        .padding(.top, 4)
        
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentStep = 1
                }
            }) {
                Text(isIndonesian ? "Kembali" : "Back")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(palette.textSecondary)
                    .frame(minHeight: 44)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentStep = 3
                }
            }) {
                Text(isIndonesian ? "Lewati Sekarang" : "Skip for Later")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(palette.accent)
                    .frame(minHeight: 44)
            }
        }
    }
    
    @ViewBuilder
    private var step3ReadySummary: some View {
        Text(isIndonesian ? "Semua Siap!" : "You're All Set!")
            .font(.title2.weight(.bold))
            .foregroundColor(palette.textPrimary)
        
        HStack(spacing: 16) {
            SottoIconView(
                selectedRole == VoiceSettings.roleCaregiver ? .partnerMode : .volumeUp,
                size: 32,
                tint: palette.accent
            )
            Text(selectedRole == VoiceSettings.roleCaregiver
                 ? (isIndonesian
                    ? "Mode Pendamping tersedia di bagian atas papan untuk bantuan krisis dan percakapan dua arah."
                    : "Partner Mode is available at the top of your board for crisis support and two-way conversations.")
                 : (isIndonesian
                    ? "Papan AAC Anda siap. Ketuk kartu apa pun untuk berbicara, atau tekan lama untuk layar penuh."
                    : "Your AAC board is ready. Tap any card to speak, or long press to view in full screen."))
                .font(.body)
                .foregroundColor(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surfaceVariant)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(palette.outlineVariant, lineWidth: 1)
        )
        
        Button(action: {
            UsabilityTracker.shared.recordRoleSet(role: selectedRole, voiceSettings: voiceSettings)
            UsabilityTracker.shared.recordActivation(key: "onboarding_completed", voiceSettings: voiceSettings)
            onFinish(selectedRole)
        }) {
            Text(isIndonesian ? "Mulai Gunakan" : "Get Started")
                .font(.headline.weight(.bold))
                .foregroundColor(palette.background)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(palette.accent)
                .cornerRadius(12)
        }
        .padding(.top, 8)
    }
    
    private func skipAndFinish() {
        let roleToSave = (!selectedRole.isEmpty && selectedRole != VoiceSettings.roleUnset)
            ? selectedRole
            : VoiceSettings.roleSelf
        UsabilityTracker.shared.recordRoleSet(role: roleToSave, voiceSettings: voiceSettings)
        UsabilityTracker.shared.recordActivation(key: "onboarding_completed", voiceSettings: voiceSettings)
        onFinish(roleToSave)
    }
}
