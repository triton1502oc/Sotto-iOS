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
    }
    
    func testVoiceSettingsCodable() throws {
        let settings = VoiceSettings(
            speechRate: 1.2,
            speechPitch: 0.9,
            voiceIdentifier: "com.apple.voice.compact.en-US.Samantha",
            appLanguage: "en",
            playAttentionChime: true
        )
        
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(VoiceSettings.self, from: data)
        
        XCTAssertEqual(settings, decoded)
    }
}
