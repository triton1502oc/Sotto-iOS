import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    
    @State private var showAddCategoryAlert: Bool = false
    @State private var newCategoryNameInput: String = ""
    @State private var categoryToRename: String? = nil
    @State private var categoryRenameInput: String = ""
    @State private var categoryToDelete: String? = nil
    
    @State private var showFileImporter: Bool = false
    @State private var shareUrl: URL? = nil
    @State private var showShareSheet: Bool = false
    
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
                        },
                        onClear: {
                            viewModel.onQuickTextCleared()
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
                categories: viewModel.categories,
                whyFinderRepository: viewModel.whyFinderRepository,
                onSpeakResponse: { text in
                    viewModel.onTwoWayResponseSpoken()
                    viewModel.speakText(text, language: LocaleHelper.langAuto)
                },
                onDismiss: {
                    viewModel.onTwoWayDismissed()
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
                onOpenWhyLog: {
                    viewModel.showWhyLogDialog = true
                },
                onOpenWhyTreeEditor: {
                    viewModel.showWhyTreeEditorDialog = true
                },
                onExportPhrases: {
                    viewModel.showExportBackupDialog = true
                },
                onImportPhrases: {
                    showFileImporter = true
                },
                onDismiss: {
                    viewModel.showVoiceSettingsDialog = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showManageCategoriesDialog) {
            ManageCategoriesModal(
                viewModel: viewModel,
                onDismiss: {
                    viewModel.showManageCategoriesDialog = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showWhyTreeEditorDialog) {
            WhyTreeEditorModal(
                repository: viewModel.whyFinderRepository,
                onDismiss: {
                    viewModel.showWhyTreeEditorDialog = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showWhyLogDialog) {
            WhyLogModal(
                repository: viewModel.whyFinderRepository,
                onDismiss: {
                    viewModel.showWhyLogDialog = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showExportBackupDialog) {
            ExportBackupModal(
                phraseCount: viewModel.phrases.count,
                areaCount: viewModel.whyFinderRepository.getTree().areas.count,
                logCount: viewModel.whyFinderRepository.getLogs().count,
                onExport: { exportPhrases, exportTree, exportLog in
                    let json = viewModel.exportBackup(exportPhrases: exportPhrases, exportTree: exportTree, exportLog: exportLog)
                    let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sotto_backup_\(Int(Date().timeIntervalSince1970)).json")
                    try? json.write(to: tempUrl, atomically: true, encoding: .utf8)
                    shareUrl = tempUrl
                    showShareSheet = true
                    viewModel.showExportBackupDialog = false
                },
                onDismiss: {
                    viewModel.showExportBackupDialog = false
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showImportBackupDialog && viewModel.backupDataToImport != nil },
            set: { if !$0 { viewModel.showImportBackupDialog = false; viewModel.backupDataToImport = nil } }
        )) {
            if let backupData = viewModel.backupDataToImport {
                ImportBackupModal(
                    backupData: backupData,
                    onMerge: {
                        _ = viewModel.importBackup(backupData: backupData, replace: false)
                        viewModel.backupDataToImport = nil
                        viewModel.showImportBackupDialog = false
                    },
                    onReplace: {
                        _ = viewModel.importBackup(backupData: backupData, replace: true)
                        viewModel.backupDataToImport = nil
                        viewModel.showImportBackupDialog = false
                    },
                    onDismiss: {
                        viewModel.backupDataToImport = nil
                        viewModel.showImportBackupDialog = false
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showPmfSurveyDialog) {
            PmfSurveyModal(
                initialRole: viewModel.voiceSettings.userRole,
                onSubmit: { pmfScore, primaryBenefit, role in
                    viewModel.onPmfSurveyAnswered(pmfScore: pmfScore, primaryBenefit: primaryBenefit, role: role) { s, b, r in
                        UsabilityTracker.shared.recordSurvey(
                            pmfScore: s,
                            primaryBenefit: b,
                            confirmedRole: r,
                            voiceSettings: viewModel.voiceSettings
                        )
                    }
                    viewModel.showPmfSurveyDialog = false
                },
                onDismiss: {
                    viewModel.onPmfSurveyDismissed()
                    viewModel.showPmfSurveyDialog = false
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareUrl {
                ShareActivityView(activityItems: [url])
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url),
                       let jsonString = String(data: data, encoding: .utf8),
                       let backup = PhraseBackupHelper.parseJson(jsonString) {
                        viewModel.backupDataToImport = backup
                        viewModel.showImportBackupDialog = true
                    }
                }
            }
        }
        // Alerts for In-Row Category Editing
        .alert("Add Category", isPresented: $showAddCategoryAlert) {
            TextField("Category name", text: $newCategoryNameInput)
            Button("Add") {
                viewModel.addCategory(newCategoryNameInput)
                newCategoryNameInput = ""
            }
            Button("Cancel", role: .cancel) {
                newCategoryNameInput = ""
            }
        }
        .alert("Rename Category", isPresented: Binding(
            get: { categoryToRename != nil },
            set: { if !$0 { categoryToRename = nil } }
        )) {
            TextField("Category name", text: $categoryRenameInput)
            Button("Save") {
                if let oldName = categoryToRename {
                    viewModel.renameCategory(oldName: oldName, newName: categoryRenameInput)
                }
                categoryToRename = nil
            }
            Button("Cancel", role: .cancel) {
                categoryToRename = nil
            }
        }
        .alert("Delete Category?", isPresented: Binding(
            get: { categoryToDelete != nil },
            set: { if !$0 { categoryToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let cat = categoryToDelete {
                    viewModel.deleteCategory(cat)
                }
                categoryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            if let cat = categoryToDelete {
                Text("Phrases in \"\(cat)\" will be moved to General.")
            }
        }
        .onAppear {
            if viewModel.shouldPromptPmfSurvey() {
                viewModel.showPmfSurveyDialog = true
            }
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
                // "ALL" Category Chip
                let isAllSelected = viewModel.selectedCategory == .all
                Button(action: {
                    viewModel.selectedCategory = .all
                }) {
                    Text("All")
                        .font(.system(size: 14, weight: isAllSelected ? .bold : .regular))
                        .foregroundColor(isAllSelected ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isAllSelected ? SottoTheme.surfaceVariant : SottoTheme.surface)
                        .cornerRadius(20)
                }
                .demoTarget("chip_all")
                
                // Dynamic Categories from Repository
                ForEach(viewModel.categories, id: \.self) { catName in
                    let catObj = PhraseCategory(catName)
                    let isSelected = viewModel.selectedCategory == catObj
                    let isEmergency = catObj == .emergency
                    let isProtectedFromDelete = Phrase.isUndeletableCategory(catName)
                    let isProtectedFromRename = Phrase.isUnrenamableCategory(catName)
                    
                    Button(action: {
                        if viewModel.isEditMode && !isProtectedFromRename {
                            categoryRenameInput = catName
                            categoryToRename = catName
                        } else {
                            viewModel.selectedCategory = catObj
                        }
                    }) {
                        HStack(spacing: 6) {
                            if isEmergency {
                                Text("🚨")
                                    .font(.system(size: 12))
                            }
                            Text(LocaleHelper.getCategoryDisplayName(catName))
                                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                            
                            if viewModel.isEditMode && !isProtectedFromRename {
                                Text("✏️")
                                    .font(.system(size: 11))
                            }
                            
                            if viewModel.isEditMode && !isProtectedFromDelete {
                                Button(action: {
                                    categoryToDelete = catName
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(SottoTheme.destructiveRed)
                                }
                            }
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
                    .demoTarget("chip_\(catName)")
                }
                
                // In Edit Mode: Manage Categories & Add Category Chips
                if viewModel.isEditMode {
                    Button(action: {
                        viewModel.showManageCategoriesDialog = true
                    }) {
                        HStack(spacing: 4) {
                            Text("↕")
                                .font(.system(size: 14, weight: .bold))
                            Text("Manage")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(SottoTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(SottoTheme.surface)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(SottoTheme.primary.opacity(0.4), lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        newCategoryNameInput = ""
                        showAddCategoryAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Text("+")
                                .font(.system(size: 14, weight: .bold))
                            Text("Add")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(SottoTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(SottoTheme.surface)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(SottoTheme.primary.opacity(0.4), lineWidth: 1)
                        )
                    }
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

// MARK: - Activity View for File Sharing

struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
