import SwiftUI
import AVFoundation

public struct VoiceSettingsModal: View {
    @Binding public var settings: VoiceSettings
    public let onTestVoice: (VoiceSettings) -> Void
    public var onOpenWhyLog: (() -> Void)?
    public var onOpenWhyTreeEditor: (() -> Void)?
    public var onExportPhrases: (() -> Void)?
    public var onImportPhrases: (() -> Void)?
    public let onDismiss: () -> Void
    
    @State private var speed: Float
    @State private var pitch: Float
    @State private var attentionChime: Bool
    @State private var selectedLanguage: String
    @State private var showLanguageSwitcher: Bool
    @State private var secondaryLanguage: String
    @State private var shareUsabilityMetrics: Bool
    @State private var userRole: String
    @State private var showSharedDataSheet: Bool = false
    @State private var availableLanguages: [(code: String, name: String)] = []
    
    public init(
        settings: Binding<VoiceSettings>,
        onTestVoice: @escaping (VoiceSettings) -> Void,
        onOpenWhyLog: (() -> Void)? = nil,
        onOpenWhyTreeEditor: (() -> Void)? = nil,
        onExportPhrases: (() -> Void)? = nil,
        onImportPhrases: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self._settings = settings
        self.onTestVoice = onTestVoice
        self.onOpenWhyLog = onOpenWhyLog
        self.onOpenWhyTreeEditor = onOpenWhyTreeEditor
        self.onExportPhrases = onExportPhrases
        self.onImportPhrases = onImportPhrases
        self.onDismiss = onDismiss
        
        _speed = State(initialValue: settings.wrappedValue.speechRate)
        _pitch = State(initialValue: settings.wrappedValue.speechPitch)
        _attentionChime = State(initialValue: settings.wrappedValue.playAttentionChime)
        _selectedLanguage = State(initialValue: settings.wrappedValue.appLanguage)
        _showLanguageSwitcher = State(initialValue: settings.wrappedValue.showLanguageSwitcher)
        _secondaryLanguage = State(initialValue: settings.wrappedValue.secondaryLanguage)
        _shareUsabilityMetrics = State(initialValue: settings.wrappedValue.shareUsabilityMetrics)
        _userRole = State(initialValue: settings.wrappedValue.userRole)
    }
    
    private var speedLabel: String {
        let text: String
        if speed <= 0.7 { text = "Slower" }
        else if speed >= 0.9 && speed <= 1.1 { text = "Normal" }
        else if speed >= 1.3 { text = "Faster" }
        else { text = "" }
        let formatted = String(format: "%.1fx", speed)
        return text.isEmpty ? formatted : "\(formatted) (\(text))"
    }
    
    private var pitchLabel: String {
        let text: String
        if pitch <= 0.8 { text = "Lower" }
        else if pitch >= 0.95 && pitch <= 1.05 { text = "Normal" }
        else if pitch >= 1.2 { text = "Higher" }
        else { text = "" }
        let formatted = String(format: "%.1fx", pitch)
        return text.isEmpty ? formatted : "\(formatted) (\(text))"
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Section 1: Speech & Voice
                        VStack(alignment: .leading, spacing: 14) {
                            Text("🗣️ Speech & Voice")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            // App Language Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("App Language")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SottoTheme.textSecondary)
                                
                                Menu {
                                    ForEach(availableLanguages, id: \.code) { item in
                                        Button(action: {
                                            selectedLanguage = item.code
                                            applyChanges()
                                        }) {
                                            HStack {
                                                Text(item.name)
                                                if selectedLanguage == item.code {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(LocaleHelper.getLanguageDisplayName(selectedLanguage))
                                            .foregroundColor(SottoTheme.textPrimary)
                                            .font(.system(size: 15))
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 13))
                                            .foregroundColor(SottoTheme.textSecondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(SottoTheme.background)
                                    .cornerRadius(10)
                                }
                            }
                            
                            // Speech Rate Slider
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Speed: \(speedLabel)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SottoTheme.textSecondary)
                                
                                Slider(
                                    value: Binding(
                                        get: { speed },
                                        set: { newValue in
                                            speed = round(newValue * 10) / 10
                                            applyChanges()
                                        }
                                    ),
                                    in: 0.5...2.0,
                                    step: 0.1
                                )
                                .tint(SottoTheme.primary)
                            }
                            
                            // Speech Pitch Slider
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pitch: \(pitchLabel)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SottoTheme.textSecondary)
                                
                                Slider(
                                    value: Binding(
                                        get: { pitch },
                                        set: { newValue in
                                            pitch = round(newValue * 10) / 10
                                            applyChanges()
                                        }
                                    ),
                                    in: 0.7...1.3,
                                    step: 0.1
                                )
                                .tint(SottoTheme.primary)
                            }
                            
                            // Attention Chime Toggle
                            Toggle(isOn: Binding(
                                get: { attentionChime },
                                set: { newValue in
                                    attentionChime = newValue
                                    applyChanges()
                                    if newValue {
                                        ChimePlayer.shared.play()
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Attention chime before speaking")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(SottoTheme.textPrimary)
                                    Text("Plays a brief chime to alert listeners before speaking")
                                        .font(.system(size: 13))
                                        .foregroundColor(SottoTheme.textSecondary)
                                }
                            }
                            .tint(SottoTheme.primary)
                            .demoTarget("voice_chimeToggle")
                            
                            // Test Voice Button
                            Button(action: {
                                let current = VoiceSettings(
                                    speechRate: speed,
                                    speechPitch: pitch,
                                    voiceIdentifier: settings.voiceIdentifier,
                                    appLanguage: selectedLanguage,
                                    playAttentionChime: attentionChime,
                                    showLanguageSwitcher: showLanguageSwitcher,
                                    secondaryLanguage: secondaryLanguage,
                                    shareUsabilityMetrics: shareUsabilityMetrics,
                                    userRole: userRole
                                )
                                onTestVoice(current)
                            }) {
                                Text("🔊  Test Voice")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(SottoTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(SottoTheme.background)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }
                            .demoTarget("voice_testVoiceButton")
                        }
                        
                        Divider().background(Color.white.opacity(0.12))
                        
                        // Section 2: Dual-Language Speech
                        VStack(alignment: .leading, spacing: 14) {
                            Text("🌐 Dual-Language Speech")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            Toggle(isOn: Binding(
                                get: { showLanguageSwitcher },
                                set: { newValue in
                                    showLanguageSwitcher = newValue
                                    applyChanges()
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Show language switcher on home")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(SottoTheme.textPrimary)
                                    Text("Adds a toggle in the top bar to switch speech language")
                                        .font(.system(size: 13))
                                        .foregroundColor(SottoTheme.textSecondary)
                                }
                            }
                            .tint(SottoTheme.primary)
                            .demoTarget("voice_dualLanguageToggle")
                            
                            if showLanguageSwitcher {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Secondary speech language")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SottoTheme.textSecondary)
                                    
                                    Menu {
                                        ForEach(availableLanguages.filter { $0.code != LocaleHelper.langSystem }, id: \.code) { item in
                                            Button(action: {
                                                secondaryLanguage = item.code
                                                applyChanges()
                                            }) {
                                                HStack {
                                                    Text(item.name)
                                                    if secondaryLanguage == item.code {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(LocaleHelper.getLanguageDisplayName(secondaryLanguage))
                                                .foregroundColor(SottoTheme.textPrimary)
                                                .font(.system(size: 15))
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 13))
                                                .foregroundColor(SottoTheme.textSecondary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(SottoTheme.background)
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.12))
                        
                        // Section 3: Guided Tools & Backup
                        VStack(alignment: .leading, spacing: 14) {
                            Text("🧭 Why Finder & Data")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            HStack(spacing: 10) {
                                Button(action: {
                                    onDismiss()
                                    onOpenWhyLog?()
                                }) {
                                    HStack(spacing: 4) {
                                        Text("📋")
                                        Text("Why Log")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(SottoTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(SottoTheme.surfaceVariant.opacity(0.5))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                
                                Button(action: {
                                    onDismiss()
                                    onOpenWhyTreeEditor?()
                                }) {
                                    HStack(spacing: 4) {
                                        Text("🌳")
                                        Text("Why Tree")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(SottoTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(SottoTheme.surfaceVariant.opacity(0.5))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                            
                            HStack(spacing: 10) {
                                Button(action: {
                                    onDismiss()
                                    onExportPhrases?()
                                }) {
                                    HStack(spacing: 4) {
                                        Text("↑")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Export Backup")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(SottoTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(SottoTheme.surfaceVariant.opacity(0.5))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                
                                Button(action: {
                                    onDismiss()
                                    onImportPhrases?()
                                }) {
                                    HStack(spacing: 4) {
                                        Text("↓")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Import Backup")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(SottoTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(SottoTheme.surfaceVariant.opacity(0.5))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.12))
                        
                        // Section 4: Anonymous Usability Analytics
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📊 Anonymous Usability Analytics")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            Toggle(isOn: $shareUsabilityMetrics) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Help improve Sotto")
                                        .font(.system(size: 15))
                                        .foregroundColor(SottoTheme.textPrimary)
                                    Text("Shares anonymous interaction timings to identify usability difficulties. Strictly zero text, phrases, or speech is shared.")
                                        .font(.system(size: 12))
                                        .foregroundColor(SottoTheme.textSecondary.opacity(0.7))
                                }
                            }
                            .tint(SottoTheme.primary)
                            .onChange(of: shareUsabilityMetrics) { _ in
                                applyChanges()
                            }
                            
                            if shareUsabilityMetrics {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("User role")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(SottoTheme.textSecondary)
                                    
                                    HStack(spacing: 8) {
                                        let roles = [
                                            (key: VoiceSettings.roleCaregiver, label: "Caregiver"),
                                            (key: VoiceSettings.roleSelf, label: "Self"),
                                            (key: VoiceSettings.roleProfessional, label: "Professional")
                                        ]
                                        ForEach(roles, id: \.key) { r in
                                            let isSelected = userRole == r.key
                                            Button(action: {
                                                userRole = r.key
                                                applyChanges()
                                                UsabilityTracker.shared.recordRoleSet(role: r.key, voiceSettings: settings)
                                            }) {
                                                Text(r.label)
                                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                                    .foregroundColor(isSelected ? .white : SottoTheme.textSecondary)
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 36)
                                                    .background(isSelected ? SottoTheme.primary : SottoTheme.surfaceVariant)
                                                    .cornerRadius(18)
                                            }
                                        }
                                    }
                                    
                                    Button(action: {
                                        showSharedDataSheet = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Text("🔍")
                                            Text("View Shared Data Preview")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(SottoTheme.primary)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.12))
                        
                        // Section 5: About
                        VStack(spacing: 8) {
                            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.6.0"
                            Text("Sotto v\(version)")
                                .font(.system(size: 13))
                                .foregroundColor(SottoTheme.textSecondary.opacity(0.6))
                            
                            Link(destination: URL(string: "https://github.com/triton1502oc/Sotto/issues")!) {
                                Text("💬  Feedback & Suggestions")
                                    .font(.system(size: 14))
                                    .foregroundColor(SottoTheme.primary.opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applyChanges()
                        onDismiss()
                    }
                    .bold()
                    .foregroundColor(SottoTheme.confirm)
                    .demoTarget("voice_doneButton")
                }
            }
            .sheet(isPresented: $showSharedDataSheet) {
                NavigationView {
                    ScrollView {
                        Text(UsabilityTracker.shared.generatePreviewPayload(voiceSettings: settings))
                            .font(.system(.caption, design: .monospaced))
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .navigationTitle("Shared Data Preview")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showSharedDataSheet = false }
                        }
                    }
                }
            }
        }
        .onAppear {
            let locales = SpeechService.shared.getAvailableLocales()
            availableLanguages = LocaleHelper.getAvailableLanguages(installedLocales: locales)
        }
    }
    
    private func applyChanges() {
        let updated = VoiceSettings(
            speechRate: speed,
            speechPitch: pitch,
            voiceIdentifier: settings.voiceIdentifier,
            appLanguage: selectedLanguage,
            playAttentionChime: attentionChime,
            showLanguageSwitcher: showLanguageSwitcher,
            secondaryLanguage: secondaryLanguage,
            shareUsabilityMetrics: shareUsabilityMetrics,
            userRole: userRole
        )
        settings = updated
    }
}
