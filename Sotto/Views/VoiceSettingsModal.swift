import SwiftUI
import AVFoundation

public struct VoiceSettingsModal: View {
    @Binding public var settings: VoiceSettings
    public let onTestVoice: (VoiceSettings) -> Void
    public let onDismiss: () -> Void
    
    @State private var speed: Float
    @State private var pitch: Float
    @State private var attentionChime: Bool
    @State private var selectedLanguage: String
    @State private var availableLanguages: [(code: String, name: String)] = []
    
    public init(
        settings: Binding<VoiceSettings>,
        onTestVoice: @escaping (VoiceSettings) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._settings = settings
        self.onTestVoice = onTestVoice
        self.onDismiss = onDismiss
        
        _speed = State(initialValue: settings.wrappedValue.speechRate)
        _pitch = State(initialValue: settings.wrappedValue.speechPitch)
        _attentionChime = State(initialValue: settings.wrappedValue.playAttentionChime)
        _selectedLanguage = State(initialValue: settings.wrappedValue.appLanguage)
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
                        // App Language Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App Language")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(SottoTheme.textPrimary)
                            
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
                        
                        // Speech Rate (Speed) Slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Speed: \(speedLabel)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(SottoTheme.textPrimary)
                            
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
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(SottoTheme.textPrimary)
                            
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
                        
                        // Test Voice Button
                        Button(action: {
                            let current = VoiceSettings(
                                speechRate: speed,
                                speechPitch: pitch,
                                voiceIdentifier: settings.voiceIdentifier,
                                appLanguage: selectedLanguage,
                                playAttentionChime: attentionChime
                            )
                            onTestVoice(current)
                        }) {
                            Text("Test Voice")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(SottoTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(SottoTheme.background)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.12))
                            .padding(.top, 8)
                        
                        // About Section
                        VStack(spacing: 8) {
                            Text("Sotto v1.0.0")
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
            .navigationTitle("Voice & Language Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applyChanges()
                        onDismiss()
                    }
                    .bold()
                    .foregroundColor(SottoTheme.confirm)
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
            playAttentionChime: attentionChime
        )
        settings = updated
    }
}
