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
    @Namespace private var accessibilityNamespace
    
    public init(viewModel: MainViewModel = MainViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private var currentPalette: SottoPalette {
        SottoPalettes.palette(for: viewModel.voiceSettings.appTheme)
    }
    
    private var isIndonesian: Bool {
        LocaleHelper.getEffectiveLanguage(appLanguage: viewModel.voiceSettings.appLanguage) == LocaleHelper.langIndonesian
    }
    
    public var body: some View {
        GeometryReader { geometry in
            coreLayoutWithPrimarySheets(size: geometry.size)
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
                        onShareQR: { _, _, _ in
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
                            onMerge: { selectedData in
                                _ = viewModel.importBackup(backupData: selectedData, replace: false)
                                viewModel.backupDataToImport = nil
                                viewModel.showImportBackupDialog = false
                            },
                            onReplace: { selectedData in
                                _ = viewModel.importBackup(backupData: selectedData, replace: true)
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
                .alert(isIndonesian ? "Frasa Sudah Ada" : "Duplicate Phrase", isPresented: $viewModel.showDuplicatePhraseAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(isIndonesian ? "Kartu dengan teks ini sudah ada di dek Anda." : "A card with this exact text already exists in your deck.")
                }
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
                    handleMainViewAppear(size: geometry.size)
                }
                .onReceive(NotificationCenter.default.publisher(for: .sottoEmergencyAction)) { notification in
                    if let action = notification.object as? EmergencyLaunchManager.Action {
                        handleEmergencyAction(action)
                    }
                }
                .preferredColorScheme(viewModel.voiceSettings.appTheme == VoiceSettings.themeSoftParchment ? .light : .dark)
                .environment(\.sottoPalette, currentPalette)
        }
    }

    private func coreLayoutWithPrimarySheets(size: CGSize) -> some View {
        mainLayout(size: size)
            .fullScreenCover(isPresented: $viewModel.showTwoWayDialog) {
                TwoWayConversationModal(
                    allPhrases: viewModel.phrases,
                    categories: viewModel.categories,
                    whyFinderRepository: viewModel.whyFinderRepository,
                    voiceSettings: viewModel.voiceSettings,
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
                        handleFullscreenSpeakSecondary(toSpeak)
                    },
                    onOpenPartnerMode: {
                        UserDefaults.standard.set("freeform", forKey: "partner_mode_last_tab")
                        viewModel.activeFullscreenPhrase = nil
                        viewModel.showTwoWayDialog = true
                    },
                    onDismiss: {
                        viewModel.activeFullscreenPhrase = nil
                    }
                )
            }
            .sheet(item: $viewModel.phraseForSafetySetup) { safetyPhrase in
                EmergencySafetySetupModal(
                    phrase: safetyPhrase,
                    voiceSettings: viewModel.voiceSettings,
                    onSavePhrase: { updated in
                        _ = viewModel.editPhrase(old: safetyPhrase, new: updated)
                        UsabilityTracker.shared.recordSafetyCardSaved(voiceSettings: viewModel.voiceSettings)
                        viewModel.phraseForSafetySetup = nil
                        viewModel.speakPhraseDirectly(updated)
                    },
                    onSpeakAnyway: { rawPhrase in
                        viewModel.phraseForSafetySetup = nil
                        viewModel.speakPhraseDirectly(rawPhrase)
                    },
                    onDismiss: {
                        viewModel.phraseForSafetySetup = nil
                    }
                )
                .environment(\.sottoPalette, currentPalette)
            }
            .sheet(isPresented: $viewModel.showWelcomeOnboarding) {
                WelcomeOnboardingModal(
                    initialRole: viewModel.voiceSettings.userRole,
                    emergencyPhrase: viewModel.phrases.first(where: { $0.isEmergency }),
                    voiceSettings: viewModel.voiceSettings,
                    onSaveEmergencyPhrase: { updatedPhrase in
                        if let existingEmergency = viewModel.phrases.first(where: { $0.isEmergency }) {
                            _ = viewModel.editPhrase(old: existingEmergency, new: updatedPhrase)
                        } else {
                            _ = viewModel.addPhrase(updatedPhrase)
                        }
                    },
                    onFinish: { selectedRole in
                        viewModel.onRolePromptAnswered(selectedRole)
                        viewModel.showWelcomeOnboarding = false
                    }
                )
                .environment(\.sottoPalette, currentPalette)
            }
            .sheet(isPresented: $viewModel.showAddPhraseDialog) {
                PhraseEditModal(
                    initialText: viewModel.initialAddText,
                    voiceSettings: viewModel.voiceSettings,
                    onSave: { newPhrase in
                        handleAddPhraseSave(newPhrase)
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
                        handleEditPhraseSave(old: phrase, updated: updated)
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
                    whyFinderRepository: viewModel.whyFinderRepository,
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
                .environment(\.sottoPalette, currentPalette)
            }
            .sheet(isPresented: $viewModel.showWhyLogDialog) {
                WhyLogModal(
                    repository: viewModel.whyFinderRepository,
                    onDismiss: {
                        viewModel.showWhyLogDialog = false
                    }
                )
                .environment(\.sottoPalette, currentPalette)
            }
    }

    private func handleFullscreenSpeakSecondary(_ toSpeak: Phrase) {
        let targetLang = viewModel.voiceSettings.secondaryLanguage
        if let spoken = toSpeak.spokenText?.trimmingCharacters(in: .whitespacesAndNewlines), !spoken.isEmpty {
            let hasExplicitLang = (toSpeak.spokenLanguage?.isEmpty == false && toSpeak.spokenLanguage != LocaleHelper.langAuto)
            let spokenLang = hasExplicitLang ? toSpeak.spokenLanguage! : targetLang
            viewModel.speakText(spoken, language: spokenLang)
        }
    }

    private func handleAddPhraseSave(_ newPhrase: Phrase) {
        let added = viewModel.addPhrase(newPhrase)
        if !added {
            UsabilityTracker.shared.recordFriction("duplicate_phrase_blocked", voiceSettings: viewModel.voiceSettings)
            viewModel.showAddPhraseDialog = false
            viewModel.showDuplicatePhraseAlert = true
            return
        }
        if newPhrase.isEmergency {
            UsabilityTracker.shared.recordSafetyCardSaved(voiceSettings: viewModel.voiceSettings)
        }
        viewModel.initialAddText = ""
        viewModel.showAddPhraseDialog = false
    }

    private func handleEditPhraseSave(old phrase: Phrase, updated: Phrase) {
        let saved = viewModel.editPhrase(old: phrase, new: updated)
        if !saved {
            UsabilityTracker.shared.recordFriction("duplicate_phrase_blocked", voiceSettings: viewModel.voiceSettings)
            viewModel.phraseToEdit = nil
            viewModel.showDuplicatePhraseAlert = true
            return
        }
        if updated.isEmergency {
            UsabilityTracker.shared.recordSafetyCardSaved(voiceSettings: viewModel.voiceSettings)
        }
        viewModel.phraseToEdit = nil
    }

    private func handleMainViewAppear(size: CGSize) {
        UsabilityTracker.shared.recordAppOpen(voiceSettings: viewModel.voiceSettings)
        let customCount = viewModel.phrases.filter { !PhraseCategory.defaultCategories.contains($0.category) }.count
        UsabilityTracker.shared.recordSettingsState(settings: viewModel.voiceSettings, customPhraseCount: customCount)
        
        if let pending = EmergencyLaunchManager.shared.pendingAction {
            handleEmergencyAction(pending)
        } else if DemoAutomationRunner.shared.isScreenshotRequested {
            DemoAutomationRunner.shared.startScreenshotCapture(viewModel: viewModel)
        } else if DemoAutomationRunner.shared.isDemoRequested {
            DemoAutomationRunner.shared.startDemo(viewModel: viewModel, size: size)
        } else if viewModel.shouldPromptRole() {
            viewModel.showWelcomeOnboarding = true
        } else if viewModel.shouldPromptPmfSurvey() {
            viewModel.showPmfSurveyDialog = true
        }
    }

    // MARK: - Main Layout & QuickSpeak Actions

    private func mainLayout(size: CGSize) -> some View {
        ZStack {
            currentPalette.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                MainTopBarView(
                    viewModel: viewModel,
                    currentPalette: currentPalette
                )
                
                CategoryFilterBarView(
                    viewModel: viewModel,
                    currentPalette: currentPalette,
                    onAddCategoryTap: {
                        newCategoryNameInput = ""
                        showAddCategoryAlert = true
                    }
                )
                .padding(.vertical, 8)
                
                if viewModel.voiceSettings.showSafetyCards && viewModel.selectedCategory != .all && viewModel.selectedCategory != .emergency,
                   let emergencyPhrase = viewModel.phrases.first(where: { $0.isEmergency }) {
                    PersistentEmergencyBannerView(
                        viewModel: viewModel,
                        phrase: emergencyPhrase
                    )
                }
                
                phrasesContent(width: size.width)
                
                QuickSpeakBarView(
                    text: $viewModel.quickText,
                    onSpeak: { text in
                        viewModel.speakQuickText(text)
                    },
                    onFullscreen: { text in
                        handleQuickSpeakFullscreen(text)
                    },
                    onSaveAsCard: { text in
                        handleQuickSpeakSaveAsCard(text)
                    },
                    onClear: {
                        viewModel.onQuickTextCleared()
                    }
                )
            }
            
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
                        .padding(.bottom, 72)
                    }
                }
            }
        }
    }

    private func handleQuickSpeakFullscreen(_ text: String) {
        let contextStr = "dock_v2 len_\(text.count)"
        UsabilityTracker.shared.endIntent(
            "QuickSpeak",
            outcome: "shown_fullscreen",
            contextTag: contextStr,
            voiceSettings: viewModel.voiceSettings
        )
        var spokenTranslation: String? = nil
        var spokenLang: String? = nil
        if viewModel.voiceSettings.showLanguageSwitcher {
            let sourceLocale = LocaleHelper.resolvePhraseLocale(
                phraseLang: LocaleHelper.langAuto,
                phraseText: text,
                appLanguage: viewModel.voiceSettings.appLanguage
            )
            let sourceLang = sourceLocale.language.languageCode?.identifier ?? "en"
            let targetLang = viewModel.voiceSettings.secondaryLanguage
            if let match = TranslationHelper.dictionaryTranslation(for: text, sourceLang: sourceLang, targetLang: targetLang) {
                spokenTranslation = match
                spokenLang = targetLang
            }
        }
        viewModel.activeFullscreenPhrase = Phrase(
            text: text,
            spokenText: spokenTranslation,
            spokenLanguage: spokenLang,
            language: LocaleHelper.langAuto
        )
    }

    private func handleQuickSpeakSaveAsCard(_ text: String) {
        if viewModel.hasDuplicatePhrase(text) {
            UsabilityTracker.shared.recordFriction("duplicate_phrase_blocked", voiceSettings: viewModel.voiceSettings)
            viewModel.showDuplicatePhraseAlert = true
            return
        }
        let contextStr = "dock_v2 len_\(text.count)"
        UsabilityTracker.shared.endIntent(
            "QuickSpeak",
            outcome: "saved_as_card",
            contextTag: contextStr,
            voiceSettings: viewModel.voiceSettings
        )
        viewModel.initialAddText = text
        viewModel.showAddPhraseDialog = true
    }

    // MARK: - Emergency Shortcut Handler (Issue #18)

    private func handleEmergencyAction(_ action: EmergencyLaunchManager.Action) {
        EmergencyLaunchManager.shared.pendingAction = nil
        switch action {
        case .partner:
            UserDefaults.standard.set("freeform", forKey: "partner_mode_last_tab")
            viewModel.showTwoWayDialog = true
            UsabilityTracker.shared.recordEmergencyShortcutLaunched(target: "partner_mode", voiceSettings: viewModel.voiceSettings)
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
            let host = url.host?.lowercased() ?? ""
            if host == "partner" || host == "emergency" || host == "triage" {
                viewModel.showTwoWayDialog = true
            } else if host == "whylog" {
                viewModel.showWhyLogDialog = true
            } else if host == "settings" {
                viewModel.showVoiceSettingsDialog = true
            } else if host == "safety" || host == "emergency" {
                if let safetyCard = viewModel.phrases.first(where: { $0.isEmergency }) {
                    viewModel.activeFullscreenPhrase = safetyCard
                }
            } else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
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
    
    // MARK: - Phrases Grid Content
    
    private func calculateColumnCount(width: CGFloat) -> Int {
        if width >= 1200 {
            return 6
        } else if width >= 950 {
            return 5
        } else if width >= 650 {
            return 4
        } else if width >= 380 {
            return 3
        } else {
            return 2
        }
    }
    
    private func phrasesContent(width: CGFloat) -> some View {
        let columnsCount = calculateColumnCount(width: width)
        let items = viewModel.filteredPhrases
        let chunkedRows = chunkPhrases(items, columnsCount: columnsCount)
        
        return ScrollView {
            LazyVStack(spacing: 16) {
                // Render items: emergency cards full-width, regular cards in N-column rows
                ForEach(0..<chunkedRows.count, id: \.self) { rowIndex in
                    let row = chunkedRows[rowIndex]
                    if row.isEmergency, let phrase = row.items.first {
                        ReorderablePhraseCard(
                            viewModel: viewModel,
                            phrase: phrase,
                            isEmergency: true,
                            currentPalette: currentPalette,
                            demoTargetId: "emergencyCard"
                        )
                    } else {
                        HStack(spacing: 16) {
                            ForEach(Array(row.items.enumerated()), id: \.element.id) { colIndex, phrase in
                                let targetId = phrase.spokenText != nil ? "dualLanguageCard" : (colIndex == 0 && rowIndex <= 1 ? "firstRegularCard" : (colIndex == 1 && rowIndex <= 1 ? "secondRegularCard" : "regularCard_\(phrase.id)"))
                                ReorderablePhraseCard(
                                    viewModel: viewModel,
                                    phrase: phrase,
                                    isEmergency: false,
                                    currentPalette: currentPalette,
                                    demoTargetId: targetId
                                )
                            }
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
        .accessibilityRotor("Categories") {
            ForEach(viewModel.categories, id: \.self) { cat in
                AccessibilityRotorEntry(Text(cat), id: cat, in: accessibilityNamespace)
            }
        }
        .accessibilityRotor("Safety Cards") {
            ForEach(viewModel.phrases.filter { $0.isEmergency }, id: \.id) { phrase in
                AccessibilityRotorEntry(Text(phrase.text), id: phrase.id, in: accessibilityNamespace)
            }
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
