import SwiftUI
import AVFoundation

public struct VoiceSettingsModal: View {
    @Binding public var settings: VoiceSettings
    public let onTestVoice: (VoiceSettings) -> Void
    public var onOpenWhyLog: (() -> Void)?
    public var onOpenWhyTreeEditor: (() -> Void)?
    public var onOpenQRScanner: (() -> Void)?
    public var onExportPhrases: (() -> Void)?
    public var onImportPhrases: (() -> Void)?
    public let onDismiss: () -> Void
    
    @AppStorage("settings_last_tab") private var selectedTabIndex: Int = 0
    public var whyFinderRepository: WhyFinderRepositoryProtocol = UserDefaultsWhyFinderRepository.shared
    @State private var speed: Float
    @State private var pitch: Float
    @State private var attentionChime: Bool
    @State private var selectedLanguage: String
    @State private var selectedVoiceIdentifier: String?
    @State private var showLanguageSwitcher: Bool
    @State private var secondaryLanguage: String
    @State private var shareUsabilityMetrics: Bool
    @State private var userRole: String
    @State private var appTheme: String
    @State private var showSafetyCards: Bool
    @State private var cardLayout: String
    @State private var respectSilentSwitchForChime: Bool
    @State private var showSharedDataSheet: Bool = false
    @State private var showWhyTreeEditorSheet: Bool = false
    @State private var showWhyLogSheet: Bool = false
    @State private var availableLanguages: [(code: String, name: String)] = []
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []
    
    public init(
        settings: Binding<VoiceSettings>,
        whyFinderRepository: WhyFinderRepositoryProtocol = UserDefaultsWhyFinderRepository.shared,
        onTestVoice: @escaping (VoiceSettings) -> Void,
        onOpenWhyLog: (() -> Void)? = nil,
        onOpenWhyTreeEditor: (() -> Void)? = nil,
        onOpenQRScanner: (() -> Void)? = nil,
        onExportPhrases: (() -> Void)? = nil,
        onImportPhrases: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self._settings = settings
        self.whyFinderRepository = whyFinderRepository
        self.onTestVoice = onTestVoice
        self.onOpenWhyLog = onOpenWhyLog
        self.onOpenWhyTreeEditor = onOpenWhyTreeEditor
        self.onOpenQRScanner = onOpenQRScanner
        self.onExportPhrases = onExportPhrases
        self.onImportPhrases = onImportPhrases
        self.onDismiss = onDismiss
        
        _speed = State(initialValue: settings.wrappedValue.speechRate)
        _pitch = State(initialValue: settings.wrappedValue.speechPitch)
        _attentionChime = State(initialValue: settings.wrappedValue.playAttentionChime)
        _selectedLanguage = State(initialValue: settings.wrappedValue.appLanguage)
        _selectedVoiceIdentifier = State(initialValue: settings.wrappedValue.voiceIdentifier)
        _showLanguageSwitcher = State(initialValue: settings.wrappedValue.showLanguageSwitcher)
        _secondaryLanguage = State(initialValue: settings.wrappedValue.secondaryLanguage)
        _shareUsabilityMetrics = State(initialValue: settings.wrappedValue.shareUsabilityMetrics)
        _userRole = State(initialValue: settings.wrappedValue.userRole)
        _appTheme = State(initialValue: settings.wrappedValue.appTheme)
        _showSafetyCards = State(initialValue: settings.wrappedValue.showSafetyCards)
        _cardLayout = State(initialValue: settings.wrappedValue.cardLayout)
        _respectSilentSwitchForChime = State(initialValue: settings.wrappedValue.respectSilentSwitchForChime)
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
    
    private var isIndonesian: Bool {
        LocaleHelper.getEffectiveLanguage(appLanguage: selectedLanguage) == LocaleHelper.langIndonesian
    }
    
    private func voiceQualityBadge(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .premium: return "[Premium]"
        case .enhanced: return "[Enhanced]"
        default: return "[Compact]"
        }
    }
    
    private var currentVoiceLabel: String {
        if let id = selectedVoiceIdentifier, let v = availableVoices.first(where: { $0.identifier == id }) {
            return "\(v.name) \(voiceQualityBadge(v.quality))"
        }
        let effective = LocaleHelper.getEffectiveLanguage(appLanguage: selectedLanguage)
        if let autoVoice = SpeechService.bestVoice(forLanguage: effective) {
            return "\(isIndonesian ? "Otomatis" : "Auto"): \(autoVoice.name) \(voiceQualityBadge(autoVoice.quality))"
        }
        return isIndonesian ? "Otomatis" : "Auto (Default)"
    }
    
    private func updateAvailableVoices() {
        let effective = LocaleHelper.getEffectiveLanguage(appLanguage: selectedLanguage)
        let locale = LocaleHelper.getLocaleForLanguage(effective)
        availableVoices = SpeechService.shared.getAvailableVoices(forLocale: locale)
    }
    
    private var currentThemePalette: SottoPalette {
        SottoPalettes.palette(for: appTheme)
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                currentThemePalette.surface
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Tabs Header
                    tabPickerBar
                    
                    Divider()
                        .background(currentThemePalette.outlineVariant.opacity(0.35))
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            switch selectedTabIndex {
                            case 0:
                                voiceTabContent
                            case 1:
                                appearanceTabContent
                            default:
                                dataTabContent
                            }
                        }
                        .padding(20)
                    }
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
                .navigationViewStyle(.stack)
            }
            .sheet(isPresented: $showWhyTreeEditorSheet) {
                WhyTreeEditorModal(
                    repository: whyFinderRepository,
                    onDismiss: { showWhyTreeEditorSheet = false }
                )
                .environment(\.sottoPalette, currentThemePalette)
            }
            .sheet(isPresented: $showWhyLogSheet) {
                WhyLogModal(
                    repository: whyFinderRepository,
                    onDismiss: { showWhyLogSheet = false }
                )
                .environment(\.sottoPalette, currentThemePalette)
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            let locales = SpeechService.shared.getAvailableLocales()
            availableLanguages = LocaleHelper.getAvailableLanguages(installedLocales: locales)
            updateAvailableVoices()
        }
    }
    
    // MARK: - Tab Picker Bar
    
    private var tabPickerBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                let isSelected = selectedTabIndex == index
                let title = LocaleHelper.getSettingsTabTitle(tab: index, appLanguage: selectedLanguage)
                
                Button(action: {
                    if selectedTabIndex != index {
                        let outcome: String
                        switch index {
                        case 0: outcome = "voice"
                        case 1: outcome = "appearance"
                        default: outcome = "data"
                        }
                        UsabilityTracker.shared.startIntent("settings_tab_view")
                        UsabilityTracker.shared.endIntent("settings_tab_view", outcome: outcome, voiceSettings: settings)
                        selectedTabIndex = index
                    }
                }) {
                    VStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? currentThemePalette.accent : currentThemePalette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)
                        
                        Rectangle()
                            .fill(isSelected ? currentThemePalette.accent : Color.clear)
                            .frame(height: 2.5)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .background(currentThemePalette.surface)
    }
    
    // MARK: - Section Header & Tool Tile Helpers
    
    @ViewBuilder
    private func sectionHeader(icon: SottoIcon, title: String, subtitle: String? = nil) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(currentThemePalette.accent.opacity(0.12))
                    .frame(width: 32, height: 32)
                SottoIconView(icon, size: 16, tint: currentThemePalette.accent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(currentThemePalette.textPrimary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(currentThemePalette.textSecondary)
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func toolTile(icon: SottoIcon, title: String, subtitle: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(currentThemePalette.accent.opacity(0.12))
                        .frame(width: 32, height: 32)
                    SottoIconView(icon, size: 16, tint: currentThemePalette.accent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(currentThemePalette.textPrimary)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(currentThemePalette.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(currentThemePalette.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(currentThemePalette.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(currentThemePalette.outlineVariant.opacity(0.4), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
    }
    
    // MARK: - Tab 0: Voice & Speech Content
    
    @ViewBuilder
    private var voiceTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(
                icon: .recordVoiceOver,
                title: isIndonesian ? "Suara & Pembicara" : "Speech & Voice"
            )
            
            // App Language Selection
            VStack(alignment: .leading, spacing: 8) {
                Text(isIndonesian ? "Bahasa Aplikasi" : "App Language")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(currentThemePalette.textSecondary)
                
                Menu {
                    ForEach(availableLanguages, id: \.code) { item in
                        Button(action: {
                            selectedLanguage = item.code
                            selectedVoiceIdentifier = nil
                            updateAvailableVoices()
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
                            .foregroundColor(currentThemePalette.textPrimary)
                            .font(.system(size: 15))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13))
                            .foregroundColor(currentThemePalette.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(currentThemePalette.background)
                    .cornerRadius(10)
                }
            }
            
            // Voice Selection (Neural / Premium / Enhanced)
            VStack(alignment: .leading, spacing: 8) {
                Text(isIndonesian ? "Suara Pembicara (Voice)" : "Voice")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(currentThemePalette.textSecondary)
                
                Menu {
                    Button(action: {
                        selectedVoiceIdentifier = nil
                        applyChanges()
                    }) {
                        HStack {
                            Text(isIndonesian ? "Otomatis (Kualitas Tertinggi)" : "Auto (Highest Quality Available)")
                            if selectedVoiceIdentifier == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    ForEach(availableVoices, id: \.identifier) { voice in
                        Button(action: {
                            selectedVoiceIdentifier = voice.identifier
                            applyChanges()
                        }) {
                            HStack {
                                Text("\(voice.name) \(voiceQualityBadge(voice.quality))")
                                if selectedVoiceIdentifier == voice.identifier {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(currentVoiceLabel)
                            .foregroundColor(currentThemePalette.textPrimary)
                            .font(.system(size: 15))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13))
                            .foregroundColor(currentThemePalette.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(currentThemePalette.background)
                    .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isIndonesian
                         ? "💡 Ingin suara lebih alami (Siri / Enhanced)?"
                         : "💡 Want a natural human voice (Siri / Enhanced)?")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(currentThemePalette.accent)
                    Text(isIndonesian
                         ? "Buka Pengaturan iPad > Aksesibilitas > Konten Lisan > Suara > pilih bahasa Anda > unduh suara 'Enhanced' atau 'Premium' gratis dari Apple."
                         : "Go to iPad Settings > Accessibility > Spoken Content > Voices > tap your language > download Apple's free 'Enhanced' or 'Premium' voice.")
                        .font(.system(size: 11))
                        .foregroundColor(currentThemePalette.textSecondary)
                        .lineSpacing(2)
                }
                .padding(10)
                .background(currentThemePalette.accent.opacity(0.08))
                .cornerRadius(8)
                .padding(.top, 4)
            }
            
            // Speech Rate Slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Speed: \(speedLabel)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(currentThemePalette.textSecondary)
                
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
                .tint(currentThemePalette.accent)
            }
            
            // Speech Pitch Slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Pitch: \(pitchLabel)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(currentThemePalette.textSecondary)
                
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
                .tint(currentThemePalette.accent)
            }
            
            // Attention Chime Toggle
            Toggle(isOn: Binding(
                get: { attentionChime },
                set: { newValue in
                    attentionChime = newValue
                    applyChanges()
                    if newValue {
                        ChimePlayer.shared.play(respectSilentSwitch: respectSilentSwitchForChime)
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isIndonesian ? "Bunyikan nada perhatian sebelum bicara" : "Attention chime before speaking")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(currentThemePalette.textPrimary)
                    Text(isIndonesian ? "Membunyikan nada singkat untuk menarik perhatian pendengar sebelum bicara" : "Plays a brief chime to alert listeners before speaking")
                        .font(.system(size: 13))
                        .foregroundColor(currentThemePalette.textSecondary)
                }
            }
            .tint(currentThemePalette.accent)
            .demoTarget("voice_chimeToggle")
            
            if attentionChime {
                Toggle(isOn: Binding(
                    get: { respectSilentSwitchForChime },
                    set: { newValue in
                        respectSilentSwitchForChime = newValue
                        applyChanges()
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isIndonesian ? "Patuhi tombol hening" : "Respect silent switch")
                            .font(.system(size: 14))
                            .foregroundColor(currentThemePalette.textPrimary)
                        Text(isIndonesian ? "Nada dibungkam saat perangkat dalam mode hening atau Jangan Ganggu" : "Mutes the chime when device is set to silent or Do Not Disturb")
                            .font(.system(size: 12))
                            .foregroundColor(currentThemePalette.textSecondary.opacity(0.8))
                    }
                }
                .padding(.leading, 16)
                .tint(currentThemePalette.accent)
            }
            
            // Dual-Language Speech Toggle
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
                        .foregroundColor(currentThemePalette.textPrimary)
                    Text("Adds a toggle in the top bar to switch speech language")
                        .font(.system(size: 13))
                        .foregroundColor(currentThemePalette.textSecondary)
                }
            }
            .tint(currentThemePalette.accent)
            .demoTarget("voice_dualLanguageToggle")
            
            if showLanguageSwitcher {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Secondary speech language")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(currentThemePalette.textSecondary)
                    
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
                                .foregroundColor(currentThemePalette.textPrimary)
                                .font(.system(size: 15))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13))
                                .foregroundColor(currentThemePalette.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(currentThemePalette.background)
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 4)
            }
            
            // Test Voice Button
            Button(action: {
                let current = VoiceSettings(
                    speechRate: speed,
                    speechPitch: pitch,
                    voiceIdentifier: selectedVoiceIdentifier,
                    appLanguage: selectedLanguage,
                    playAttentionChime: attentionChime,
                    showLanguageSwitcher: showLanguageSwitcher,
                    secondaryLanguage: secondaryLanguage,
                    shareUsabilityMetrics: shareUsabilityMetrics,
                    userRole: userRole,
                    appTheme: appTheme,
                    showSafetyCards: showSafetyCards,
                    cardLayout: cardLayout,
                    respectSilentSwitchForChime: respectSilentSwitchForChime
                )
                onTestVoice(current)
            }) {
                HStack(spacing: 8) {
                    SottoIconView(.volumeUp, size: 16, tint: currentThemePalette.textPrimary)
                    Text("Test Voice")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(currentThemePalette.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(currentThemePalette.background)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .demoTarget("voice_testVoiceButton")
        }
    }
    
    // MARK: - Tab 1: Appearance & Safety Content
    
    @ViewBuilder
    private var appearanceTabContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Appearance (Sensory Themes)
            sectionHeader(
                icon: .palette,
                title: isIndonesian ? "Tema Tampilan" : "Appearance"
            )
            
            VStack(spacing: 8) {
                ForEach(SottoPalettes.all, id: \.key) { pal in
                    let isSelected = appTheme == pal.key
                    Button(action: {
                        appTheme = pal.key
                        applyChanges()
                        UsabilityTracker.shared.recordThemeSelected(theme: pal.key, voiceSettings: settings)
                    }) {
                        HStack(spacing: 12) {
                            // 3-layer swatch
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(pal.background)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(pal.outlineVariant, lineWidth: 1.5)
                                    )
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(pal.surface)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(pal.outlineVariant, lineWidth: 1)
                                    )
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(pal.accent)
                                    .frame(width: 8, height: 8)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pal.name)
                                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(pal.textPrimary)
                                Text(pal.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(pal.textSecondary)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(pal.accent)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(isSelected ? pal.accent.opacity(0.12) : pal.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? pal.accent : pal.outlineVariant, lineWidth: isSelected ? 2 : 1)
                        )
                    }
                }
            }
            
            Divider().background(currentThemePalette.outlineVariant.opacity(0.35))
            
            // Safety & Bystander Section
            sectionHeader(
                icon: .shield,
                title: isIndonesian ? "Keamanan & Pengamat" : "Safety & Bystander"
            )
            
            Toggle(isOn: Binding(
                get: { showSafetyCards },
                set: { newValue in
                    showSafetyCards = newValue
                    applyChanges()
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show Safety cards on Home")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(currentThemePalette.textPrimary)
                    Text("Display safety and contact cards at the top of the All phrases grid")
                        .font(.system(size: 13))
                        .foregroundColor(currentThemePalette.textSecondary)
                }
            }
            .tint(currentThemePalette.accent)
            
            Divider().background(currentThemePalette.outlineVariant.opacity(0.35))
            
            // Phrase Card Density / Layout (#36)
            sectionHeader(
                icon: .cards,
                title: LocaleHelper.getCardLayoutTitle(appLanguage: selectedLanguage),
                subtitle: LocaleHelper.getCardLayoutDesc(appLanguage: selectedLanguage)
            )
            
            HStack(spacing: 12) {
                let options = [
                    (isCompact: false, label: LocaleHelper.getCardLayoutOption(isCompact: false, appLanguage: selectedLanguage)),
                    (isCompact: true, label: LocaleHelper.getCardLayoutOption(isCompact: true, appLanguage: selectedLanguage))
                ]
                
                ForEach(options, id: \.isCompact) { opt in
                    let isSelected = (cardLayout == VoiceSettings.cardLayoutCompact) == opt.isCompact
                    Button(action: {
                        if (cardLayout == VoiceSettings.cardLayoutCompact) != opt.isCompact {
                            let nextVal = opt.isCompact ? VoiceSettings.cardLayoutCompact : VoiceSettings.cardLayoutSquare
                            UsabilityTracker.shared.startIntent("card_layout_changed")
                            UsabilityTracker.shared.endIntent(
                                "card_layout_changed",
                                outcome: opt.isCompact ? "compact" : "square",
                                voiceSettings: settings
                            )
                            cardLayout = nextVal
                            applyChanges()
                        }
                    }) {
                        VStack(spacing: 6) {
                            Text(opt.label)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? currentThemePalette.accent : currentThemePalette.textPrimary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 10)
                        .frame(minHeight: 46)
                        .background(isSelected ? currentThemePalette.accent.opacity(0.12) : currentThemePalette.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? currentThemePalette.accent : currentThemePalette.outlineVariant.opacity(0.4), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Tab 2: Data & Backup Content
    
    @ViewBuilder
    private var dataTabContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Why Finder Tools
            sectionHeader(
                icon: .explore,
                title: isIndonesian ? "Alat Pencari Penyebab (Why Finder)" : "Why Finder Tools"
            )
            
            VStack(spacing: 8) {
                toolTile(
                    icon: .listAlt,
                    title: "View Why Log",
                    subtitle: "Browse private root cause discovery records"
                ) {
                    UsabilityTracker.shared.startIntent("settings_tool_open")
                    UsabilityTracker.shared.endIntent("settings_tool_open", outcome: "why_log", voiceSettings: settings)
                    showWhyLogSheet = true
                }
                
                toolTile(
                    icon: .branch,
                    title: "Edit Question Tree",
                    subtitle: "Customize branching root-cause questions"
                ) {
                    UsabilityTracker.shared.startIntent("settings_tool_open")
                    UsabilityTracker.shared.endIntent("settings_tool_open", outcome: "tree_editor", voiceSettings: settings)
                    showWhyTreeEditorSheet = true
                }
            }
            
            Divider().background(currentThemePalette.outlineVariant.opacity(0.35))
            
            // Backup & Transfer
            sectionHeader(
                icon: .backup,
                title: isIndonesian ? "Cadangan & Transfer" : "Backup & Transfer",
                subtitle: isIndonesian ? "Ekspor atau impor frasa dan pengaturan Anda" : "Export or import your phrases and settings"
            )
            
            VStack(spacing: 8) {
                toolTile(
                    icon: .backup,
                    title: "Export Phrases",
                    subtitle: "Create a shareable backup of phrases & logs"
                ) {
                    UsabilityTracker.shared.startIntent("settings_tool_open")
                    UsabilityTracker.shared.endIntent("settings_tool_open", outcome: "export", voiceSettings: settings)
                    onDismiss()
                    onExportPhrases?()
                }
                
                toolTile(
                    icon: .restore,
                    title: "Import Phrases",
                    subtitle: "Restore vocabulary from a backup file"
                ) {
                    UsabilityTracker.shared.startIntent("settings_tool_open")
                    UsabilityTracker.shared.endIntent("settings_tool_open", outcome: "import", voiceSettings: settings)
                    onDismiss()
                    onImportPhrases?()
                }
                
                toolTile(
                    icon: .qrCodeScanner,
                    title: "Scan QR Code Deck",
                    subtitle: "Import compact phrase deck via camera"
                ) {
                    UsabilityTracker.shared.startIntent("settings_tool_open")
                    UsabilityTracker.shared.endIntent("settings_tool_open", outcome: "scan_qr", voiceSettings: settings)
                    onDismiss()
                    onOpenQRScanner?()
                }
            }
            
            Divider().background(currentThemePalette.outlineVariant.opacity(0.35))
            
            // Anonymous Usability Analytics
            sectionHeader(
                icon: .analytics,
                title: isIndonesian ? "Analitik Anonim" : "Anonymous Usability Analytics"
            )
            
            Toggle(isOn: $shareUsabilityMetrics) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isIndonesian ? "Bantu menyempurnakan Sotto" : "Help improve Sotto")
                        .font(.system(size: 15))
                        .foregroundColor(currentThemePalette.textPrimary)
                    Text(isIndonesian ? "Bagikan waktu interaksi anonim untuk perbaikan aplikasi. Tidak pernah mengumpulkan teks, suara, atau informasi kesehatan/tubuh." : "Shares anonymous interaction timings to identify usability difficulties. Never collects text, speech, or health/body information.")
                        .font(.system(size: 12))
                        .foregroundColor(currentThemePalette.textSecondary.opacity(0.7))
                }
            }
            .tint(currentThemePalette.accent)
            .onChange(of: shareUsabilityMetrics) { _ in
                applyChanges()
            }
            
            Button(action: {
                showSharedDataSheet = true
            }) {
                HStack(spacing: 6) {
                    SottoIconView(.search, size: 12, tint: currentThemePalette.accent)
                    Text(isIndonesian ? "Lihat contoh data yang dibagikan" : "View sample shared data")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(currentThemePalette.accent)
            }
            .padding(.top, 2)
            
            if shareUsabilityMetrics {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isIndonesian ? "Peran pengguna" : "User role")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(currentThemePalette.textSecondary)
                    
                    HStack(spacing: 8) {
                        let roles = [
                            (key: VoiceSettings.roleCaregiver, label: isIndonesian ? "Pendamping" : "Caregiver"),
                            (key: VoiceSettings.roleSelf, label: isIndonesian ? "Diri Sendiri" : "Self"),
                            (key: VoiceSettings.roleProfessional, label: isIndonesian ? "Profesional" : "Professional")
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
                                    .foregroundColor(isSelected ? .white : currentThemePalette.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(isSelected ? currentThemePalette.accent : currentThemePalette.surfaceVariant)
                                    .cornerRadius(18)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            Divider().background(currentThemePalette.outlineVariant.opacity(0.35))
            
            // About & Feedback
            VStack(spacing: 8) {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.7.2"
                Text("Sotto v\(version)")
                    .font(.system(size: 13))
                    .foregroundColor(currentThemePalette.textSecondary.opacity(0.6))
                
                Link(destination: URL(string: "https://github.com/triton1502oc/Sotto-iOS/issues")!) {
                    HStack(spacing: 6) {
                        SottoIconView(.chat, size: 14, tint: currentThemePalette.accent)
                        Text("Feedback & Suggestions")
                            .font(.system(size: 14))
                            .foregroundColor(currentThemePalette.accent.opacity(0.8))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
    }
    
    private func applyChanges() {
        let updated = VoiceSettings(
            speechRate: speed,
            speechPitch: pitch,
            voiceIdentifier: selectedVoiceIdentifier,
            appLanguage: selectedLanguage,
            playAttentionChime: attentionChime,
            showLanguageSwitcher: showLanguageSwitcher,
            secondaryLanguage: secondaryLanguage,
            shareUsabilityMetrics: shareUsabilityMetrics,
            userRole: userRole,
            appTheme: appTheme,
            showSafetyCards: showSafetyCards,
            cardLayout: cardLayout,
            respectSilentSwitchForChime: respectSilentSwitchForChime
        )
        settings = updated
    }
}
