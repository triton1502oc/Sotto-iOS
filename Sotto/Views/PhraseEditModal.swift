import SwiftUI
#if canImport(Translation)
import Translation
#endif

public struct PhraseEditModal: View {
    public let existingPhrase: Phrase?
    public let voiceSettings: VoiceSettings
    public let onSave: (Phrase) -> Void
    public let onDelete: ((Phrase) -> Void)?
    public let onCancel: () -> Void
    
    @State private var text: String
    @State private var spokenText: String
    @State private var spokenLanguage: String
    @State private var isSpokenTextExpanded: Bool
    @State private var isTranslating: Bool = false
    @State private var translationError: String? = nil
    @State private var translationTrigger: Bool = false
    @State private var selectedCategory: PhraseCategory
    @State private var baseTextBeforeRecording: String = ""
    @State private var baseSpokenTextBeforeRecording: String = ""
    
    @StateObject private var speechRecognizer = SpeechRecognizerService()
    @StateObject private var spokenSpeechRecognizer = SpeechRecognizerService()
    
    public init(
        existingPhrase: Phrase? = nil,
        initialText: String = "",
        voiceSettings: VoiceSettings = VoiceSettings(),
        onSave: @escaping (Phrase) -> Void,
        onDelete: ((Phrase) -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.existingPhrase = existingPhrase
        self.voiceSettings = voiceSettings
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        
        _text = State(initialValue: existingPhrase?.text ?? initialText)
        let initialSpoken = existingPhrase?.spokenText ?? ""
        _spokenText = State(initialValue: initialSpoken)
        _spokenLanguage = State(initialValue: existingPhrase?.spokenLanguage ?? voiceSettings.secondaryLanguage)
        _isSpokenTextExpanded = State(initialValue: !initialSpoken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        _selectedCategory = State(initialValue: existingPhrase?.isEmergency == true ? .emergency : (existingPhrase?.category ?? .general))
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Text input with microphone dictation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phrase text")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SottoTheme.textSecondary)
                            
                            HStack(alignment: .top, spacing: 8) {
                                TextEditor(text: $text)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                                    .background(SottoTheme.background)
                                    .foregroundColor(SottoTheme.textPrimary)
                                    .font(.system(size: 16))
                                    .cornerRadius(8)
                                    .padding(4)
                                
                                VStack(spacing: 6) {
                                    if speechRecognizer.isRecording {
                                        Button(action: toggleDictation) {
                                            Image(systemName: "mic.fill")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(SottoTheme.danger)
                                                .frame(width: 44, height: 44)
                                                .background(SottoTheme.danger.opacity(0.18))
                                                .clipShape(Circle())
                                        }
                                        .accessibilityLabel("Stop recording phrase text")
                                        .accessibilityHint("Turns off microphone listening mode")
                                    } else {
                                        Button(action: toggleDictation) {
                                            Image(systemName: "mic")
                                                .font(.system(size: 20))
                                                .foregroundColor(SottoTheme.textPrimary)
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                        }
                                        .accessibilityLabel("Start recording phrase text")
                                        .accessibilityHint("Dictates spoken words into phrase text")
                                    }
                                    
                                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Button(action: {
                                            speechRecognizer.stopRecording()
                                            text = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(SottoTheme.textSecondary)
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                        }
                                        .accessibilityLabel("Clear phrase text")
                                    }
                                }
                                .padding(.trailing, 2)
                                .padding(.top, 2)
                            }
                            .background(SottoTheme.background)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(speechRecognizer.isRecording ? SottoTheme.danger : Color.white.opacity(0.12), lineWidth: 1)
                            )
                            
                            if let speechErr = speechRecognizer.errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(SottoTheme.warning)
                                    Text(speechErr)
                                        .font(.system(size: 12))
                                        .foregroundColor(SottoTheme.danger)
                                    Spacer()
                                    Button(action: { speechRecognizer.errorMessage = nil }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(SottoTheme.textSecondary)
                                    }
                                }
                            }
                        }
                        
                        // Alternate Spoken Text (Only when Dual-Language is enabled)
                        if voiceSettings.showLanguageSwitcher {
                            VStack(alignment: .leading, spacing: 8) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSpokenTextExpanded.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text("Alternate spoken text (optional)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(SottoTheme.textSecondary)
                                        Spacer()
                                        Image(systemName: isSpokenTextExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(SottoTheme.primary)
                                    }
                                }
                                
                                if isSpokenTextExpanded {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text("Spoken language: \(LocaleHelper.getLanguageDisplayName(voiceSettings.secondaryLanguage))")
                                                .font(.system(size: 12))
                                                .foregroundColor(SottoTheme.textSecondary.opacity(0.8))
                                            Spacer()
                                            
                                            Button(action: executeAutoTranslate) {
                                                HStack(spacing: 4) {
                                                    if isTranslating {
                                                        ProgressView()
                                                            .progressViewStyle(CircularProgressViewStyle(tint: SottoTheme.primary))
                                                            .scaleEffect(0.7)
                                                        Text("Translating…")
                                                            .font(.system(size: 12, weight: .medium))
                                                    } else {
                                                        Text("🌐 Auto-translate")
                                                            .font(.system(size: 12, weight: .medium))
                                                    }
                                                }
                                                .foregroundColor(SottoTheme.primary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(SottoTheme.surfaceVariant)
                                                .cornerRadius(6)
                                            }
                                            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTranslating)
                                        }
                                        
                                        if let error = translationError {
                                            Text(error)
                                                .font(.system(size: 12))
                                                .foregroundColor(SottoTheme.danger)
                                        }
                                        
                                        HStack(alignment: .top, spacing: 8) {
                                            TextEditor(text: $spokenText)
                                                .frame(minHeight: 70)
                                                .scrollContentBackground(.hidden)
                                                .background(SottoTheme.background)
                                                .foregroundColor(SottoTheme.textPrimary)
                                                .font(.system(size: 15))
                                                .cornerRadius(8)
                                                .padding(4)
                                            
                                            VStack(spacing: 6) {
                                                if spokenSpeechRecognizer.isRecording {
                                                    Button(action: toggleSpokenDictation) {
                                                        Image(systemName: "mic.fill")
                                                            .font(.system(size: 18, weight: .bold))
                                                            .foregroundColor(SottoTheme.danger)
                                                            .frame(width: 44, height: 44)
                                                            .background(SottoTheme.danger.opacity(0.18))
                                                            .clipShape(Circle())
                                                    }
                                                    .accessibilityLabel("Stop recording spoken text")
                                                    .accessibilityHint("Turns off microphone listening mode")
                                                } else {
                                                    Button(action: toggleSpokenDictation) {
                                                        Image(systemName: "mic")
                                                            .font(.system(size: 18))
                                                            .foregroundColor(SottoTheme.textPrimary)
                                                            .frame(width: 44, height: 44)
                                                            .contentShape(Rectangle())
                                                    }
                                                    .accessibilityLabel("Start recording spoken text")
                                                    .accessibilityHint("Dictates spoken words into alternate text")
                                                }
                                                
                                                if !spokenText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                    Button(action: {
                                                        spokenSpeechRecognizer.stopRecording()
                                                        spokenText = ""
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.system(size: 18))
                                                            .foregroundColor(SottoTheme.textSecondary)
                                                            .frame(width: 44, height: 44)
                                                            .contentShape(Rectangle())
                                                    }
                                                    .accessibilityLabel("Clear spoken text")
                                                }
                                            }
                                            .padding(.trailing, 2)
                                            .padding(.top, 2)
                                        }
                                        .background(SottoTheme.background)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(spokenSpeechRecognizer.isRecording ? SottoTheme.danger : Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        
                        // Category selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Category")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SottoTheme.textSecondary)
                            
                            HStack(spacing: 8) {
                                ForEach(PhraseCategory.selectableCategories, id: \.self) { category in
                                    let isSelected = selectedCategory == category
                                    let isEmergency = category == .emergency
                                    
                                    Button(action: {
                                        speechRecognizer.stopRecording()
                                        spokenSpeechRecognizer.stopRecording()
                                        selectedCategory = category
                                    }) {
                                        HStack(spacing: 4) {
                                            if isEmergency {
                                                Text("🛡️")
                                                    .font(.system(size: 12))
                                            }
                                            Text(category.displayName)
                                                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                                        }
                                        .foregroundColor(
                                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedText :
                                            (isSelected ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                                        )
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedBg :
                                            (isSelected ? SottoTheme.surfaceVariant : SottoTheme.background)
                                        )
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isEmergency && isSelected ? SottoTheme.emergencyBorder : Color.clear, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                }
                
                #if canImport(Translation)
                if #available(iOS 18.0, *) {
                    let sourceLocale = LocaleHelper.resolvePhraseLocale(
                        phraseLang: LocaleHelper.langAuto,
                        phraseText: text,
                        appLanguage: voiceSettings.appLanguage
                    )
                    let targetLocale = LocaleHelper.getLocaleForLanguage(voiceSettings.secondaryLanguage)
                    OnDeviceTranslationHost(
                        sourceText: text,
                        sourceLocale: Locale.Language(identifier: sourceLocale.identifier),
                        targetLocale: Locale.Language(identifier: targetLocale.identifier),
                        trigger: $translationTrigger,
                        onResult: { translated in
                            spokenText = translated
                            spokenLanguage = voiceSettings.secondaryLanguage
                            isTranslating = false
                            translationError = nil
                        },
                        onError: { err in
                            isTranslating = false
                            translationError = err
                        }
                    )
                }
                #endif
            }
            .navigationTitle(existingPhrase != nil ? "Edit Phrase" : "Add Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        speechRecognizer.stopRecording()
                        spokenSpeechRecognizer.stopRecording()
                        onCancel()
                    }
                    .foregroundColor(SottoTheme.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    HStack(spacing: 16) {
                        if let existing = existingPhrase, let onDelete = onDelete {
                            Button(action: {
                                speechRecognizer.stopRecording()
                                spokenSpeechRecognizer.stopRecording()
                                onDelete(existing)
                            }) {
                                Text("Delete")
                                    .foregroundColor(SottoTheme.danger)
                            }
                        }
                        
                        Button(action: savePhrase) {
                            Text("Save")
                                .bold()
                                .foregroundColor(SottoTheme.confirm)
                        }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onDisappear {
            speechRecognizer.stopRecording()
            spokenSpeechRecognizer.stopRecording()
        }
    }
    
    private func savePhrase() {
        speechRecognizer.stopRecording()
        spokenSpeechRecognizer.stopRecording()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let isEmergency = selectedCategory == .emergency
        let newSpokenText: String?
        let newSpokenLang: String?
        
        if voiceSettings.showLanguageSwitcher {
            let trimmedSpoken = spokenText.trimmingCharacters(in: .whitespacesAndNewlines)
            newSpokenText = trimmedSpoken.isEmpty ? nil : trimmedSpoken
            newSpokenLang = newSpokenText != nil ? voiceSettings.secondaryLanguage : nil
        } else {
            newSpokenText = existingPhrase?.spokenText
            newSpokenLang = existingPhrase?.spokenLanguage
        }
        
        let newPhrase = Phrase(
            id: existingPhrase?.id ?? UUID(),
            text: trimmed,
            spokenText: newSpokenText,
            spokenLanguage: newSpokenLang,
            language: existingPhrase?.language ?? LocaleHelper.langAuto,
            isEmergency: isEmergency,
            category: selectedCategory
        )
        onSave(newPhrase)
    }
    
    private func executeAutoTranslate() {
        speechRecognizer.stopRecording()
        spokenSpeechRecognizer.stopRecording()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        translationError = nil
        let targetLang = voiceSettings.secondaryLanguage
        let sourceLocale = LocaleHelper.resolvePhraseLocale(
            phraseLang: LocaleHelper.langAuto,
            phraseText: trimmed,
            appLanguage: voiceSettings.appLanguage
        )
        let sourceLang = sourceLocale.language.languageCode?.identifier ?? "en"
        
        // 1. Check built-in offline dictionary
        if let match = TranslationHelper.dictionaryTranslation(for: trimmed, sourceLang: sourceLang, targetLang: targetLang) {
            spokenText = match
            spokenLanguage = targetLang
            return
        }
        
        // 2. Trigger on-device Translation framework if available
        #if canImport(Translation)
        if #available(iOS 18.0, *) {
            isTranslating = true
            translationTrigger.toggle()
        } else {
            translationError = "Auto-translation requires iOS 18.0+."
        }
        #else
        translationError = "Translation is not supported on this device."
        #endif
    }
    
    private func toggleDictation() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            spokenSpeechRecognizer.stopRecording()
            speechRecognizer.requestPermissions { granted in
                if granted {
                    baseTextBeforeRecording = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    let effectiveLang = LocaleHelper.getEffectiveLanguage(appLanguage: voiceSettings.appLanguage)
                    let locale = LocaleHelper.getLocaleForLanguage(effectiveLang)
                    speechRecognizer.startRecording(locale: locale) { recognizedText in
                        let clean = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if baseTextBeforeRecording.isEmpty {
                            text = clean
                        } else {
                            text = "\(baseTextBeforeRecording) \(clean)"
                        }
                    }
                }
            }
        }
    }
    
    private func toggleSpokenDictation() {
        if spokenSpeechRecognizer.isRecording {
            spokenSpeechRecognizer.stopRecording()
        } else {
            speechRecognizer.stopRecording()
            spokenSpeechRecognizer.requestPermissions { granted in
                if granted {
                    baseSpokenTextBeforeRecording = spokenText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let targetLang = voiceSettings.secondaryLanguage
                    let locale = LocaleHelper.getLocaleForLanguage(targetLang)
                    spokenSpeechRecognizer.startRecording(locale: locale) { recognizedText in
                        let clean = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if baseSpokenTextBeforeRecording.isEmpty {
                            spokenText = clean
                        } else {
                            spokenText = "\(baseSpokenTextBeforeRecording) \(clean)"
                        }
                    }
                }
            }
        }
    }
}

#if canImport(Translation)
@available(iOS 18.0, *)
private struct OnDeviceTranslationHost: View {
    let sourceText: String
    let sourceLocale: Locale.Language
    let targetLocale: Locale.Language
    @Binding var trigger: Bool
    let onResult: (String) -> Void
    let onError: (String) -> Void
    
    @State private var configuration: TranslationSession.Configuration?
    
    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    if configuration != nil {
                        configuration?.invalidate()
                    } else {
                        configuration = TranslationSession.Configuration(
                            source: sourceLocale,
                            target: targetLocale
                        )
                    }
                }
            }
            .translationTask(configuration) { session in
                do {
                    let response = try await session.translate(sourceText)
                    await MainActor.run {
                        onResult(response.targetText)
                    }
                } catch {
                    await MainActor.run {
                        onError(error.localizedDescription)
                    }
                }
            }
    }
}
#endif
