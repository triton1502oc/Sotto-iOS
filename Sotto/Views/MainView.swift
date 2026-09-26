import SwiftUI

public struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    
    public init(viewModel: MainViewModel = MainViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                SottoTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Bar
                    topBar
                    
                    // Category Filter Chips
                    categoryFilterRow
                        .padding(.vertical, 8)
                    
                    // Phrases Grid / List
                    phrasesContent
                    
                    // Quick Speak Bar (docked at bottom)
                    QuickSpeakBarView(
                        text: $viewModel.quickText,
                        onSpeak: { text in
                            viewModel.speakQuickText(text)
                        },
                        onFullscreen: { text in
                            let phrase = Phrase(text: text, language: LocaleHelper.langAuto)
                            viewModel.activeFullscreenPhrase = phrase
                        },
                        onSaveAsCard: { text in
                            viewModel.initialAddText = text
                            viewModel.showAddPhraseDialog = true
                        }
                    )
                }
            
            // Floating Action Button (+) in Edit Mode
            if viewModel.isEditMode {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.showAddPhraseDialog = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(SottoTheme.textPrimary)
                                .frame(width: 56, height: 56)
                                .background(SottoTheme.surface)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 72) // Above the quick-speak bar
                    }
                }
            }
        }
        // Modals
        .fullScreenCover(isPresented: $viewModel.showTwoWayDialog) {
            TwoWayConversationModal(
                allPhrases: viewModel.phrases,
                onSpeakResponse: { text in
                    viewModel.speakText(text, language: LocaleHelper.langAuto)
                },
                onDismiss: {
                    viewModel.showTwoWayDialog = false
                }
            )
        }
        .fullScreenCover(item: $viewModel.activeFullscreenPhrase) { phrase in
            FullscreenPhraseModal(
                phrase: phrase,
                voiceSettings: viewModel.voiceSettings,
                onSpeak: { toSpeak in
                    viewModel.speakText(toSpeak.text, language: toSpeak.language)
                },
                onSpeakSecondary: { toSpeak in
                    if let spoken = toSpeak.spokenText {
                        viewModel.speakText(spoken, language: toSpeak.spokenLanguage ?? viewModel.voiceSettings.secondaryLanguage)
                    }
                },
                onDismiss: {
                    viewModel.activeFullscreenPhrase = nil
                }
            )
        }
        .sheet(isPresented: $viewModel.showAddPhraseDialog) {
            PhraseEditModal(
                initialText: viewModel.initialAddText,
                voiceSettings: viewModel.voiceSettings,
                onSave: { newPhrase in
                    viewModel.addPhrase(newPhrase)
                    viewModel.initialAddText = ""
                    viewModel.showAddPhraseDialog = false
                },
                onCancel: {
                    viewModel.initialAddText = ""
                    viewModel.showAddPhraseDialog = false
                }
            )
        }
        .sheet(item: $viewModel.phraseToEdit) { phrase in
            PhraseEditModal(
                existingPhrase: phrase,
                voiceSettings: viewModel.voiceSettings,
                onSave: { updated in
                    viewModel.editPhrase(old: phrase, new: updated)
                    viewModel.phraseToEdit = nil
                },
                onDelete: { toDelete in
                    viewModel.deletePhrase(toDelete)
                    viewModel.phraseToEdit = nil
                },
                onCancel: {
                    viewModel.phraseToEdit = nil
                }
            )
        }
        .sheet(isPresented: $viewModel.showVoiceSettingsDialog) {
            VoiceSettingsModal(
                settings: Binding(
                    get: { viewModel.voiceSettings },
                    set: { viewModel.updateVoiceSettings($0) }
                ),
                onTestVoice: { testSettings in
                    viewModel.testVoice(with: testSettings)
                },
                onDismiss: {
                    viewModel.showVoiceSettingsDialog = false
                }
            )
        }
        .onAppear {
            if DemoAutomationRunner.shared.isDemoRequested {
                DemoAutomationRunner.shared.startDemo(viewModel: viewModel, size: geometry.size)
            }
        }
    }
}
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Text("Sotto")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(SottoTheme.textPrimary)
            
            Spacer()
            
            if !viewModel.ttsReady {
                Text("Initializing")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(SottoTheme.warning)
                    .cornerRadius(6)
                    .padding(.trailing, 6)
            }
            
            if viewModel.voiceSettings.showLanguageSwitcher {
                let isPrimary = viewModel.activeSpeechTarget == "primary"
                let primaryCode = LocaleHelper.getLocaleForLanguage(
                    LocaleHelper.getEffectiveLanguage(appLanguage: viewModel.voiceSettings.appLanguage)
                ).language.languageCode?.identifier.uppercased() ?? "EN"
                let secondaryCode = viewModel.voiceSettings.secondaryLanguage.uppercased()
                
                HStack(spacing: 2) {
                    Button(action: { viewModel.activeSpeechTarget = "primary" }) {
                        Text(primaryCode)
                            .font(.system(size: 12, weight: isPrimary ? .bold : .regular))
                            .foregroundColor(isPrimary ? SottoTheme.onPrimary : SottoTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isPrimary ? SottoTheme.primary : Color.clear)
                            .cornerRadius(12)
                    }
                    .demoTarget("langSwitch_primary")
                    
                    Button(action: { viewModel.activeSpeechTarget = "secondary" }) {
                        Text(secondaryCode)
                            .font(.system(size: 12, weight: !isPrimary ? .bold : .regular))
                            .foregroundColor(!isPrimary ? SottoTheme.onPrimary : SottoTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(!isPrimary ? SottoTheme.primary : Color.clear)
                            .cornerRadius(12)
                    }
                    .demoTarget("langSwitch_secondary")
                }
                .padding(2)
                .background(SottoTheme.surfaceVariant)
                .cornerRadius(14)
                .padding(.trailing, 4)
            }
            
            // Caregiver Receptive Mode (👂)
            Button(action: {
                viewModel.showTwoWayDialog = true
            }) {
                Text("👂")
                    .font(.system(size: 20))
                    .frame(width: 36, height: 36)
            }
            .demoTarget("topBar_listenModeButton")
            
            // Settings Gear Icon (Always accessible)
            Button(action: {
                viewModel.showVoiceSettingsDialog = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SottoTheme.textSecondary)
                    .frame(width: 36, height: 36)
            }
            .demoTarget("topBar_voiceButton")
            
            // Edit List / Done Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isEditMode.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(viewModel.isEditMode ? "✓" : "✏️")
                        .font(.system(size: 13))
                        .foregroundColor(viewModel.isEditMode ? SottoTheme.confirm : SottoTheme.textPrimary)
                    Text(viewModel.isEditMode ? "Done" : "Edit List")
                        .font(.system(size: 14, weight: viewModel.isEditMode ? .bold : .medium))
                        .foregroundColor(viewModel.isEditMode ? SottoTheme.confirm : SottoTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(viewModel.isEditMode ? SottoTheme.confirm.opacity(0.15) : SottoTheme.surfaceVariant)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(viewModel.isEditMode ? SottoTheme.confirm : Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .demoTarget("topBar_editButton")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(SottoTheme.background)
    }
    
    // MARK: - Category Filter Row
    
    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PhraseCategory.filterCategories, id: \.self) { category in
                    let isSelected = viewModel.selectedCategory == category
                    let isEmergency = category == .emergency
                    
                    Button(action: {
                        viewModel.selectedCategory = category
                    }) {
                        HStack(spacing: 4) {
                            if isEmergency {
                                Text("🚨")
                                    .font(.system(size: 12))
                            }
                            Text(category.displayName)
                                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                        }
                        .foregroundColor(
                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedText :
                            (isSelected ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedBg :
                            (isSelected ? SottoTheme.surfaceVariant : SottoTheme.surface)
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isEmergency && isSelected ? SottoTheme.emergencyBorder : Color.clear, lineWidth: 1)
                        )
                    }
                    .demoTarget("chip_\(category.rawValue)")
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Phrases Grid Content
    
    private var phrasesContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Render items: emergency cards full-width, regular cards in 2-column rows
                let items = viewModel.filteredPhrases
                let chunkedRows = chunkPhrases(items)
                
                ForEach(0..<chunkedRows.count, id: \.self) { rowIndex in
                    let row = chunkedRows[rowIndex]
                    if row.isEmergency, let phrase = row.items.first {
                        PhraseCardView(
                            phrase: phrase,
                            isEditMode: viewModel.isEditMode,
                            showAlternateSpeech: viewModel.voiceSettings.showLanguageSwitcher,
                            onTap: {
                                if viewModel.isEditMode {
                                    viewModel.phraseToEdit = phrase
                                } else {
                                    viewModel.speak(phrase: phrase)
                                }
                            },
                            onLongPress: {
                                viewModel.activeFullscreenPhrase = phrase
                            }
                        )
                        .demoTarget("emergencyCard")
                    } else {
                        HStack(spacing: 16) {
                            ForEach(Array(row.items.enumerated()), id: \.element.id) { colIndex, phrase in
                                PhraseCardView(
                                    phrase: phrase,
                                    isEditMode: viewModel.isEditMode,
                                    showAlternateSpeech: viewModel.voiceSettings.showLanguageSwitcher,
                                    onTap: {
                                        if viewModel.isEditMode {
                                            viewModel.phraseToEdit = phrase
                                        } else {
                                            viewModel.speak(phrase: phrase)
                                        }
                                    },
                                    onLongPress: {
                                        viewModel.activeFullscreenPhrase = phrase
                                    }
                                )
                                .demoTarget(phrase.spokenText != nil ? "dualLanguageCard" : (colIndex == 0 && rowIndex <= 1 ? "firstRegularCard" : (colIndex == 1 && rowIndex <= 1 ? "secondRegularCard" : "regularCard_\(phrase.id)")))
                            }
                            // If row has only 1 item, pad the other half
                            if row.items.count == 1 {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
    
    // Helper to group phrases into full-width emergency rows and 2-item regular rows
    private struct PhraseRow {
        let isEmergency: Bool
        let items: [Phrase]
    }
    
    private func chunkPhrases(_ phrases: [Phrase]) -> [PhraseRow] {
        var rows: [PhraseRow] = []
        var regularBuffer: [Phrase] = []
        
        for phrase in phrases {
            if phrase.isEmergency {
                if !regularBuffer.isEmpty {
                    rows.append(PhraseRow(isEmergency: false, items: regularBuffer))
                    regularBuffer.removeAll()
                }
                rows.append(PhraseRow(isEmergency: true, items: [phrase]))
            } else {
                regularBuffer.append(phrase)
                if regularBuffer.count == 2 {
                    rows.append(PhraseRow(isEmergency: false, items: regularBuffer))
                    regularBuffer.removeAll()
                }
            }
        }
        
        if !regularBuffer.isEmpty {
            rows.append(PhraseRow(isEmergency: false, items: regularBuffer))
        }
        
        return rows
    }
}
