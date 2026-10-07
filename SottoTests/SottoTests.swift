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
    
    // MARK: - Category Management Tests (v1.5.8)
    
    func testCategoryProtectedRules() {
        XCTAssertTrue(Phrase.isUndeletableCategory("Emergency"))
        XCTAssertTrue(Phrase.isUndeletableCategory("General"))
        XCTAssertFalse(Phrase.isUndeletableCategory("Needs"))
        XCTAssertFalse(Phrase.isUndeletableCategory("Social"))
        XCTAssertFalse(Phrase.isUndeletableCategory("Care"))
        XCTAssertFalse(Phrase.isUndeletableCategory("Custom Category"))
        
        XCTAssertTrue(Phrase.isUnrenamableCategory("Emergency"))
        XCTAssertFalse(Phrase.isUnrenamableCategory("General"))
        XCTAssertFalse(Phrase.isUnrenamableCategory("Needs"))
        XCTAssertFalse(Phrase.isUnrenamableCategory("Custom Category"))
    }
    
    func testCategoryOperationsInMainViewModel() {
        let suite = "test_categories_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let phraseRepo = UserDefaultsPhraseRepository(userDefaults: defaults)
        let vm = MainViewModel(phraseRepository: phraseRepo)
        
        // Add valid category
        XCTAssertTrue(vm.addCategory("Hobbies"))
        XCTAssertTrue(vm.categories.contains("Hobbies"))
        
        // Disallow duplicate (case-insensitive)
        XCTAssertFalse(vm.addCategory("hobbies"))
        // Disallow ALL
        XCTAssertFalse(vm.addCategory("ALL"))
        
        // Add phrase under Hobbies
        let hobbyPhrase = Phrase(text: "I want to paint.", category: "Hobbies")
        vm.addPhrase(hobbyPhrase)
        
        // Rename category
        XCTAssertTrue(vm.renameCategory(oldName: "Hobbies", newName: "Art"))
        XCTAssertTrue(vm.categories.contains("Art"))
        XCTAssertFalse(vm.categories.contains("Hobbies"))
        let updatedPhrase = vm.phrases.first { $0.text == "I want to paint." }
        XCTAssertEqual(updatedPhrase?.category.rawValue, "Art")
        
        // Reorder categories
        let oldFirst = vm.categories[0]
        let oldSecond = vm.categories[1]
        vm.reorderCategories(fromIndex: 0, toIndex: 1)
        XCTAssertEqual(vm.categories[0], oldSecond)
        XCTAssertEqual(vm.categories[1], oldFirst)
        
        // Delete category -> phrases fallback to General
        XCTAssertTrue(vm.deleteCategory("Art"))
        XCTAssertFalse(vm.categories.contains("Art"))
        let fallbackPhrase = vm.phrases.first { $0.text == "I want to paint." }
        XCTAssertEqual(fallbackPhrase?.category.rawValue, PhraseCategory.general.rawValue)
        
        // Cannot delete undeletable category
        XCTAssertFalse(vm.deleteCategory("General"))
        XCTAssertFalse(vm.deleteCategory("Emergency"))
        
        defaults.removePersistentDomain(forName: suite)
    }
    
    // MARK: - Why Finder Session State Machine Tests (v1.6.0)
    
    func testWhyFinderSessionFullFlow() {
        let defaultTree = UserDefaultsWhyFinderRepository.defaultTree(forLanguage: "en")
        let session = WhyFinderSession(tree: defaultTree)
        
        // 1. Initial State: AskingArea (Body)
        guard case .askingArea(_, let area) = session.currentState else {
            XCTFail("Initial state should be AskingArea")
            return
        }
        XCTAssertEqual(area.id, "body")
        
        // Answer Yes to Area -> enters first question of Body area
        session.answerYes()
        guard case .askingQuestion(_, _, let q) = session.currentState else {
            XCTFail("Should transition to AskingQuestion")
            return
        }
        XCTAssertEqual(q.type, .bodyPart)
        
        // Answer Yes to question with bodyPart -> transitions to selectingBodyPart
        session.answerYes()
        guard case .selectingBodyPart = session.currentState else {
            XCTFail("Should transition to SelectingBodyPart")
            return
        }
        
        // Select body part -> transitions to intensity scale
        session.selectBodyPart(BodyRegions.head)
        guard case .selectingIntensity = session.currentState else {
            XCTFail("Should transition to SelectingIntensity")
            return
        }
        
        // Select intensity -> transitions to confirmingCause
        session.selectIntensity(4)
        guard case .confirmingCause(_, _, let cause, let part, let intensity) = session.currentState else {
            XCTFail("Should transition to ConfirmingCause")
            return
        }
        XCTAssertEqual(part, BodyRegions.head)
        XCTAssertEqual(intensity, 4)
        XCTAssertFalse(cause.isEmpty)
        
        // Confirm Yes -> Finished with outcome .found
        session.answerYes()
        guard case .finished(let outcome, _, let finalCause, let finalPart, let finalIntensity, _, _, _) = session.currentState else {
            XCTFail("Should transition to Finished")
            return
        }
        XCTAssertEqual(outcome, .found)
        XCTAssertEqual(finalPart, BodyRegions.head)
        XCTAssertEqual(finalIntensity, 4)
        XCTAssertEqual(finalCause, cause)
        
        // Verify session can produce log entry
        let log = session.toLogEntry(privateNote: "Testing log")
        XCTAssertNotNil(log)
        XCTAssertEqual(log?.outcome, .found)
        XCTAssertEqual(log?.bodyPart, BodyRegions.head)
        XCTAssertEqual(log?.intensity, 4)
        XCTAssertEqual(log?.privateNote, "Testing log")
        XCTAssertFalse(log?.steps.isEmpty ?? true)
    }
    
    func testWhyFinderSessionStepBackAndStop() {
        let defaultTree = UserDefaultsWhyFinderRepository.defaultTree(forLanguage: "en")
        let session = WhyFinderSession(tree: defaultTree)
        
        XCTAssertFalse(session.canStepBack())
        session.answerNo() // Skips to next area (Sensory)
        XCTAssertTrue(session.canStepBack())
        
        session.stepBack() // Back to Body
        if case .askingArea(_, let area) = session.currentState {
            XCTAssertEqual(area.id, "body")
        } else {
            XCTFail("Should be back at body")
        }
        
        // Stop session early
        session.stop()
        if case .finished(let outcome, _, _, _, _, _, _, _) = session.currentState {
            XCTAssertEqual(outcome, .stopped)
        } else {
            XCTFail("Should be in Finished with stopped outcome")
        }
    }
    
    // MARK: - Why Finder Repository Persistence Tests
    
    func testWhyFinderRepositoryPersistence() {
        let suite = "test_why_repo_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let repo = UserDefaultsWhyFinderRepository(userDefaults: defaults)
        
        let initialTree = repo.getTree()
        XCTAssertEqual(initialTree.areas.count, 6)
        
        let entry = WhyLogEntry(
            id: UUID().uuidString,
            startedAt: 1000,
            endedAt: 2000,
            outcome: .found,
            areaId: "pain",
            causeText: "Headache",
            bodyPart: BodyRegions.head,
            intensity: 3,
            privateNote: "Rest needed",
            steps: [WhyStep(questionText: "Does something hurt?", answer: "yes")]
        )
        repo.addLog(entry)
        let logs = repo.getLogs()
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.causeText, "Headache")
        
        repo.deleteLog(id: entry.id)
        XCTAssertTrue(repo.getLogs().isEmpty)
        
        defaults.removePersistentDomain(forName: suite)
    }
    
    // MARK: - Backup V2 JSON Serialization & Helper Tests
    
    func testBackupExportAndImportMergeReplace() throws {
        let phrases = [
            Phrase(text: "Emergency card", isEmergency: true, category: .emergency),
            Phrase(text: "I want water.", category: .needs)
        ]
        let categories = ["Emergency", "General", "Needs", "Custom1"]
        let defaultTree = UserDefaultsWhyFinderRepository.defaultTree(forLanguage: "en")
        let testLog = [
            WhyLogEntry(
                id: "log-1",
                startedAt: 100,
                endedAt: 200,
                outcome: .found,
                areaId: "physical",
                causeText: "Thirsty",
                steps: []
            )
        ]
        
        // 1. Export JSON v2
        let json = PhraseBackupHelper.exportToJson(
            phrases: phrases,
            categories: categories,
            whyTree: defaultTree,
            whyLog: testLog
        )
        XCTAssertTrue(json.contains("\"version\"") && json.contains("2"))
        
        // 2. Parse JSON
        let parsed = PhraseBackupHelper.parseJson(json)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.phrases.count, 2)
        XCTAssertEqual(parsed?.categories.count, 4)
        XCTAssertNotNil(parsed?.whyTree)
        XCTAssertEqual(parsed?.whyLog?.count, 1)
        
        // 3. Merge test
        let existingPhrases = [Phrase(text: "Emergency card", isEmergency: true, category: .emergency)]
        let existingCategories = ["Emergency", "General"]
        let mergeResult = PhraseBackupHelper.mergeData(
            currentPhrases: existingPhrases,
            currentCategories: existingCategories,
            backup: parsed!
        )
        XCTAssertEqual(mergeResult.0.count, 2) // "Emergency card" deduplicated, "I want water." added
        XCTAssertTrue(mergeResult.1.contains("Custom1"))
        
        // 4. Replace test (preserves existing emergency phrases)
        let replaceResult = PhraseBackupHelper.replaceData(
            currentPhrases: existingPhrases,
            backup: parsed!
        )
        XCTAssertTrue(replaceResult.0.contains { $0.isEmergency })
        XCTAssertEqual(replaceResult.1, parsed!.categories)
    }
    
    // MARK: - Usability Tracker Telemetry V2 Scrubber Tests
    
    func testTelemetryPrivacyScrubber() {
        // System categories should be kept as-is
        XCTAssertEqual(UsabilityTracker.categoryType("General"), "general")
        XCTAssertEqual(UsabilityTracker.categoryType("Emergency"), "emergency")
        XCTAssertEqual(UsabilityTracker.categoryType("Needs"), "needs")
        XCTAssertEqual(UsabilityTracker.categoryType("Care"), "care")
        XCTAssertEqual(UsabilityTracker.categoryType("Social"), "social")
        
        // Custom user category name MUST be scrubbed to "custom"
        XCTAssertEqual(UsabilityTracker.categoryType("My Private Medicine"), "custom")
        XCTAssertEqual(UsabilityTracker.categoryType("Doctor Smith Routine"), "custom")
    }
}

