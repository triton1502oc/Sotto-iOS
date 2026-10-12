import Foundation
import Combine

public final class MainViewModel: ObservableObject {
    @Published public var phrases: [Phrase] = []
    @Published public var categories: [String] = []
    @Published public var selectedCategory: PhraseCategory = .all
    @Published public var voiceSettings: VoiceSettings = VoiceSettings()
    @Published public var isEditMode: Bool = false
    @Published public var ttsReady: Bool = true
    @Published public var activeFullscreenPhrase: Phrase? = nil
    @Published public var phraseToEdit: Phrase? = nil
    @Published public var showAddPhraseDialog: Bool = false
    @Published public var showVoiceSettingsDialog: Bool = false
    @Published public var showManageCategoriesDialog: Bool = false
    @Published public var showWhyTreeEditorDialog: Bool = false
    @Published public var showWhyLogDialog: Bool = false
    @Published public var showExportBackupDialog: Bool = false
    @Published public var showImportBackupDialog: Bool = false
    @Published public var showPmfSurveyDialog: Bool = false
    @Published public var backupDataToImport: BackupData? = nil
    @Published public var activeSpeechTarget: String = "primary"
    @Published public var showTwoWayDialog: Bool = false {
        didSet {
            if showTwoWayDialog {
                UsabilityTracker.shared.startIntent("TwoWay")
            }
        }
    }
    @Published public var initialAddText: String = ""
    @Published public var quickText: String = "" {
        didSet {
            if oldValue.isEmpty && !quickText.isEmpty {
                UsabilityTracker.shared.startIntent("QuickSpeak")
            }
        }
    }
    
    public let phraseRepository: PhraseRepositoryProtocol
    public let voiceSettingsRepository: VoiceSettingsRepositoryProtocol
    public let whyFinderRepository: WhyFinderRepositoryProtocol
    private let speechService: SpeechService
    
    public init(
        phraseRepository: PhraseRepositoryProtocol = UserDefaultsPhraseRepository(),
        voiceSettingsRepository: VoiceSettingsRepositoryProtocol = UserDefaultsVoiceSettingsRepository(),
        whyFinderRepository: WhyFinderRepositoryProtocol = UserDefaultsWhyFinderRepository.shared,
        speechService: SpeechService = .shared
    ) {
        self.phraseRepository = phraseRepository
        self.voiceSettingsRepository = voiceSettingsRepository
        self.whyFinderRepository = whyFinderRepository
        self.speechService = speechService
        
        self.phrases = phraseRepository.getPhrases()
        self.categories = phraseRepository.getCategories()
        self.voiceSettings = voiceSettingsRepository.getVoiceSettings()
    }
    
    public var filteredPhrases: [Phrase] {
        switch selectedCategory {
        case .all:
            return voiceSettings.showSafetyCards ? phrases : phrases.filter { !$0.isEmergency }
        case .emergency:
            return phrases.filter { $0.isEmergency }
        default:
            return phrases.filter { !$0.isEmergency && $0.category == selectedCategory }
        }
    }
    
    // MARK: - Category Operations
    
    @discardableResult
    public func addCategory(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.caseInsensitiveCompare("ALL") == .orderedSame {
            return false
        }
        if categories.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return false
        }
        categories.append(trimmed)
        phraseRepository.saveCategories(categories)
        return true
    }
    
    @discardableResult
    public func renameCategory(oldName: String, newName: String) -> Bool {
        let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedNew.isEmpty || trimmedNew.caseInsensitiveCompare("ALL") == .orderedSame {
            return false
        }
        if Phrase.isUnrenamableCategory(oldName) {
            return false
        }
        guard let index = categories.firstIndex(where: { $0.caseInsensitiveCompare(oldName) == .orderedSame }) else {
            return false
        }
        if categories.contains(where: { $0.caseInsensitiveCompare(trimmedNew) == .orderedSame && $0.caseInsensitiveCompare(oldName) != .orderedSame }) {
            return false
        }
        
        categories[index] = trimmedNew
        phraseRepository.saveCategories(categories)
        
        phrases = phrases.map { phrase in
            if phrase.category.rawValue.caseInsensitiveCompare(oldName) == .orderedSame {
                return Phrase(
                    id: phrase.id,
                    text: phrase.text,
                    spokenText: phrase.spokenText,
                    spokenLanguage: phrase.spokenLanguage,
                    language: phrase.language,
                    isEmergency: phrase.isEmergency,
                    category: PhraseCategory(trimmedNew)
                )
            }
            return phrase
        }
        phraseRepository.savePhrases(phrases)
        return true
    }
    
    @discardableResult
    public func deleteCategory(_ name: String) -> Bool {
        if Phrase.isUndeletableCategory(name) {
            return false
        }
        guard let index = categories.firstIndex(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else {
            return false
        }
        categories.remove(at: index)
        phraseRepository.saveCategories(categories)
        
        phrases = phrases.map { phrase in
            if phrase.category.rawValue.caseInsensitiveCompare(name) == .orderedSame {
                return Phrase(
                    id: phrase.id,
                    text: phrase.text,
                    spokenText: phrase.spokenText,
                    spokenLanguage: phrase.spokenLanguage,
                    language: phrase.language,
                    isEmergency: phrase.isEmergency,
                    category: .general
                )
            }
            return phrase
        }
        phraseRepository.savePhrases(phrases)
        
        if selectedCategory.rawValue.caseInsensitiveCompare(name) == .orderedSame {
            selectedCategory = .all
        }
        return true
    }
    
    public func reorderCategories(fromIndex: Int, toIndex: Int) {
        guard fromIndex >= 0 && fromIndex < categories.count,
              toIndex >= 0 && toIndex < categories.count,
              fromIndex != toIndex else {
            return
        }
        let item = categories.remove(at: fromIndex)
        categories.insert(item, at: toIndex)
        phraseRepository.saveCategories(categories)
    }
    
    public func moveCategory(fromName: String, toName: String) {
        guard let from = categories.firstIndex(where: { $0.caseInsensitiveCompare(fromName) == .orderedSame }),
              let to = categories.firstIndex(where: { $0.caseInsensitiveCompare(toName) == .orderedSame }),
              from != to else {
            return
        }
        let item = categories.remove(at: from)
        categories.insert(item, at: to)
        phraseRepository.saveCategories(categories)
    }
    
    // MARK: - Phrase Operations
    
    public func addPhrase(_ phrase: Phrase) {
        phrases.append(phrase)
        phraseRepository.savePhrases(phrases)
    }
    
    public func editPhrase(old: Phrase, new: Phrase) {
        if let index = phrases.firstIndex(where: { $0.id == old.id }) {
            phrases[index] = new
            phraseRepository.savePhrases(phrases)
        }
    }
    
    public func deletePhrase(_ phrase: Phrase) {
        phrases.removeAll(where: { $0.id == phrase.id })
        phraseRepository.savePhrases(phrases)
    }
    
    public func movePhrase(fromPhrase: Phrase, toPhrase: Phrase) {
        guard let fromIndex = phrases.firstIndex(where: { $0.id == fromPhrase.id }),
              let toIndex = phrases.firstIndex(where: { $0.id == toPhrase.id }),
              fromIndex != toIndex else {
            return
        }
        let item = phrases.remove(at: fromIndex)
        phrases.insert(item, at: toIndex)
        phraseRepository.savePhrases(phrases)
    }
    
    public func movePhrases(from source: IndexSet, to destination: Int) {
        var updated = phrases
        updated.move(fromOffsets: source, toOffset: destination)
        phrases = updated
        phraseRepository.savePhrases(phrases)
    }
    
    // MARK: - Voice Settings Operations
    
    public func updateVoiceSettings(_ settings: VoiceSettings) {
        self.voiceSettings = settings
        voiceSettingsRepository.saveVoiceSettings(settings)
        let customCount = phrases.filter { !PhraseCategory.defaultCategories.contains($0.category) }.count
        UsabilityTracker.shared.recordSettingsState(settings: settings, customPhraseCount: customCount)
    }
    
    // MARK: - Metrics, Role, & Survey
    
    public func shouldPromptMetrics() -> Bool {
        let isOptedIn = voiceSettings.shareUsabilityMetrics
        let hasPrompted = voiceSettingsRepository.getLastPromptedMetricsVersion() > 0
        return !isOptedIn && !hasPrompted
    }
    
    public func onMetricsPromptAnswered(optIn: Bool) {
        voiceSettingsRepository.setLastPromptedMetricsVersion(160)
        if optIn {
            voiceSettings.shareUsabilityMetrics = true
            updateVoiceSettings(voiceSettings)
        }
    }
    
    public func shouldPromptRole() -> Bool {
        return !voiceSettingsRepository.hasPromptedRole() && voiceSettings.userRole == VoiceSettings.roleUnset
    }
    
    public func onRolePromptAnswered(_ role: String) {
        voiceSettingsRepository.setPromptedRole(true)
        if !role.isEmpty {
            voiceSettings.userRole = role
            updateVoiceSettings(voiceSettings)
        }
    }
    
    public func shouldPromptPmfSurvey() -> Bool {
        return voiceSettingsRepository.shouldPromptPmfSurvey()
    }
    
    public func onPmfSurveyAnswered(pmfScore: String, primaryBenefit: String, role: String, onTrack: (String, String, String) -> Void) {
        voiceSettingsRepository.setPromptedPmfSurvey(true)
        if !role.isEmpty && role != VoiceSettings.roleUnset {
            voiceSettings.userRole = role
            updateVoiceSettings(voiceSettings)
        }
        onTrack(pmfScore, primaryBenefit, role)
    }
    
    public func onPmfSurveyDismissed() {
        voiceSettingsRepository.setPromptedPmfSurvey(true)
    }
    
    // MARK: - Backup Export & Import
    
    public func exportBackup(
        exportPhrases: Bool = true,
        exportTree: Bool = false,
        exportLog: Bool = false
    ) -> String {
        let phrasesToExport = exportPhrases ? phrases : nil
        let categoriesToExport = exportPhrases ? categories : nil
        let treeToExport = exportTree ? whyFinderRepository.getTree() : nil
        let logToExport = exportLog ? whyFinderRepository.getLogs() : nil
        
        let json = PhraseBackupHelper.exportToJson(
            phrases: phrasesToExport,
            categories: categoriesToExport,
            whyTree: treeToExport,
            whyLog: logToExport
        )
        
        UsabilityTracker.shared.recordBackupAction(
            isExport: true,
            includesPhrases: phrasesToExport != nil,
            includesTree: treeToExport != nil,
            includesLog: logToExport != nil,
            isReplace: false,
            voiceSettings: voiceSettings
        )
        
        return json
    }
    
    public func exportCompactPhrasesForQR() -> String {
        let json = PhraseBackupHelper.exportCompactPhrasesForQR(phrases: phrases, categories: categories)
        UsabilityTracker.shared.recordBackupAction(
            isExport: true,
            includesPhrases: true,
            includesTree: false,
            includesLog: false,
            isReplace: false,
            voiceSettings: voiceSettings
        )
        return json
    }
    
    public func importBackup(
        backupData: BackupData,
        replace: Bool
    ) -> ImportResult {
        var newPhrases = phrases
        var newCategories = categories
        var treeImported = false
        var logCount = 0
        
        if !backupData.phrases.isEmpty {
            let pair = replace
                ? PhraseBackupHelper.replaceData(currentPhrases: phrases, backup: backupData)
                : PhraseBackupHelper.mergeData(currentPhrases: phrases, currentCategories: categories, backup: backupData)
            
            newPhrases = pair.0
            newCategories = pair.1
            phrases = newPhrases
            categories = newCategories
            phraseRepository.savePhrases(newPhrases)
            phraseRepository.saveCategories(newCategories)
        }
        
        if let tree = backupData.whyTree {
            whyFinderRepository.saveTree(tree)
            treeImported = true
        }
        
        if let logs = backupData.whyLog, !logs.isEmpty {
            let currentLogs = whyFinderRepository.getLogs()
            let mergedLogs = PhraseBackupHelper.mergeLogs(currentLogs: currentLogs, backupLogs: logs)
            whyFinderRepository.clearLogs()
            for log in mergedLogs.reversed() {
                whyFinderRepository.addLog(log)
            }
            logCount = logs.count
        }
        
        UsabilityTracker.shared.recordBackupAction(
            isExport: false,
            includesPhrases: !backupData.phrases.isEmpty,
            includesTree: treeImported,
            includesLog: logCount > 0,
            isReplace: replace,
            voiceSettings: voiceSettings
        )
        
        return ImportResult(
            phraseCount: newPhrases.count,
            categoryCount: newCategories.count,
            treeImported: treeImported,
            logCount: logCount
        )
    }
    
    // MARK: - Speech
    
    public func speak(phrase: Phrase) {
        UsabilityTracker.shared.recordCardTap(
            category: phrase.category.rawValue,
            phraseId: phrase.id.uuidString,
            isEmergency: phrase.isEmergency,
            voiceSettings: voiceSettings
        )
        if voiceSettings.showLanguageSwitcher {
            if activeSpeechTarget == "secondary" {
                let targetLang = voiceSettings.secondaryLanguage
                if let spoken = phrase.spokenText?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !spoken.isEmpty && spoken != LocaleHelper.langAuto {
                    let spokenLang = (phrase.spokenLanguage?.isEmpty == false && phrase.spokenLanguage != LocaleHelper.langAuto)
                        ? phrase.spokenLanguage!
                        : targetLang
                    speechService.speak(
                        text: spoken,
                        language: spokenLang,
                        settings: voiceSettings
                    )
                } else {
                    let sourceLocale = LocaleHelper.resolvePhraseLocale(phraseLang: phrase.language, phraseText: phrase.text, appLanguage: voiceSettings.appLanguage)
                    let sourceLang = sourceLocale.language.languageCode?.identifier ?? "en"
                    if let dictMatch = TranslationHelper.dictionaryTranslation(for: phrase.text, sourceLang: sourceLang, targetLang: targetLang) {
                        speechService.speak(
                            text: dictMatch,
                            language: targetLang,
                            settings: voiceSettings
                        )
                    } else {
                        speechService.speak(
                            text: phrase.text,
                            language: targetLang,
                            settings: voiceSettings
                        )
                    }
                }
            } else {
                // Primary speech target: always speak primary card text with primary language
                speechService.speak(
                    text: phrase.text,
                    language: phrase.language,
                    settings: voiceSettings
                )
            }
        } else {
            // Single-language mode
            if let spoken = phrase.spokenText?.trimmingCharacters(in: .whitespacesAndNewlines),
               !spoken.isEmpty && spoken != LocaleHelper.langAuto {
                let spokenLang = (phrase.spokenLanguage?.isEmpty == false && phrase.spokenLanguage != LocaleHelper.langAuto)
                    ? phrase.spokenLanguage!
                    : phrase.language
                speechService.speak(
                    text: spoken,
                    language: spokenLang,
                    settings: voiceSettings
                )
            } else {
                speechService.speak(
                    text: phrase.text,
                    language: phrase.language,
                    settings: voiceSettings
                )
            }
        }
    }
    
    public func speakText(_ text: String, language: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        speechService.speak(
            text: trimmed,
            language: language ?? LocaleHelper.langAuto,
            settings: voiceSettings
        )
    }
    
    public func speakQuickText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        UsabilityTracker.shared.endIntent(
            "QuickSpeak",
            outcome: "completed",
            contextTag: "dock_v2 len_\(trimmed.count)",
            voiceSettings: voiceSettings
        )
        
        if voiceSettings.showLanguageSwitcher && activeSpeechTarget == "secondary" {
            let sourceLocale = LocaleHelper.resolvePhraseLocale(phraseLang: LocaleHelper.langAuto, phraseText: trimmed, appLanguage: voiceSettings.appLanguage)
            let sourceLang = sourceLocale.language.languageCode?.identifier ?? "en"
            let targetLang = voiceSettings.secondaryLanguage
            
            if let dictMatch = TranslationHelper.dictionaryTranslation(for: trimmed, sourceLang: sourceLang, targetLang: targetLang) {
                speechService.speak(
                    text: dictMatch,
                    language: targetLang,
                    settings: voiceSettings
                )
            } else {
                speechService.speak(
                    text: trimmed,
                    language: targetLang,
                    settings: voiceSettings
                )
            }
        } else {
            speechService.speak(
                text: trimmed,
                language: LocaleHelper.langAuto,
                settings: voiceSettings
            )
        }
    }
    
    public func onQuickTextCleared() {
        UsabilityTracker.shared.endIntent(
            "QuickSpeak",
            outcome: "aborted",
            frictionTag: "cleared_text",
            contextTag: "dock_v2 len_\(quickText.count)",
            voiceSettings: voiceSettings
        )
    }
    
    public func onTwoWayDismissed() {
        UsabilityTracker.shared.endIntent(
            "TwoWay",
            outcome: "aborted",
            frictionTag: "dismissed",
            voiceSettings: voiceSettings
        )
    }
    
    public func onTwoWayResponseSpoken() {
        UsabilityTracker.shared.endIntent(
            "TwoWay",
            outcome: "completed",
            voiceSettings: voiceSettings
        )
    }
    
    public func testVoice(with settings: VoiceSettings) {
        let isIndonesian = settings.appLanguage == "id" || settings.appLanguage == "in"
        let testPhrase = isIndonesian ? "Halo, ini adalah suara bicara saya." : "Hello, this is my speaking voice."
        speechService.speak(
            text: testPhrase,
            language: LocaleHelper.langAuto,
            settings: settings
        )
    }
}
