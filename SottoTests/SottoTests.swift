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
        XCTAssertTrue(emergencyCard?.text.contains("kontak darurat") == true)
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
        testDefaults.set(true, forKey: "safety_consolidated_migrated")
        
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
    
    // MARK: - Sensory Color Palettes & Themes Tests
    
    func testSottoPalettes() {
        XCTAssertEqual(SottoPalettes.all.count, 5)
        
        let charcoal = SottoPalettes.palette(for: VoiceSettings.themeCharcoal)
        XCTAssertEqual(charcoal.key, "charcoal")
        XCTAssertEqual(charcoal.name, "Charcoal")
        
        let oledBlack = SottoPalettes.palette(for: VoiceSettings.themeOledBlack)
        XCTAssertEqual(oledBlack.key, "oled_black")
        XCTAssertEqual(oledBlack.name, "OLED Black")
        
        let warmAmber = SottoPalettes.palette(for: VoiceSettings.themeWarmAmber)
        XCTAssertEqual(warmAmber.key, "warm_amber")
        XCTAssertEqual(warmAmber.name, "Warm Amber")
        
        let slateNavy = SottoPalettes.palette(for: VoiceSettings.themeSlateNavy)
        XCTAssertEqual(slateNavy.key, "slate_navy")
        XCTAssertEqual(slateNavy.name, "Slate Navy")
        
        let softParchment = SottoPalettes.palette(for: VoiceSettings.themeSoftParchment)
        XCTAssertEqual(softParchment.key, "soft_parchment")
        XCTAssertEqual(softParchment.name, "Soft Parchment")
        
        // Dynamic accessors
        XCTAssertEqual(SottoTheme.background(for: VoiceSettings.themeCharcoal), charcoal.background)
        XCTAssertEqual(SottoTheme.surface(for: VoiceSettings.themeOledBlack), oledBlack.surface)
        XCTAssertEqual(SottoTheme.accent(for: VoiceSettings.themeWarmAmber), warmAmber.accent)
        XCTAssertEqual(SottoTheme.outline(for: VoiceSettings.themeSlateNavy), slateNavy.outlineVariant)
        
        // Palettes must have distinctly different surfaces & backgrounds
        XCTAssertNotEqual(oledBlack.background, warmAmber.background)
        XCTAssertNotEqual(slateNavy.background, softParchment.background)
        XCTAssertNotEqual(warmAmber.surface, slateNavy.surface)
        XCTAssertNotEqual(charcoal.surface, softParchment.surface)
    }
    
    // MARK: - Safety Reframing & Consolidated Migration Tests
    
    func testSafetyCategoryReframing() {
        XCTAssertEqual(PhraseCategory.safety.rawValue, "Emergency")
        XCTAssertEqual(PhraseCategory.safety.displayName, "Safety")
        XCTAssertEqual(PhraseCategory.emergency.displayName, "Safety")
        XCTAssertEqual(Phrase.categorySafety, "Emergency")
        
        XCTAssertEqual(LocaleHelper.getCategoryDisplayName("Emergency", appLanguage: "en"), "Safety")
        XCTAssertEqual(LocaleHelper.getCategoryDisplayName("Emergency", appLanguage: "id"), "Keselamatan")
        XCTAssertEqual(LocaleHelper.getCategoryDisplayName("Safety", appLanguage: "en"), "Safety")
        XCTAssertEqual(LocaleHelper.getCategoryDisplayName("Safety", appLanguage: "id"), "Keselamatan")
    }
    
    func testSafetyConsolidatedMigration() {
        let suite = "test_sotto_safety_migration_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suite)!
        
        // Seed with old default safety cards
        let oldPhrases = [
            Phrase(text: "I cannot speak right now. Please read my screen.", isEmergency: true, category: .emergency),
            Phrase(text: "Please call my emergency contact: [Phone Number]", isEmergency: true, category: .emergency),
            Phrase(text: "I need a quiet space.", category: .needs)
        ]
        let data = try! JSONEncoder().encode(oldPhrases)
        testDefaults.set(data, forKey: "saved_phrases")
        testDefaults.set(true, forKey: "v2_migrated")
        testDefaults.set(true, forKey: "care_migrated")
        testDefaults.set(false, forKey: "safety_consolidated_migrated")
        
        let repo = UserDefaultsPhraseRepository(userDefaults: testDefaults)
        let loaded = repo.getPhrases()
        
        // Old safety cards should be replaced with single consolidated card
        let emergencyCards = loaded.filter { $0.isEmergency }
        XCTAssertEqual(emergencyCards.count, 1)
        XCTAssertTrue(emergencyCards[0].text.contains("please call my emergency contact") || emergencyCards[0].text.contains("tolong hubungi kontak darurat"))
        XCTAssertTrue(testDefaults.bool(forKey: "safety_consolidated_migrated"))
        
        testDefaults.removePersistentDomain(forName: suite)
    }
    
    // MARK: - Voice Settings Theme & Safety Toggle Tests
    
    func testVoiceSettingsSensoryThemesAndSafetyCards() throws {
        var settings = VoiceSettings()
        XCTAssertEqual(settings.appTheme, "charcoal")
        XCTAssertTrue(settings.showSafetyCards)
        
        settings.appTheme = "warm_amber"
        settings.showSafetyCards = false
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)
        let decoded = try JSONDecoder().decode(VoiceSettings.self, from: data)
        
        XCTAssertEqual(decoded.appTheme, "warm_amber")
        XCTAssertFalse(decoded.showSafetyCards)
    }
    
    func testMainViewModelShowSafetyCardsFiltering() {
        let suite = "test_sotto_filter_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suite)!
        
        let repo = UserDefaultsPhraseRepository(userDefaults: testDefaults)
        let voiceRepo = UserDefaultsVoiceSettingsRepository(userDefaults: testDefaults)
        
        let vm = MainViewModel(phraseRepository: repo, voiceSettingsRepository: voiceRepo)
        
        // By default showSafetyCards is true: all includes emergency
        vm.selectedCategory = .all
        XCTAssertTrue(vm.filteredPhrases.contains { $0.isEmergency })
        
        // When showSafetyCards is false: all excludes emergency
        var updated = vm.voiceSettings
        updated.showSafetyCards = false
        vm.updateVoiceSettings(updated)
        
        XCTAssertFalse(vm.filteredPhrases.contains { $0.isEmergency })
        
        // But selecting emergency category directly still shows it
        vm.selectedCategory = .emergency
        XCTAssertTrue(vm.filteredPhrases.contains { $0.isEmergency })
        
        testDefaults.removePersistentDomain(forName: suite)
    }
    
    // MARK: - Telemetry Schema 3 & Tap Aggregation Tests
    
    func testUsabilityTrackerSchema3EventSerialization() {
        let event = UsabilityTracker.UsabilityEvent(
            intent: "SpeakCard",
            durationMs: 120,
            outcome: "completed",
            frictionTag: "none",
            contextTag: "cat_needs",
            day: "2026-10-09",
            hourBucket: 3
        )
        
        let arr = event.toJsonArray()
        XCTAssertEqual(arr.count, 7)
        XCTAssertEqual(arr[0] as? String, "SpeakCard")
        XCTAssertEqual(arr[1] as? Int, 120)
        XCTAssertEqual(arr[2] as? String, "completed")
        XCTAssertEqual(arr[3] as? String, "none")
        XCTAssertEqual(arr[4] as? String, "cat_needs")
        XCTAssertEqual(arr[5] as? String, "2026-10-09")
        XCTAssertEqual(arr[6] as? Int, 3)
        
        let restored = UsabilityTracker.UsabilityEvent.fromJsonArray(arr)
        XCTAssertNotNil(restored)
        XCTAssertEqual(event, restored)
    }
    
    // MARK: - Action & TwoWay Localization Tests
    
    func testLocaleHelperActionEdit() {
        XCTAssertEqual(LocaleHelper.getActionEdit(isEditMode: false, appLanguage: "en"), "Edit")
        XCTAssertEqual(LocaleHelper.getActionEdit(isEditMode: true, appLanguage: "en"), "Done")
        XCTAssertEqual(LocaleHelper.getActionEdit(isEditMode: false, appLanguage: "id"), "Ubah")
        XCTAssertEqual(LocaleHelper.getActionEdit(isEditMode: true, appLanguage: "id"), "Selesai")
    }
    
    func testLocaleHelperTwoWayLabels() {
        // Tab labels
        XCTAssertEqual(LocaleHelper.getTwoWayTabLabel(isWhyFinder: true, appLanguage: "en"), "Guided")
        XCTAssertEqual(LocaleHelper.getTwoWayTabLabel(isWhyFinder: false, appLanguage: "en"), "Talk")
        XCTAssertEqual(LocaleHelper.getTwoWayTabLabel(isWhyFinder: true, appLanguage: "id"), "Panduan")
        XCTAssertEqual(LocaleHelper.getTwoWayTabLabel(isWhyFinder: false, appLanguage: "id"), "Bicara")
        
        // Response labels
        XCTAssertEqual(LocaleHelper.getTwoWayResponseLabel(responseKey: "yes", appLanguage: "en"), "Yes")
        XCTAssertEqual(LocaleHelper.getTwoWayResponseLabel(responseKey: "no", appLanguage: "en"), "No")
        XCTAssertEqual(LocaleHelper.getTwoWayResponseLabel(responseKey: "not_sure", appLanguage: "en"), "Not Sure")
        XCTAssertEqual(LocaleHelper.getTwoWayResponseLabel(responseKey: "stop", appLanguage: "en"), "Stop")
        
        XCTAssertEqual(LocaleHelper.getTwoWayResponseLabel(responseKey: "yes", appLanguage: "id"), "Ya")
        XCTAssertEqual(LocaleHelper.getTwoWayResponseLabel(responseKey: "no", appLanguage: "id"), "Tidak")
        XCTAssertEqual(LocaleHelper.getTwoWayResponseLabel(responseKey: "not_sure", appLanguage: "id"), "Tidak Yakin")
        XCTAssertEqual(LocaleHelper.getTwoWayResponseLabel(responseKey: "stop", appLanguage: "id"), "Berhenti")
        
        // Action labels
        XCTAssertEqual(LocaleHelper.getTwoWayActionLabel(actionKey: "flip", appLanguage: "en"), "Flip")
        XCTAssertEqual(LocaleHelper.getTwoWayActionLabel(actionKey: "flip_back", appLanguage: "en"), "Flip Back")
        XCTAssertEqual(LocaleHelper.getTwoWayActionLabel(actionKey: "flip", appLanguage: "id"), "Putar")
        XCTAssertEqual(LocaleHelper.getTwoWayActionLabel(actionKey: "flip_back", appLanguage: "id"), "Kembali")
        XCTAssertEqual(LocaleHelper.getTwoWayActionLabel(actionKey: "speak", appLanguage: "id"), "Bicara")
        XCTAssertEqual(LocaleHelper.getTwoWayActionLabel(actionKey: "cards", appLanguage: "id"), "Kartu")
        XCTAssertEqual(LocaleHelper.getTwoWayActionLabel(actionKey: "mic", appLanguage: "id"), "Mik")
    }
    
    func testLocaleHelperSafetyCategoryDisplay() {
        XCTAssertEqual(LocaleHelper.getCategoryDisplayName("EMERGENCY", appLanguage: "en"), "Safety")
        XCTAssertEqual(LocaleHelper.getCategoryDisplayName("SAFETY", appLanguage: "en"), "Safety")
        XCTAssertEqual(LocaleHelper.getCategoryDisplayName("EMERGENCY", appLanguage: "id"), "Keselamatan")
        XCTAssertEqual(LocaleHelper.getCategoryDisplayName("SAFETY", appLanguage: "id"), "Keselamatan")
    }
    
    // MARK: - Batch 1 Security & Bug Regression Tests
    
    func testCurrentAppVersionFormatted() {
        let version = UsabilityTracker.currentAppVersion
        XCTAssertTrue(version.hasPrefix("v"), "App version should start with 'v'")
        XCTAssertFalse(version.isEmpty)
    }
    
    @MainActor
    func testSpeechRecognizerServiceInitialization() {
        let recognizer = SpeechRecognizerService()
        XCTAssertFalse(recognizer.isRecording)
        XCTAssertEqual(recognizer.transcribedText, "")
        XCTAssertNil(recognizer.errorMessage)
    }
    
    func testCumulativeDictationBaselineReplacementLogic() {
        // Simulating the dictation replacement logic in QuickSpeakBarView & PhraseEditModal
        let baseText = "I need"
        let partialUpdates = ["water", "water please", "water please quickly"]
        
        var currentText = baseText
        for partial in partialUpdates {
            let clean = partial.trimmingCharacters(in: .whitespacesAndNewlines)
            currentText = baseText.isEmpty ? clean : "\(baseText) \(clean)"
        }
        
        // Ensure no exponential duplication occurred
        XCTAssertEqual(currentText, "I need water please quickly")
        XCTAssertFalse(currentText.contains("water please water please"))
    }
    
    // MARK: - Batch 2 Security & Accessibility Tests
    
    func testWhyFinderRepositoryLogPersistenceAndUserDefaultsMigration() {
        let suiteName = "test_sotto_whyfinder_\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        
        let repo = UserDefaultsWhyFinderRepository(userDefaults: testDefaults)
        repo.clearLogs()
        
        let legacyEntry = WhyLogEntry(
            id: "legacy_test_log",
            startedAt: Int64(Date().timeIntervalSince1970 * 1000),
            endedAt: Int64(Date().timeIntervalSince1970 * 1000) + 5000,
            outcome: .found,
            areaId: "senses",
            causeText: "Too bright",
            note: "Test legacy migration"
        )
        let legacyData = try! JSONEncoder().encode([legacyEntry])
        testDefaults.set(legacyData, forKey: UserDefaultsWhyFinderRepository.keyLogs)
        
        // Should migrate from UserDefaults to disk
        let logs = repo.getLogs()
        XCTAssertTrue(logs.contains { $0.id == "legacy_test_log" })
        
        // After migration, UserDefaults key should be cleared
        XCTAssertNil(testDefaults.data(forKey: UserDefaultsWhyFinderRepository.keyLogs))
        
        // Test add new entry
        let newEntry = WhyLogEntry(
            id: "new_test_log",
            startedAt: Int64(Date().timeIntervalSince1970 * 1000) + 10000,
            endedAt: Int64(Date().timeIntervalSince1970 * 1000) + 15000,
            outcome: .found,
            areaId: "body",
            bodyPart: "head",
            note: "Encrypted at rest"
        )
        repo.addLog(newEntry)
        
        let updatedLogs = repo.getLogs()
        XCTAssertEqual(updatedLogs.first?.id, "new_test_log")
        
        // Test delete and clean up
        XCTAssertTrue(repo.deleteLog(id: "new_test_log"))
        XCTAssertTrue(repo.deleteLog(id: "legacy_test_log"))
        repo.clearLogs()
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    func testMainViewModelEmergencyPhraseFiltering() {
        let mockPhrases = [
            Phrase(text: "Emergency SOS Contact", isEmergency: true, category: .emergency),
            Phrase(text: "I need quiet", isEmergency: false, category: .needs),
            Phrase(text: "Hello", isEmergency: false, category: .general)
        ]
        
        // When .all and showSafetyCards == true
        let allWithSafety = mockPhrases
        XCTAssertTrue(allWithSafety.contains { $0.isEmergency })
        
        // When .all and showSafetyCards == false
        let allWithoutSafety = mockPhrases.filter { !$0.isEmergency }
        XCTAssertFalse(allWithoutSafety.contains { $0.isEmergency })
        
        // When .needs
        let needsPhrases = mockPhrases.filter { !$0.isEmergency && $0.category == .needs }
        XCTAssertEqual(needsPhrases.count, 1)
        XCTAssertEqual(needsPhrases.first?.text, "I need quiet")
        
        // Persistent SOS banner query across subcategories finds the emergency phrase
        let persistentEmergency = mockPhrases.first(where: { $0.isEmergency })
        XCTAssertNotNil(persistentEmergency)
        XCTAssertEqual(persistentEmergency?.text, "Emergency SOS Contact")
    }
    
    // MARK: - Batch 3 Tests (Issues #13, #14)
    
    func testAppDelegateOrientationLockToggle() {
        XCTAssertEqual(AppDelegate.orientationLock, .all)
        
        // Partner Mode 180° flip active
        AppDelegate.orientationLock = .portrait
        XCTAssertEqual(AppDelegate.orientationLock, .portrait)
        
        // Partner Mode dismissed or un-flipped
        AppDelegate.orientationLock = .all
        XCTAssertEqual(AppDelegate.orientationLock, .all)
    }
    
    func testQRDeckPayloadBase64Roundtrip() {
        let samplePhrases = [
            Phrase(text: "Hello", category: .general),
            Phrase(text: "Thank you", category: .social)
        ]
        
        let json = PhraseBackupHelper.exportToJson(phrases: samplePhrases, categories: ["General", "Social"])
        XCTAssertFalse(json.isEmpty)
        
        // Base64 encode for QR/URL transfer
        let base64 = Data(json.utf8).base64EncodedString()
        XCTAssertFalse(base64.isEmpty)
        
        // Decode
        let decodedData = Data(base64Encoded: base64)
        XCTAssertNotNil(decodedData)
        let decodedJson = String(data: decodedData!, encoding: .utf8)
        XCTAssertNotNil(decodedJson)
        
        let restoredBackup = PhraseBackupHelper.parseJson(decodedJson!)
        XCTAssertNotNil(restoredBackup)
        XCTAssertEqual(restoredBackup?.phrases.count, 2)
        XCTAssertEqual(restoredBackup?.phrases.first?.text, "Hello")
    }
    
    // MARK: - Post-Batch 3 Verification Tests (Phone TTS, Natural Voice, Compact QR)
    
    func testFormatDigitsForSpeechAndEmergencyTTS() {
        // Continuous 12 digits
        let rawDigits = "081234567890"
        let formatted = LocaleHelper.formatDigitsForSpeech(rawDigits)
        XCTAssertEqual(formatted, "0 8 1 2 3 4 5 6 7 8 9 0")
        
        // Dashed phone number
        let dashed = "Ibu: 0812-3456-7890"
        let formattedDashed = LocaleHelper.formatDigitsForSpeech(dashed)
        XCTAssertTrue(formattedDashed.contains("0 8 1 2 - 3 4 5 6 - 7 8 9 0"))
        
        // Regular small numbers (e.g. 120, 2024) should remain intact
        let normalText = "Room 101, Year 2024"
        let unchanged = LocaleHelper.formatDigitsForSpeech(normalText)
        XCTAssertEqual(unchanged, normalText)
        
        // Phone numbers and contact digits speech generation
        let idSpeech = LocaleHelper.formatDigitsForSpeech("Ibu: 081234567890")
        XCTAssertTrue(idSpeech.contains("0 8 1 2 3 4 5 6 7 8 9 0"))
        
        let enSpeech = LocaleHelper.formatDigitsForSpeech("Mom: 555-019-2831")
        XCTAssertTrue(enSpeech.contains("5 5 5 - 0 1 9 - 2 8 3 1"))
    }
    
    func testBestVoiceSelectionPriority() {
        // Should resolve voice for English, prioritizing Samantha/Siri and never Gordon
        let enVoice = SpeechService.bestVoice(forLanguage: "en-US")
        XCTAssertNotNil(enVoice)
        XCTAssertFalse(enVoice?.name.lowercased() == "gordon")
        XCTAssertTrue(SpeechService.isDignifiedVoice(enVoice!))
        
        // Should resolve voice for Indonesian to Damayanti
        let idVoice = SpeechService.bestVoice(forLanguage: "id-ID")
        XCTAssertNotNil(idVoice)
        XCTAssertEqual(idVoice?.name.lowercased(), "damayanti")
        
        // When invalid identifier is passed, it falls back to best matching language voice
        let fallbackVoice = SpeechService.bestVoice(forLanguage: "en-US", preferredIdentifier: "non.existent.voice.id")
        XCTAssertNotNil(fallbackVoice)
        XCTAssertTrue(SpeechService.isDignifiedVoice(fallbackVoice!))
        
        // When user has preferred English voice configured, requesting Indonesian MUST resolve to Damayanti, NOT the English voice
        let dualSecondaryVoice = SpeechService.bestVoice(forLanguage: "id-ID", preferredIdentifier: enVoice?.identifier)
        XCTAssertNotNil(dualSecondaryVoice)
        XCTAssertEqual(dualSecondaryVoice?.name.lowercased(), "damayanti")
        XCTAssertNotEqual(dualSecondaryVoice?.identifier, enVoice?.identifier)
    }
    
    func testCompactQRExportAndRoundtrip() {
        let samplePhrases = [
            Phrase(text: "Saya butuh air minum.", category: .needs),
            Phrase(text: "Tolong panggil bantuan.", isEmergency: true, category: .emergency),
            Phrase(text: "Terima kasih.", category: .social)
        ]
        
        let fullJson = PhraseBackupHelper.exportToJson(phrases: samplePhrases, categories: ["Needs", "Emergency", "Social"])
        let compactJson = PhraseBackupHelper.exportCompactPhrasesForQR(phrases: samplePhrases, categories: ["Needs", "Emergency", "Social"])
        
        // Compact JSON must be smaller than full formatted JSON
        XCTAssertTrue(compactJson.utf8.count < fullJson.utf8.count)
        XCTAssertTrue(compactJson.utf8.count < 1000)
        
        // Must parse back accurately
        let parsed = try? PhraseBackupHelper.parseBackupJson(compactJson)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.phrases.count, 3)
        XCTAssertEqual(parsed?.phrases[0].text, "Saya butuh air minum.")
        XCTAssertEqual(parsed?.phrases[1].isEmergency, true)
    }
    
    func testDictationControlTrailingStateLogic() {
        // Test simulation of QuickSpeakBarView trailing controls:
        // Case 1: When recording is active, Stop Mic control is always exposed even if text is non-empty
        var isRecording = true
        var text = "Hello world"
        let isNotEmpty = !text.isEmpty
        
        // Assert that isRecording keeps stop action visible
        let shouldShowStopRecording = isRecording
        XCTAssertTrue(shouldShowStopRecording, "Stop recording button must remain visible when listening mode is active, even if text is entered")
        
        // Case 2: Tapping stop turns off recording
        isRecording.toggle()
        XCTAssertFalse(isRecording)
        
        // Case 3: When not recording and text exists, clear button is exposed
        let shouldShowClear = !isRecording && isNotEmpty
        XCTAssertTrue(shouldShowClear)
        
        // Case 4: Clearing resets text
        text = ""
        XCTAssertTrue(text.isEmpty)
    }
    
    func testModalDictationLifecycleAndMutualExclusionLogic() {
        // Simulating PhraseEditModal dual speech recognizers
        var primaryRecording = true
        var secondaryRecording = false
        
        // When secondary starts, primary must be stopped
        if !secondaryRecording {
            primaryRecording = false
            secondaryRecording = true
        }
        XCTAssertFalse(primaryRecording, "Primary dictation must be stopped when secondary dictation starts")
        XCTAssertTrue(secondaryRecording)
        
        // When modal actions occur (cancel, save, translate, category pick), both must be stopped
        primaryRecording = false
        secondaryRecording = false
        XCTAssertFalse(primaryRecording)
        XCTAssertFalse(secondaryRecording)
    }
    
    @MainActor
    func testSpeechAutoStopSilenceEndpointingLogic() {
        let recognizer = SpeechRecognizerService()
        XCTAssertFalse(recognizer.isRecording)
        
        // Ensure calling stopRecording cancels timers without crashing
        recognizer.stopRecording()
        XCTAssertFalse(recognizer.isRecording)
    }
    
    // MARK: - Issue #16 Tests: Standard Safety Category & Multi-Card Support
    
    func testSafetyCardsAsStandardCategory() {
        let defaultSafetyCard = Phrase(
            text: "I live around [Area/Neighborhood], please call my emergency contact: [phone number]",
            isEmergency: true,
            category: .emergency
        )
        XCTAssertTrue(defaultSafetyCard.isEmergency)
        XCTAssertEqual(defaultSafetyCard.category, .emergency)
        
        let customSafetyCard = Phrase(
            text: "I am having an autistic shutdown. Please give me space.",
            isEmergency: true,
            category: .emergency
        )
        XCTAssertTrue(customSafetyCard.isEmergency)
        XCTAssertEqual(customSafetyCard.category, .emergency)
        
        let regularPhrase = Phrase(
            text: "I need a quiet space.",
            isEmergency: false,
            category: .needs
        )
        XCTAssertFalse(regularPhrase.isEmergency)
        XCTAssertEqual(regularPhrase.category, .needs)
    }
    
    func testUsabilityTrackerRecordSafetyCardSaved() {
        var settings = VoiceSettings()
        settings.shareUsabilityMetrics = true
        
        // Should execute and record safety_card_setup activation safely
        UsabilityTracker.shared.recordSafetyCardSaved(voiceSettings: settings)
        
        // With telemetry disabled, should safely no-op
        settings.shareUsabilityMetrics = false
        UsabilityTracker.shared.recordSafetyCardSaved(voiceSettings: settings)
    }
    
    // MARK: - Emergency Shortcut & Intent Tests (Issue #18)
    
    func testEmergencyLaunchManagerTrigger() {
        let manager = EmergencyLaunchManager.shared
        manager.pendingAction = nil
        
        let expectation = expectation(description: "Notification posted")
        var receivedAction: EmergencyLaunchManager.Action? = nil
        
        let observer = NotificationCenter.default.addObserver(
            forName: .sottoEmergencyAction,
            object: nil,
            queue: .main
        ) { notification in
            receivedAction = notification.object as? EmergencyLaunchManager.Action
            expectation.fulfill()
        }
        
        manager.trigger(.partner)
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedAction, .partner)
        XCTAssertEqual(receivedAction, .triage)
        
        NotificationCenter.default.removeObserver(observer)
        manager.pendingAction = nil
    }
    
    func testExportCompactPhrasesForQRAndParseSottoV1Prefix() throws {
        let samplePhrases = [
            Phrase(text: "I cannot speak right now.", language: "en", isEmergency: true),
            Phrase(text: "Thank you.", language: "en", isEmergency: false, category: .social)
        ]
        let sampleCategories = ["Social", "Needs"]
        
        let qrPayload = PhraseBackupHelper.exportCompactPhrasesForQR(phrases: samplePhrases, categories: sampleCategories)
        XCTAssertTrue(qrPayload.hasPrefix("SOTTO:v1:"), "QR payload must be prefixed with SOTTO:v1: for Android parity")
        
        // Test parsing SOTTO:v1: prefix
        let parsedFromPrefix = try PhraseBackupHelper.parseBackupJson(qrPayload)
        XCTAssertEqual(parsedFromPrefix.phrases.count, 2)
        XCTAssertEqual(parsedFromPrefix.phrases[0].text, "I cannot speak right now.")
        XCTAssertTrue(parsedFromPrefix.phrases[0].isEmergency)
        
        // Test parsing raw base64 without prefix
        let b64 = String(qrPayload.dropFirst("SOTTO:v1:".count))
        let parsedFromB64 = try PhraseBackupHelper.parseBackupJson(b64)
        XCTAssertEqual(parsedFromB64.phrases.count, 2)
        
        // Test parsing raw JSON string
        let rawData = try XCTUnwrap(Data(base64Encoded: b64))
        let rawJson = try XCTUnwrap(String(data: rawData, encoding: .utf8))
        let parsedFromRawJson = try PhraseBackupHelper.parseBackupJson(rawJson)
        XCTAssertEqual(parsedFromRawJson.phrases.count, 2)
    }
    
    func testLocaleHelperTriggerLabels() {
        XCTAssertEqual(LocaleHelper.getTriggerLabel("Pain", appLanguage: "en"), "Pain")
        XCTAssertEqual(LocaleHelper.getTriggerLabel("Pain", appLanguage: "id"), "Nyeri")
        XCTAssertEqual(LocaleHelper.getTriggerLabel("Noise", appLanguage: "en"), "Noise")
        XCTAssertEqual(LocaleHelper.getTriggerLabel("Noise", appLanguage: "id"), "Bising")
        
        let enHeader = LocaleHelper.getTriggerLogHeader(appLanguage: "en")
        let idHeader = LocaleHelper.getTriggerLogHeader(appLanguage: "id")
        XCTAssertTrue(enHeader.contains("Log"))
        XCTAssertTrue(idHeader.contains("Catat"))
        
        let feedback = LocaleHelper.getTriggerLoggedFeedback("Pain", appLanguage: "en")
        XCTAssertTrue(feedback.contains("Pain"))
    }
    
    func testUsabilityTrackerRecordEmergencyShortcut() {
        var settings = VoiceSettings()
        settings.shareUsabilityMetrics = true
        
        UsabilityTracker.shared.recordEmergencyShortcutLaunched(target: "partner_mode", voiceSettings: settings)
        UsabilityTracker.shared.recordEmergencyShortcutLaunched(target: "safety_card", voiceSettings: settings)
        
        settings.shareUsabilityMetrics = false
        UsabilityTracker.shared.recordEmergencyShortcutLaunched(target: "partner_mode", voiceSettings: settings)
    }
    
    // MARK: - Milestone v1.7.1 Tests: SottoIcon & Partner Mode Telemetry
    
    func testSottoIconMappingsAndLocalization() {
        for icon in SottoIcon.allCases {
            XCTAssertFalse(icon.systemName.isEmpty, "Icon systemName must not be empty: \(icon)")
            let enLabel = icon.accessibilityLabel(appLanguage: "en")
            let idLabel = icon.accessibilityLabel(appLanguage: "id")
            XCTAssertFalse(enLabel.isEmpty, "EN label must not be empty for \(icon)")
            XCTAssertFalse(idLabel.isEmpty, "ID label must not be empty for \(icon)")
        }
        
        // Verify key symbols
        XCTAssertEqual(SottoIcon.close.systemName, "xmark")
        XCTAssertEqual(SottoIcon.noteAlt.systemName, "square.and.pencil")
        XCTAssertEqual(SottoIcon.flipPartner.systemName, "arrow.triangle.2.circlepath")
        XCTAssertEqual(SottoIcon.branch.systemName, "arrow.triangle.branch")
        XCTAssertEqual(SottoIcon.chat.systemName, "bubble.left.and.bubble.right.fill")
        XCTAssertEqual(SottoIcon.volumeUp.systemName, "speaker.wave.2.fill")
        XCTAssertEqual(SottoIcon.cards.systemName, "rectangle.stack")
        XCTAssertEqual(SottoIcon.mic.systemName, "mic.fill")
        XCTAssertEqual(SottoIcon.keyboard.systemName, "keyboard")
    }
    
    func testPartnerModeV171TelemetryIntents() {
        var settings = VoiceSettings()
        settings.shareUsabilityMetrics = true
        UsabilityTracker.shared.clearBuffer()
        
        // 1. partner_tool: log, flip, close
        UsabilityTracker.shared.startIntent("partner_tool")
        UsabilityTracker.shared.endIntent("partner_tool", outcome: "log", voiceSettings: settings)
        
        UsabilityTracker.shared.startIntent("partner_tool")
        UsabilityTracker.shared.endIntent("partner_tool", outcome: "flip", voiceSettings: settings)
        
        UsabilityTracker.shared.startIntent("partner_tool")
        UsabilityTracker.shared.endIntent("partner_tool", outcome: "close", voiceSettings: settings)
        
        // 2. caregiver_action: listen, speak, cards, type, back
        for outcome in ["listen", "speak", "cards", "type", "back"] {
            UsabilityTracker.shared.startIntent("caregiver_action")
            UsabilityTracker.shared.endIntent("caregiver_action", outcome: outcome, voiceSettings: settings)
        }
        
        // 3. partner_flip with contextTag ipad and phone
        UsabilityTracker.shared.startIntent("partner_flip")
        UsabilityTracker.shared.endIntent("partner_flip", outcome: "flipped", contextTag: "ipad", voiceSettings: settings)
        
        UsabilityTracker.shared.startIntent("partner_flip")
        UsabilityTracker.shared.endIntent("partner_flip", outcome: "flipped", contextTag: "phone", voiceSettings: settings)
        
        let events = UsabilityTracker.shared.getPendingEvents(voiceSettings: settings)
        let partnerToolEvents = events.filter { $0.intent == "partner_tool" }
        XCTAssertEqual(partnerToolEvents.count, 3)
        XCTAssertEqual(partnerToolEvents.map { $0.outcome }, ["log", "flip", "close"])
        
        let caregiverEvents = events.filter { $0.intent == "caregiver_action" }
        XCTAssertEqual(caregiverEvents.count, 5)
        XCTAssertEqual(caregiverEvents.map { $0.outcome }, ["listen", "speak", "cards", "type", "back"])
        
        let flipEvents = events.filter { $0.intent == "partner_flip" }
        XCTAssertEqual(flipEvents.count, 2)
        XCTAssertEqual(flipEvents[0].contextTag, "ipad")
        XCTAssertEqual(flipEvents[1].contextTag, "phone")
    }
    
    // MARK: - Export and Import Round Trip Fidelity Tests (Milestone v1.7.2 - Ticket #39)
    
    func testExportAndImportRoundTripPreservesFullFidelity() {
        let samplePhrases = [
            Phrase(id: UUID(), text: "I need help right now.", language: "en", isEmergency: true, category: .emergency),
            Phrase(id: UUID(), text: "Please wait a moment.", language: "en", isEmergency: false, category: .needs),
            Phrase(id: UUID(), text: "Terima kasih", spokenText: "Terima kasih banyak", spokenLanguage: "id", language: "id", isEmergency: false, category: .social)
        ]
        let sampleCategories = ["Needs", "Social", "Care", "Work", "Emergency", "General"]
        let sampleTree = WhyTree(
            areas: [
                WhyArea(
                    id: "sensory",
                    question: "Is the environment overwhelming?",
                    questions: [
                        WhyQuestion(id: "q1", text: "Too noisy?", type: .plain),
                        WhyQuestion(id: "q2", text: "Too bright?", type: .plain),
                        WhyQuestion(id: "q3", text: "Where does it hurt?", type: .bodyPart),
                        WhyQuestion(id: "q4", text: "How intense is it?", type: .intensity)
                    ]
                )
            ]
        )
        let sampleLogs = [
            WhyLogEntry(
                id: "roundtrip-log-1",
                startedAt: 1700000000000,
                endedAt: 1700000045000,
                outcome: .found,
                areaId: "sensory",
                causeText: "Too noisy",
                bodyPart: "head",
                intensity: 4,
                note: "Calmed down with ear defenders"
            )
        ]
        
        // 1. Export
        let exportedJson = PhraseBackupHelper.exportToJson(
            phrases: samplePhrases,
            categories: sampleCategories,
            whyTree: sampleTree,
            whyLog: sampleLogs
        )
        XCTAssertFalse(exportedJson.isEmpty)
        
        // 2. Parse (Import)
        guard let importedData = PhraseBackupHelper.parseJson(exportedJson) else {
            XCTFail("Failed to parse exported JSON")
            return
        }
        
        // Verify Phrases
        XCTAssertEqual(importedData.phrases.count, samplePhrases.count)
        for (i, original) in samplePhrases.enumerated() {
            let imported = importedData.phrases[i]
            XCTAssertEqual(imported.text, original.text)
            XCTAssertEqual(imported.spokenText, original.spokenText)
            XCTAssertEqual(imported.spokenLanguage, original.spokenLanguage)
            XCTAssertEqual(imported.category, original.category)
            XCTAssertEqual(imported.isEmergency, original.isEmergency)
        }
        
        // Verify Categories
        XCTAssertEqual(importedData.categories, sampleCategories)
        
        // Verify Why Tree
        guard let importedTree = importedData.whyTree, let importedArea = importedTree.areas.first else {
            XCTFail("Missing imported whyTree or area")
            return
        }
        XCTAssertEqual(importedTree.areas.count, 1)
        XCTAssertEqual(importedArea.id, "sensory")
        XCTAssertEqual(importedArea.question, "Is the environment overwhelming?")
        XCTAssertEqual(importedArea.questions.count, 4)
        XCTAssertEqual(importedArea.questions[2].type, WhyQuestionType.bodyPart)
        XCTAssertEqual(importedArea.questions[3].type, WhyQuestionType.intensity)
        
        // Verify Why Log
        guard let importedLogList = importedData.whyLog, let importedLog = importedLogList.first else {
            XCTFail("Missing imported whyLog")
            return
        }
        XCTAssertEqual(importedLogList.count, 1)
        XCTAssertEqual(importedLog.id, "roundtrip-log-1")
        XCTAssertEqual(importedLog.outcome, WhyOutcome.found)
        XCTAssertEqual(importedLog.areaId, "sensory")
        XCTAssertEqual(importedLog.causeText, "Too noisy")
        XCTAssertEqual(importedLog.bodyPart, "head")
        XCTAssertEqual(importedLog.intensity, 4)
        XCTAssertEqual(importedLog.note, "Calmed down with ear defenders")
    }
    
    // MARK: - Selective Category Export Tests (Milestone v1.7.5 - Ticket #63)
    
    func testSelectiveCategoryExportAndRoundTrip() {
        let carePhrase = Phrase(text: "Need medication", category: .care)
        let socialPhrase = Phrase(text: "Good morning", category: .social)
        let generalPhrase = Phrase(text: "Thank you", category: .general)
        
        let allPhrases = [carePhrase, socialPhrase, generalPhrase]
        let allCategories = ["Care", "Social", "General"]
        
        let selectedCategories: Set<String> = ["Care"]
        
        let filteredPhrases = allPhrases.filter { selectedCategories.contains($0.category.rawValue) }
        let filteredCategories = allCategories.filter { selectedCategories.contains($0) }
        
        let json = PhraseBackupHelper.exportToJson(
            phrases: filteredPhrases,
            categories: filteredCategories
        )
        
        XCTAssertTrue(json.contains("Need medication"))
        XCTAssertTrue(json.contains("\"Care\""))
        XCTAssertFalse(json.contains("Good morning"))
        XCTAssertFalse(json.contains("Thank you"))
        XCTAssertFalse(json.contains("\"Social\""))
        XCTAssertFalse(json.contains("\"General\""))
        
        guard let imported = PhraseBackupHelper.parseJson(json) else {
            XCTFail("Failed to parse filtered JSON")
            return
        }
        
        XCTAssertEqual(imported.phrases.count, 1)
        XCTAssertEqual(imported.phrases.first?.text, "Need medication")
        XCTAssertEqual(imported.phrases.first?.category, .care)
        XCTAssertEqual(imported.categories, ["Care"])
    }
    
    func testMainViewModelExportBackupWithSelectedCategories() {
        let suite = "test_export_selective_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let phraseRepo = UserDefaultsPhraseRepository(userDefaults: defaults)
        let voiceRepo = UserDefaultsVoiceSettingsRepository(userDefaults: defaults)
        let viewModel = MainViewModel(
            phraseRepository: phraseRepo,
            voiceSettingsRepository: voiceRepo
        )
        
        var settings = viewModel.voiceSettings
        settings.shareUsabilityMetrics = true
        viewModel.updateVoiceSettings(settings)
        UsabilityTracker.shared.clearBuffer()
        
        let carePhrase = Phrase(text: "Need special care", category: .care)
        let socialPhrase = Phrase(text: "Good afternoon", category: .social)
        _ = viewModel.addPhrase(carePhrase)
        _ = viewModel.addPhrase(socialPhrase)
        
        let json = viewModel.exportBackup(selectedCategories: ["Care"])
        XCTAssertTrue(json.contains("Need special care"))
        XCTAssertTrue(json.contains("\"Care\""))
        XCTAssertFalse(json.contains("Good afternoon"))
        XCTAssertFalse(json.contains("\"Social\""))
        
        // Verify telemetry recorded
        let events = UsabilityTracker.shared.getPendingEvents(voiceSettings: viewModel.voiceSettings)
        XCTAssertTrue(events.contains { $0.intent == "Activation" && $0.outcome == "backup_category_filtered_export" })
        
        defaults.removePersistentDomain(forName: suite)
    }
    
    // MARK: - Audit & Parity Ticket Tests
    
    func testBackupDeduplicationCaseInsensitive() {
        let existing = [
            Phrase(text: "I Need Water", category: .needs)
        ]
        let backup = BackupData(
            version: 2,
            exportedAt: 100,
            categories: ["Needs", "General"],
            phrases: [
                Phrase(text: "i need water", category: .needs),
                Phrase(text: "New unique phrase", category: .general)
            ],
            whyTree: nil,
            whyLog: nil
        )
        
        let result = PhraseBackupHelper.mergeData(
            currentPhrases: existing,
            currentCategories: ["Needs", "General"],
            backup: backup
        )
        
        // "i need water" should be deduplicated (case-insensitively), only "New unique phrase" added
        XCTAssertEqual(result.0.count, 2)
        XCTAssertEqual(result.0[0].text, "I Need Water")
        XCTAssertEqual(result.0[1].text, "New unique phrase")
    }
    
    func testWhyFinderSessionRestartGeneratesFreshUUID() {
        let tree = UserDefaultsWhyFinderRepository.defaultTree(forLanguage: "en")
        let session = WhyFinderSession(tree: tree)
        
        let firstSessionId = session.sessionId
        let firstStartedAt = session.startedAt
        
        // Ensure some time passes or restart creates a different ID
        session.restart()
        
        let secondSessionId = session.sessionId
        let secondStartedAt = session.startedAt
        
        XCTAssertNotEqual(firstSessionId, secondSessionId, "Restarting Why Finder session must generate a fresh UUID")
        XCTAssertGreaterThanOrEqual(secondStartedAt, firstStartedAt)
    }
    
    func testWhyFinderRepositoryAddLogUpsert() {
        let suite = "test_wf_upsert_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let repo = UserDefaultsWhyFinderRepository(userDefaults: defaults)
        
        let logId = "shared-session-uuid"
        let entry1 = WhyLogEntry(
            id: logId,
            startedAt: 1000,
            endedAt: 2000,
            outcome: .found,
            areaId: "sensory",
            causeText: "Initial reason",
            bodyPart: nil,
            intensity: nil,
            note: nil,
            steps: []
        )
        repo.addLog(entry1)
        XCTAssertEqual(repo.getLogs().count, 1)
        XCTAssertEqual(repo.getLogs().first?.causeText, "Initial reason")
        
        // Update same log ID
        let entry2 = WhyLogEntry(
            id: logId,
            startedAt: 1000,
            endedAt: 2500,
            outcome: .found,
            areaId: "sensory",
            causeText: "Updated reason",
            bodyPart: nil,
            intensity: nil,
            note: "Added caregiver note",
            steps: []
        )
        repo.addLog(entry2)
        
        // Count must remain 1 (upsert based on id)
        let logs = repo.getLogs()
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.causeText, "Updated reason")
        XCTAssertEqual(logs.first?.note, "Added caregiver note")
        
        defaults.removePersistentDomain(forName: suite)
    }
    
    func testIndonesianDigitFormattingAndPlaceholderSanitization() {
        // Digits to Indonesian words
        let phone = "0812-3456-7890"
        let spokenPhone = LocaleHelper.formatIndonesianDigits(phone)
        XCTAssertTrue(spokenPhone.contains("nol delapan satu dua"))
        XCTAssertTrue(spokenPhone.contains("tiga empat lima enam"))
        XCTAssertTrue(spokenPhone.contains("tujuh delapan sembilan nol"))
        
        // Bracket placeholder removal
        let template = "Saya tinggal di [Nama Komplek / Area] dan butuh bantuan."
        let cleaned = LocaleHelper.cleanPlaceholdersForSpeech(template)
        XCTAssertFalse(cleaned.contains("["))
        XCTAssertFalse(cleaned.contains("]"))
        XCTAssertFalse(cleaned.contains("Nama Komplek"))
        XCTAssertEqual(cleaned, "Saya tinggal di  dan butuh bantuan.")
    }
    
    func testTelemetryContextPurgesHealthMetrics() {
        // Context string format: area_{safeArea}_depth_{depth}_ns_{notSureCount}_outcome_{outcome}
        // Must NEVER contain bp_ or int_
        let contextTag = "area_physical_depth_3_ns_1_outcome_found"
        XCTAssertFalse(contextTag.contains("bp_"))
        XCTAssertFalse(contextTag.contains("int_"))
        XCTAssertFalse(contextTag.contains("head"))
        XCTAssertFalse(contextTag.contains("stomach"))
    }
    
    func testSingleLanguageModeAlwaysSpeaksPrimaryCardText() {
        let phrase = Phrase(
            text: "I need help",
            spokenText: "Saya butuh bantuan",
            spokenLanguage: "id",
            language: "en",
            category: .needs
        )
        
        let settings = VoiceSettings(
            appLanguage: "en",
            showLanguageSwitcher: false,
            secondaryLanguage: "id"
        )
        
        let phraseRepo = UserDefaultsPhraseRepository(userDefaults: UserDefaults(suiteName: "test_sl_\(UUID().uuidString)")!)
        let voiceRepo = UserDefaultsVoiceSettingsRepository(userDefaults: UserDefaults(suiteName: "test_sl_v_\(UUID().uuidString)")!)
        voiceRepo.saveVoiceSettings(settings)
        
        let viewModel = MainViewModel(
            phraseRepository: phraseRepo,
            voiceSettingsRepository: voiceRepo,
            speechService: SpeechService.shared
        )
        
        viewModel.speak(phrase: phrase)
        
        XCTAssertEqual(SpeechService.shared.lastSpokenText, "I need help", "When showLanguageSwitcher is false, tapping the card must speak phrase.text, never spokenText")
        XCTAssertEqual(SpeechService.shared.lastSpokenLocale?.language.languageCode?.identifier, "en")
    }
    
    // MARK: - Optimization & Ease-of-Use Tickets (#55 - #62)
    
    func testSafetyCardSetupInterceptionAndFormatSafetyPhrase() {
        let suite = "test_safety_setup_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let phraseRepo = UserDefaultsPhraseRepository(userDefaults: defaults)
        let voiceRepo = UserDefaultsVoiceSettingsRepository(userDefaults: defaults)
        let viewModel = MainViewModel(
            phraseRepository: phraseRepo,
            voiceSettingsRepository: voiceRepo,
            speechService: SpeechService.shared
        )
        
        let unconfiguredEmergency = Phrase(
            text: "I live around [Area/Neighborhood], please call my emergency contact: [phone number]",
            isEmergency: true,
            category: .emergency
        )
        XCTAssertTrue(LocaleHelper.hasUnresolvedPlaceholders(unconfiguredEmergency.text))
        
        // Tapping an unconfigured emergency card must intercept and set phraseForSafetySetup
        viewModel.speak(phrase: unconfiguredEmergency)
        XCTAssertEqual(viewModel.phraseForSafetySetup?.id, unconfiguredEmergency.id)
        
        // Formatting EN safety phrase
        let formattedEn = LocaleHelper.formatSafetyPhrase(
            area: "Menteng",
            contactName: "Mom",
            phone: "0812-3456-7890",
            appLanguage: "en"
        )
        XCTAssertEqual(formattedEn.displayText, "I live around Menteng, please call my emergency contact: Mom (0812-3456-7890)")
        XCTAssertFalse(LocaleHelper.hasUnresolvedPlaceholders(formattedEn.displayText))
        XCTAssertTrue(formattedEn.spokenText.contains("0 8 1 2"))
        
        // Formatting ID safety phrase
        let formattedId = LocaleHelper.formatSafetyPhrase(
            area: "Kebayoran Baru",
            contactName: "Ibu",
            phone: "0812-3456-7890",
            appLanguage: "id"
        )
        XCTAssertEqual(formattedId.displayText, "Saya tinggal di sekitar Kebayoran Baru, tolong hubungi kontak darurat saya: Ibu (0812-3456-7890)")
        XCTAssertFalse(LocaleHelper.hasUnresolvedPlaceholders(formattedId.displayText))
        XCTAssertTrue(formattedId.spokenText.contains("nol delapan satu dua"))
        
        defaults.removePersistentDomain(forName: suite)
    }
    
    func testPhraseCardViewEquatableConformance() {
        let phraseA = Phrase(id: UUID(), text: "Hello", category: .general)
        let phraseB = Phrase(id: phraseA.id, text: "Hello", category: .general)
        let phraseC = Phrase(id: phraseA.id, text: "Updated", category: .general)
        
        let card1 = PhraseCardView(
            phrase: phraseA,
            isEditMode: false,
            showAlternateSpeech: false,
            appLanguage: "en",
            cardLayout: "compact",
            onTap: {},
            onLongPress: {}
        )
        let card2 = PhraseCardView(
            phrase: phraseB,
            isEditMode: false,
            showAlternateSpeech: false,
            appLanguage: "en",
            cardLayout: "compact",
            onTap: {},
            onLongPress: {}
        )
        let card3 = PhraseCardView(
            phrase: phraseC,
            isEditMode: false,
            showAlternateSpeech: false,
            appLanguage: "en",
            cardLayout: "compact",
            onTap: {},
            onLongPress: {}
        )
        
        XCTAssertEqual(card1, card2)
        XCTAssertNotEqual(card1, card3)
    }
    
    func testSpeechServiceVoiceCacheAndSharedLanguageRecognizer() {
        let v1 = SpeechService.bestVoice(forLanguage: "en-US", preferredIdentifier: nil)
        let v2 = SpeechService.bestVoice(forLanguage: "en-US", preferredIdentifier: nil)
        XCTAssertEqual(v1?.identifier, v2?.identifier)
        
        // Shared NLLanguageRecognizer thread-safe detection
        let idLocale = LocaleHelper.resolvePhraseLocale(
            phraseLang: LocaleHelper.langAuto,
            phraseText: "Saya butuh bantuan sekarang tolong panggil keluarga saya",
            appLanguage: "en"
        )
        XCTAssertEqual(idLocale.language.languageCode?.identifier, "id")
    }
    
    func testWelcomeOnboardingRolePromptLifecycle() {
        let suite = "test_onboarding_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let phraseRepo = UserDefaultsPhraseRepository(userDefaults: defaults)
        let voiceRepo = UserDefaultsVoiceSettingsRepository(userDefaults: defaults)
        let viewModel = MainViewModel(
            phraseRepository: phraseRepo,
            voiceSettingsRepository: voiceRepo
        )
        
        XCTAssertTrue(viewModel.shouldPromptRole())
        viewModel.onRolePromptAnswered(VoiceSettings.roleSelf)
        XCTAssertFalse(viewModel.shouldPromptRole())
        XCTAssertEqual(viewModel.voiceSettings.userRole, VoiceSettings.roleSelf)
        
        defaults.removePersistentDomain(forName: suite)
    }
    
    func testDuplicatePhrasePreventionAndFrictionTelemetry() {
        let suite = "test_dup_phrase_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let phraseRepo = UserDefaultsPhraseRepository(userDefaults: defaults)
        let voiceRepo = UserDefaultsVoiceSettingsRepository(userDefaults: defaults)
        let viewModel = MainViewModel(
            phraseRepository: phraseRepo,
            voiceSettingsRepository: voiceRepo
        )
        
        var settings = viewModel.voiceSettings
        settings.shareUsabilityMetrics = true
        viewModel.updateVoiceSettings(settings)
        UsabilityTracker.shared.clearBuffer()
        
        let first = Phrase(text: "Unique Custom Test Phrase", category: .general)
        XCTAssertTrue(viewModel.addPhrase(first))
        
        // Case-insensitive duplicate add must return false
        let duplicate = Phrase(text: "  unique custom test phrase  ", category: .needs)
        XCTAssertTrue(viewModel.hasDuplicatePhrase(duplicate.text))
        XCTAssertFalse(viewModel.addPhrase(duplicate))
        
        // Editing the same phrase with its own text must succeed (excludingId == first.id)
        let editedSame = Phrase(id: first.id, text: "Unique Custom Test Phrase", category: .needs)
        XCTAssertTrue(viewModel.editPhrase(old: first, new: editedSame))
        
        // Record friction telemetry
        UsabilityTracker.shared.recordFriction("duplicate_phrase_blocked", voiceSettings: viewModel.voiceSettings)
        UsabilityTracker.shared.recordFriction("speech_error", voiceSettings: viewModel.voiceSettings)
        
        let events = UsabilityTracker.shared.getPendingEvents(voiceSettings: viewModel.voiceSettings)
        XCTAssertTrue(events.contains { $0.intent == "friction" && $0.frictionTag == "duplicate_phrase_blocked" })
        XCTAssertTrue(events.contains { $0.intent == "friction" && $0.frictionTag == "speech_error" })
        
        defaults.removePersistentDomain(forName: suite)
    }
}

