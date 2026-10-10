import SwiftUI
import UniformTypeIdentifiers

private struct QRShareItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let data: String
}

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
    @State private var activeQRShareItem: QRShareItem? = nil
    @State private var showQRScanner: Bool = false
    
    public init(viewModel: MainViewModel = MainViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                SottoTheme.background(for: viewModel.voiceSettings.appTheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Bar
                    topBar
                    
                    // Category Filter Chips
                    categoryFilterRow
                        .padding(.vertical, 8)
                    
                    // Persistent Safety / SOS Quick-Action Banner when viewing sub-categories
                    if viewModel.voiceSettings.showSafetyCards && viewModel.selectedCategory != .all && viewModel.selectedCategory != .emergency,
                       let emergencyPhrase = viewModel.phrases.first(where: { $0.isEmergency }) {
                        persistentEmergencyBanner(phrase: emergencyPhrase)
                    }
                    
                    // Phrases Grid / List
                    phrasesContent(width: geometry.size.width)
                    
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
                appLanguage: viewModel.voiceSettings.appLanguage,
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
                    if newPhrase.isEmergency {
                        UsabilityTracker.shared.recordSafetyCardSaved(voiceSettings: viewModel.voiceSettings)
                    }
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
                    if updated.isEmergency {
                        UsabilityTracker.shared.recordSafetyCardSaved(voiceSettings: viewModel.voiceSettings)
                    }
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
                onOpenQRScanner: {
                    showQRScanner = true
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
                    let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("sotto_deck_\(Int(Date().timeIntervalSince1970)).sotto")
                    try? json.write(to: tempUrl, atomically: true, encoding: .utf8)
                    shareUrl = tempUrl
                    showShareSheet = true
                    viewModel.showExportBackupDialog = false
                },
                onShareQR: { exportPhrases, exportTree, exportLog in
                    let json = viewModel.exportCompactPhrasesForQR()
                    viewModel.showExportBackupDialog = false
                    activeQRShareItem = QRShareItem(
                        title: "Sotto Vocabulary Deck",
                        subtitle: "Scan with camera to import phrases",
                        data: json
                    )
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
        .sheet(isPresented: $showShareSheet, onDismiss: {
            if let url = shareUrl {
                try? FileManager.default.removeItem(at: url)
                shareUrl = nil
            }
        }) {
            if let url = shareUrl {
                ShareActivityView(activityItems: [url])
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType(filenameExtension: "sotto") ?? .json, .json]) { result in
            if case .success(let url) = result {
                handleIncomingDeckUrl(url)
            }
        }
        .sheet(item: $activeQRShareItem) { item in
            QRCodeModal(
                title: item.title,
                subtitle: item.subtitle,
                dataString: item.data,
                onDismiss: {
                    activeQRShareItem = nil
                }
            )
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerModal(
                onScan: { scanned in
                    showQRScanner = false
                    handleIncomingDeckString(scanned)
                },
                onDismiss: {
                    showQRScanner = false
                }
            )
        }
        .onOpenURL { url in
            handleIncomingDeckUrl(url)
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
            UsabilityTracker.shared.recordAppOpen(voiceSettings: viewModel.voiceSettings)
            let customCount = viewModel.phrases.filter { !PhraseCategory.defaultCategories.contains($0.category) }.count
            UsabilityTracker.shared.recordSettingsState(settings: viewModel.voiceSettings, customPhraseCount: customCount)
            
            if viewModel.shouldPromptPmfSurvey() {
                viewModel.showPmfSurveyDialog = true
            }
            if let pending = EmergencyLaunchManager.shared.pendingAction {
                handleEmergencyAction(pending)
            }
            if DemoAutomationRunner.shared.isDemoRequested {
                DemoAutomationRunner.shared.startDemo(viewModel: viewModel, size: geometry.size)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sottoEmergencyAction)) { notification in
            if let action = notification.object as? EmergencyLaunchManager.Action {
                handleEmergencyAction(action)
            }
        }
        .preferredColorScheme(viewModel.voiceSettings.appTheme == VoiceSettings.themeSoftParchment ? .light : .dark)
    }
}

    // MARK: - Emergency Shortcut Handler (Issue #18)

    private func handleEmergencyAction(_ action: EmergencyLaunchManager.Action) {
        EmergencyLaunchManager.shared.pendingAction = nil
        switch action {
        case .triage:
            viewModel.showTwoWayDialog = true
            UsabilityTracker.shared.recordEmergencyShortcutLaunched(target: "triage", voiceSettings: viewModel.voiceSettings)
        case .safetyCard:
            if let safetyCard = viewModel.phrases.first(where: { $0.isEmergency }) {
                viewModel.activeFullscreenPhrase = safetyCard
                UsabilityTracker.shared.recordEmergencyShortcutLaunched(target: "safety_card", voiceSettings: viewModel.voiceSettings)
            }
        }
    }
    
    // MARK: - Deck File & QR Handlers (Issue #13)
    
    private func handleIncomingDeckUrl(_ url: URL) {
        if url.isFileURL {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url),
                   let jsonString = String(data: data, encoding: .utf8),
                   let backup = PhraseBackupHelper.parseJson(jsonString) {
                    viewModel.backupDataToImport = backup
                    viewModel.showImportBackupDialog = true
                }
            } else if let data = try? Data(contentsOf: url),
                      let jsonString = String(data: data, encoding: .utf8),
                      let backup = PhraseBackupHelper.parseJson(jsonString) {
                viewModel.backupDataToImport = backup
                viewModel.showImportBackupDialog = true
            }
        } else if url.scheme == "sotto" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let dataParam = components.queryItems?.first(where: { $0.name == "data" })?.value {
                handleIncomingDeckString(dataParam)
            }
        }
    }
    
    private func handleIncomingDeckString(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = Data(base64Encoded: trimmed),
           let json = String(data: data, encoding: .utf8),
           let backup = PhraseBackupHelper.parseJson(json) {
            viewModel.backupDataToImport = backup
            viewModel.showImportBackupDialog = true
            return
        }
        if let backup = PhraseBackupHelper.parseJson(trimmed) {
            viewModel.backupDataToImport = backup
            viewModel.showImportBackupDialog = true
            return
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
                            .frame(minWidth: 36, minHeight: 44)
                            .background(isPrimary ? SottoTheme.primary : Color.clear)
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Speak in primary language, \(primaryCode)")
                    .accessibilityAddTraits(isPrimary ? [.isSelected] : [])
                    .demoTarget("langSwitch_primary")
                    
                    Button(action: { viewModel.activeSpeechTarget = "secondary" }) {
                        Text(secondaryCode)
                            .font(.system(size: 12, weight: !isPrimary ? .bold : .regular))
                            .foregroundColor(!isPrimary ? SottoTheme.onPrimary : SottoTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .frame(minWidth: 36, minHeight: 44)
                            .background(!isPrimary ? SottoTheme.primary : Color.clear)
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Speak in secondary language, \(secondaryCode)")
                    .accessibilityAddTraits(!isPrimary ? [.isSelected] : [])
                    .demoTarget("langSwitch_secondary")
                }
                .padding(2)
                .background(SottoTheme.surfaceVariant)
                .cornerRadius(14)
                .padding(.trailing, 4)
            }
            
            // Partner Mode (🤝)
            Button(action: {
                viewModel.showTwoWayDialog = true
            }) {
                Text("🤝")
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Open Partner mode for communication partner")
            .demoTarget("topBar_listenModeButton")
            
            // Settings Gear Icon (Always accessible)
            Button(action: {
                viewModel.showVoiceSettingsDialog = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SottoTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Settings")
            .demoTarget("topBar_voiceButton")
            
            // Edit / Done Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isEditMode.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(viewModel.isEditMode ? "✓" : "✏️")
                        .font(.system(size: 13))
                        .foregroundColor(viewModel.isEditMode ? SottoTheme.confirm : SottoTheme.textPrimary)
                    Text(LocaleHelper.getActionEdit(isEditMode: viewModel.isEditMode, appLanguage: viewModel.voiceSettings.appLanguage))
                        .font(.system(size: 14, weight: viewModel.isEditMode ? .bold : .medium))
                        .foregroundColor(viewModel.isEditMode ? SottoTheme.confirm : SottoTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(viewModel.isEditMode ? SottoTheme.confirm.opacity(0.15) : SottoTheme.surfaceVariant)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(viewModel.isEditMode ? SottoTheme.confirm : Color.white.opacity(0.1), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .accessibilityLabel(viewModel.isEditMode ? "Done editing" : "Edit list")
            .demoTarget("topBar_editButton")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(SottoTheme.background(for: viewModel.voiceSettings.appTheme))
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
                    Text(LocaleHelper.getCategoryDisplayName("ALL", appLanguage: viewModel.voiceSettings.appLanguage))
                        .font(.system(size: 14, weight: isAllSelected ? .bold : .regular))
                        .foregroundColor(isAllSelected ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(isAllSelected ? SottoTheme.surfaceVariant : SottoTheme.surface)
                        .cornerRadius(20)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(LocaleHelper.getCategoryDisplayName("ALL", appLanguage: viewModel.voiceSettings.appLanguage))
                .accessibilityAddTraits(isAllSelected ? [.isSelected] : [])
                .demoTarget("chip_all")
                
                // Dynamic Categories from Repository (Safety chip hidden on main bar to reduce visual clutter)
                let mainBarCategories = viewModel.categories.filter { PhraseCategory($0) != .emergency }
                ForEach(mainBarCategories, id: \.self) { catName in
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
                                Text("🛡️")
                                    .font(.system(size: 12))
                            }
                            Text(LocaleHelper.getCategoryDisplayName(catName, appLanguage: viewModel.voiceSettings.appLanguage))
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
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .accessibilityLabel("Delete category \(catName)")
                            }
                        }
                        .foregroundColor(
                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedText :
                            (isSelected ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                        )
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(
                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedBg :
                            (isSelected ? SottoTheme.surfaceVariant : SottoTheme.surface)
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isEmergency && isSelected ? SottoTheme.emergencyBorder : Color.clear, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel(LocaleHelper.getCategoryDisplayName(catName, appLanguage: viewModel.voiceSettings.appLanguage))
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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
                        .frame(minHeight: 44)
                        .background(SottoTheme.surface)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(SottoTheme.primary.opacity(0.4), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Manage categories")
                    
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
                        .frame(minHeight: 44)
                        .background(SottoTheme.surface)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(SottoTheme.primary.opacity(0.4), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Add new category")
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Persistent Emergency Banner (Issue #11)
    
    @ViewBuilder
    private func persistentEmergencyBanner(phrase: Phrase) -> some View {
        Button(action: {
            if viewModel.isEditMode {
                viewModel.phraseToEdit = phrase
            } else {
                viewModel.speak(phrase: phrase)
            }
        }) {
            HStack(spacing: 10) {
                Text("🛡️")
                    .font(.system(size: 16))
                
                Text(phrase.text)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SottoTheme.safetyText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(SottoTheme.safetyBadgeText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(SottoTheme.safetyBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(SottoTheme.safetyBorder.opacity(0.8), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SottoCardButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                if !viewModel.isEditMode {
                    #if canImport(UIKit)
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.impactOccurred()
                    #endif
                    viewModel.activeFullscreenPhrase = phrase
                }
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quick Emergency Phrase: \(phrase.text)")
        .accessibilityHint(viewModel.isEditMode ? "Double tap to edit emergency card." : "Double tap to speak aloud. Double tap and hold to show fullscreen.")
        .accessibilityAction(named: "Speak Aloud") {
            viewModel.speak(phrase: phrase)
        }
        .accessibilityAction(named: "Show Fullscreen") {
            viewModel.activeFullscreenPhrase = phrase
        }
        .demoTarget("persistentEmergencyBanner")
    }
    
    // MARK: - Phrases Grid Content
    
    private func phrasesContent(width: CGFloat) -> some View {
        let columnsCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2)
        let items = viewModel.filteredPhrases
        let chunkedRows = chunkPhrases(items, columnsCount: columnsCount)
        
        return ScrollView {
            LazyVStack(spacing: 16) {
                // Render items: emergency cards full-width, regular cards in N-column rows
                ForEach(0..<chunkedRows.count, id: \.self) { rowIndex in
                    let row = chunkedRows[rowIndex]
                    if row.isEmergency, let phrase = row.items.first {
                        PhraseCardView(
                            phrase: phrase,
                            isEditMode: viewModel.isEditMode,
                            showAlternateSpeech: viewModel.voiceSettings.showLanguageSwitcher,
                            appLanguage: viewModel.voiceSettings.appLanguage,
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
                                    appLanguage: viewModel.voiceSettings.appLanguage,
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
                            // If row has fewer items than columnsCount, pad the other cells
                            if row.items.count < columnsCount {
                                ForEach(0..<(columnsCount - row.items.count), id: \.self) { _ in
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
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
    
    // Helper to group phrases into full-width emergency rows and N-item regular rows
    private struct PhraseRow {
        let isEmergency: Bool
        let items: [Phrase]
    }
    
    private func chunkPhrases(_ phrases: [Phrase], columnsCount: Int = 2) -> [PhraseRow] {
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
                if regularBuffer.count == columnsCount {
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
