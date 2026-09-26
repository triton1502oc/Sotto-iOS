import XCTest
@testable import Sotto

final class SottoTests: XCTestCase {
    
    // MARK: - Phrase Model & Serialization Tests
    
    func testPhraseInitialization() {
        let phrase = Phrase(text: "Hello world", language: "en", isEmergency: false, category: .general)
        XCTAssertEqual(phrase.text, "Hello world")
        XCTAssertEqual(phrase.language, "en")
        XCTAssertFalse(phrase.isEmergency)
        XCTAssertEqual(phrase.category, .general)
    }
    
    func testEmergencyPhraseCategoryEnforcement() {
        // If isEmergency is true, category should default to .emergency
        let emergencyPhrase = Phrase(text: "Emergency help", language: "auto", isEmergency: true)
        XCTAssertTrue(emergencyPhrase.isEmergency)
        XCTAssertEqual(emergencyPhrase.category, .emergency)
    }
    
    func testPhraseCodableRoundtrip() throws {
        let original = Phrase(
            id: UUID(),
            text: "I need a quiet space.",
            language: "en",
            isEmergency: false,
            category: .needs
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Phrase.self, from: data)
        
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.text, decoded.text)
        XCTAssertEqual(original.language, decoded.language)
        XCTAssertEqual(original.isEmergency, decoded.isEmergency)
        XCTAssertEqual(original.category, decoded.category)
    }
    
    // MARK: - Phrase Repository & Migration Tests
    
    func testDefaultPhrasesCountAndCategories() {
        let englishDefaults = UserDefaultsPhraseRepository.defaultPhrases(forLanguage: "en")
        XCTAssertFalse(englishDefaults.isEmpty)
        
        let hasEmergency = englishDefaults.contains { $0.isEmergency && $0.category == .emergency }
        let hasNeeds = englishDefaults.contains { $0.category == .needs }
        let hasSocial = englishDefaults.contains { $0.category == .social }
        let hasGeneral = englishDefaults.contains { $0.category == .general }
        
        XCTAssertTrue(hasEmergency, "Default phrases should include an Emergency phrase")
        XCTAssertTrue(hasNeeds, "Default phrases should include Needs phrases")
        XCTAssertTrue(hasSocial, "Default phrases should include Social phrases")
        XCTAssertTrue(hasGeneral, "Default phrases should include General phrases")
    }
    
    func testIndonesianDefaultPhrases() {
        let indoDefaults = UserDefaultsPhraseRepository.defaultPhrases(forLanguage: "id")
        XCTAssertFalse(indoDefaults.isEmpty)
        
        let emergencyCard = indoDefaults.first { $0.isEmergency }
        XCTAssertNotNil(emergencyCard)
        XCTAssertTrue(emergencyCard?.text.contains("bicara") == true)
    }
    
    func testEmergencyMigrationPrependsEmergencyCard() {
        let userDefaultsSuite = "test_sotto_migration_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: userDefaultsSuite)!
        
        // Seed with phrases that have no emergency card
        let nonEmergencyPhrases = [
            Phrase(text: "Hello.", category: .general),
            Phrase(text: "Thank you.", category: .social)
        ]
        let data = try! JSONEncoder().encode(nonEmergencyPhrases)
        testDefaults.set(data, forKey: "saved_phrases")
        testDefaults.set(false, forKey: "v2_migrated")
        
        let repo = UserDefaultsPhraseRepository(userDefaults: testDefaults)
        let loaded = repo.getPhrases()
        
        XCTAssertTrue(loaded.contains { $0.isEmergency })
        XCTAssertEqual(loaded.first?.isEmergency, true, "Migrated emergency card should be prepended")
        
        testDefaults.removePersistentDomain(forName: userDefaultsSuite)
    }
    
    // MARK: - LocaleHelper Language Detection Tests
    
    func testLocaleHelperDetectionEnglish() {
        let phrase = "I cannot speak right now. Please read my screen."
        let locale = LocaleHelper.detectLocale(phrase: phrase, appLanguage: "en")
        XCTAssertEqual(locale.identifier, "en_US")
    }
    
    func testLocaleHelperDetectionIndonesian() {
        let phrase = "Saya tidak bisa bicara sekarang. Tolong baca layar saya."
        let locale = LocaleHelper.detectLocale(phrase: phrase, appLanguage: "id")
        XCTAssertEqual(locale.identifier, "id_ID")
    }
    
    func testLocaleHelperDisplayName() {
        let systemName = LocaleHelper.getLanguageDisplayName("system")
        XCTAssertEqual(systemName, "System Default")
        
        let enName = LocaleHelper.getLanguageDisplayName("en")
        XCTAssertTrue(enName.contains("English"))
    }
    
    // MARK: - VoiceSettings Tests
    
    func testVoiceSettingsDefaults() {
        let settings = VoiceSettings()
        XCTAssertEqual(settings.speechRate, 1.0)
        XCTAssertEqual(settings.speechPitch, 1.0)
        XCTAssertNil(settings.voiceIdentifier)
        XCTAssertEqual(settings.appLanguage, "system")
        XCTAssertFalse(settings.playAttentionChime)
        XCTAssertFalse(settings.showLanguageSwitcher)
        XCTAssertEqual(settings.secondaryLanguage, "id")
    }
    
    func testVoiceSettingsCodable() throws {
        let settings = VoiceSettings(
            speechRate: 1.2,
            speechPitch: 0.9,
            voiceIdentifier: "com.apple.voice.compact.en-US.Samantha",
            appLanguage: "en",
            playAttentionChime: true,
            showLanguageSwitcher: true,
            secondaryLanguage: "id"
        )
        
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(VoiceSettings.self, from: data)
        
        XCTAssertEqual(settings, decoded)
    }
    
    // MARK: - Dual-Language & SpokenText Tests
    
    func testPhraseWithSpokenTextCodableRoundtrip() throws {
        let phrase = Phrase(
            id: UUID(),
            text: "I need a quiet space.",
            spokenText: "Saya butuh tempat tenang.",
            spokenLanguage: "id",
            language: "en",
            isEmergency: false,
            category: .needs
        )
        
        let data = try JSONEncoder().encode(phrase)
        let decoded = try JSONDecoder().decode(Phrase.self, from: data)
        
        XCTAssertEqual(phrase.id, decoded.id)
        XCTAssertEqual(phrase.text, decoded.text)
        XCTAssertEqual(phrase.spokenText, decoded.spokenText)
        XCTAssertEqual(phrase.spokenLanguage, decoded.spokenLanguage)
        XCTAssertEqual(phrase.language, decoded.language)
        XCTAssertEqual(phrase.isEmergency, decoded.isEmergency)
        XCTAssertEqual(phrase.category, decoded.category)
    }
    
    // MARK: - TranslationHelper Tests
    
    func testTranslationHelperDictionary() {
        let enText = "I need a quiet space."
        let idTranslation = TranslationHelper.dictionaryTranslation(for: enText, sourceLang: "en", targetLang: "id")
        XCTAssertEqual(idTranslation, "Saya butuh tempat tenang.")
        
        let idText = "Terima kasih."
        let enTranslation = TranslationHelper.dictionaryTranslation(for: idText, sourceLang: "id", targetLang: "en")
        XCTAssertEqual(enTranslation, "Thank you.")
        
        let normalizedId = TranslationHelper.normalizeLanguageCode("id-ID")
        XCTAssertEqual(normalizedId, "id")
        
        let normalizedEn = TranslationHelper.normalizeLanguageCode("en_US")
        XCTAssertEqual(normalizedEn, "en")
    }
    
    // MARK: - Care Category & Care Migration Tests
    
    func testCareCategoryAndPhraseModel() {
        XCTAssertEqual(PhraseCategory.care.rawValue, "Care")
        XCTAssertEqual(PhraseCategory.care.displayName, "Care")
        XCTAssertTrue(PhraseCategory.selectableCategories.contains(.care))
        XCTAssertTrue(PhraseCategory.filterCategories.contains(.care))
        
        let carePhrase = Phrase(text: "Are you in pain?", category: .care)
        XCTAssertEqual(carePhrase.category, .care)
        XCTAssertFalse(carePhrase.isEmergency)
    }
    
    func testDefaultPhrasesIncludeCareCategory() {
        let enDefaults = UserDefaultsPhraseRepository.defaultPhrases(forLanguage: "en")
        let careEn = enDefaults.filter { $0.category == .care }
        XCTAssertEqual(careEn.count, 5)
        XCTAssertTrue(careEn.contains { $0.text == "Are you in pain?" })
        
        let idDefaults = UserDefaultsPhraseRepository.defaultPhrases(forLanguage: "id")
        let careId = idDefaults.filter { $0.category == .care }
        XCTAssertEqual(careId.count, 5)
        XCTAssertTrue(careId.contains { $0.text == "Apakah merasa sakit?" })
    }
    
    func testCareMigrationAppendsCarePhrases() {
        let userDefaultsSuite = "test_sotto_care_migration_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: userDefaultsSuite)!
        
        // Seed without care phrases
        let existingPhrases = [
            Phrase(text: "Hello.", category: .general),
            Phrase(text: "I need a quiet space.", category: .needs)
        ]
        let data = try! JSONEncoder().encode(existingPhrases)
        testDefaults.set(data, forKey: "saved_phrases")
        testDefaults.set(true, forKey: "v2_migrated")
        testDefaults.set(false, forKey: "care_migrated")
        
        let repo = UserDefaultsPhraseRepository(userDefaults: testDefaults)
        let loaded = repo.getPhrases()
        
        XCTAssertTrue(loaded.contains { $0.category == .care })
        XCTAssertTrue(testDefaults.bool(forKey: "care_migrated"))
        
        testDefaults.removePersistentDomain(forName: userDefaultsSuite)
    }
    
    func testSanitizeLegacyAutoSpokenText() {
        let userDefaultsSuite = "test_sotto_sanitize_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: userDefaultsSuite)!
        
        let legacyPhrases = [
            Phrase(text: "Hello.", spokenText: "auto", category: .general),
            Phrase(text: "Thank you.", spokenText: "Terima kasih.", category: .social)
        ]
        let data = try! JSONEncoder().encode(legacyPhrases)
        testDefaults.set(data, forKey: "saved_phrases")
        testDefaults.set(true, forKey: "v2_migrated")
        testDefaults.set(true, forKey: "care_migrated")
        
        let repo = UserDefaultsPhraseRepository(userDefaults: testDefaults)
        let loaded = repo.getPhrases()
        
        XCTAssertNil(loaded[0].spokenText, "Legacy 'auto' should be sanitized to nil")
        XCTAssertEqual(loaded[1].spokenText, "Terima kasih.")
        
        testDefaults.removePersistentDomain(forName: userDefaultsSuite)
    }
    
    func testCareAndTwoWayDictionaryTranslations() {
        let careEn = "Are you in pain?"
        let careId = TranslationHelper.dictionaryTranslation(for: careEn, sourceLang: "en", targetLang: "id")
        XCTAssertEqual(careId, "Apakah merasa sakit?")
        
        let repeatEn = "repeat"
        let repeatId = TranslationHelper.dictionaryTranslation(for: repeatEn, sourceLang: "en", targetLang: "id")
        XCTAssertEqual(repeatId, "Ulangi")
        
        let waitId = "tolong beri saya waktu sebentar."
        let waitEn = TranslationHelper.dictionaryTranslation(for: waitId, sourceLang: "id", targetLang: "en")
        XCTAssertEqual(waitEn, "Please give me a moment.")
    }
}
