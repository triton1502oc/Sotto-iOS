import Foundation
import Combine

public final class MainViewModel: ObservableObject {
    @Published public var phrases: [Phrase] = []
    @Published public var selectedCategory: PhraseCategory = .all
    @Published public var voiceSettings: VoiceSettings = VoiceSettings()
    @Published public var isEditMode: Bool = false
    @Published public var ttsReady: Bool = true
    @Published public var activeFullscreenPhrase: Phrase? = nil
    @Published public var phraseToEdit: Phrase? = nil
    @Published public var showAddPhraseDialog: Bool = false
    @Published public var showVoiceSettingsDialog: Bool = false
    @Published public var activeSpeechTarget: String = "primary"
    @Published public var showTwoWayDialog: Bool = false
    @Published public var initialAddText: String = ""
    @Published public var quickText: String = ""
    
    private let phraseRepository: PhraseRepositoryProtocol
    private let voiceSettingsRepository: VoiceSettingsRepositoryProtocol
    private let speechService: SpeechService
    
    public init(
        phraseRepository: PhraseRepositoryProtocol = UserDefaultsPhraseRepository(),
        voiceSettingsRepository: VoiceSettingsRepositoryProtocol = UserDefaultsVoiceSettingsRepository(),
        speechService: SpeechService = .shared
    ) {
        self.phraseRepository = phraseRepository
        self.voiceSettingsRepository = voiceSettingsRepository
        self.speechService = speechService
        
        self.phrases = phraseRepository.getPhrases()
        self.voiceSettings = voiceSettingsRepository.getVoiceSettings()
    }
    
    public var filteredPhrases: [Phrase] {
        switch selectedCategory {
        case .all:
            return phrases
        case .emergency:
            return phrases.filter { $0.isEmergency }
        default:
            return phrases.filter { !$0.isEmergency && $0.category == selectedCategory }
        }
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
    }
    
    // MARK: - Speech
    
    public func speak(phrase: Phrase) {
        if voiceSettings.showLanguageSwitcher && activeSpeechTarget == "secondary" {
            if let spoken = phrase.spokenText?.trimmingCharacters(in: .whitespacesAndNewlines),
               !spoken.isEmpty && spoken != LocaleHelper.langAuto {
                speechService.speak(
                    text: spoken,
                    language: phrase.spokenLanguage ?? voiceSettings.secondaryLanguage,
                    settings: voiceSettings
                )
            } else {
                let sourceLocale = LocaleHelper.resolvePhraseLocale(phraseLang: phrase.language, phraseText: phrase.text, appLanguage: voiceSettings.appLanguage)
                let sourceLang = sourceLocale.language.languageCode?.identifier ?? "en"
                let targetLang = voiceSettings.secondaryLanguage
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
            speechService.speak(
                text: phrase.text,
                language: phrase.language,
                settings: voiceSettings
            )
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
