import Foundation

public protocol PhraseRepositoryProtocol {
    func getPhrases() -> [Phrase]
    func savePhrases(_ phrases: [Phrase])
    func getCategories() -> [String]
    func saveCategories(_ categories: [String])
    func getCustomCategories() -> [String]
    func saveCustomCategories(_ categories: [String])
}

public final class UserDefaultsPhraseRepository: PhraseRepositoryProtocol {
    private let userDefaults: UserDefaults
    private let keyPhrases = "saved_phrases"
    private let keyCustomCategories = "saved_custom_categories"
    private let keyCategoryOrder = "saved_category_order"
    private let keyMigrated = "v2_migrated"
    private let keyCareMigrated = "care_migrated"
    private let keySafetyConsolidatedMigrated = "safety_consolidated_migrated"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public static func defaultPhrases(forLanguage language: String = Locale.current.language.languageCode?.identifier ?? "en") -> [Phrase] {
        let isIndonesian = (language == "id" || language == "in")
        if isIndonesian {
            return [
                Phrase(text: "Saya tinggal di sekitar [Area / Lingkungan], tolong hubungi kontak darurat saya: [nomor telepon]", language: LocaleHelper.langAuto, isEmergency: true, category: .emergency),
                Phrase(text: "Saya butuh tempat tenang.", language: LocaleHelper.langAuto, isEmergency: false, category: .needs),
                Phrase(text: "Tolong beri saya waktu.", language: LocaleHelper.langAuto, isEmergency: false, category: .needs),
                Phrase(text: "Saya harus pergi sekarang.", language: LocaleHelper.langAuto, isEmergency: false, category: .needs),
                Phrase(text: "Ya, silakan.", language: LocaleHelper.langAuto, isEmergency: false, category: .social),
                Phrase(text: "Tidak, terima kasih.", language: LocaleHelper.langAuto, isEmergency: false, category: .social),
                Phrase(text: "Terima kasih.", language: LocaleHelper.langAuto, isEmergency: false, category: .social),
                Phrase(text: "Apakah merasa sakit?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Apakah butuh minum atau makan?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Apakah perlu ke kamar mandi?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Apakah merasa dingin atau panas?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Apakah ingin istirahat atau tidur?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Halo.", language: LocaleHelper.langAuto, isEmergency: false, category: .general),
                Phrase(text: "Tolong ulangi.", language: LocaleHelper.langAuto, isEmergency: false, category: .general)
            ]
        } else {
            return [
                Phrase(text: "I live around [Area/Neighborhood], please call my emergency contact: [phone number]", language: LocaleHelper.langAuto, isEmergency: true, category: .emergency),
                Phrase(text: "I need a quiet space.", language: LocaleHelper.langAuto, isEmergency: false, category: .needs),
                Phrase(text: "Please give me time.", language: LocaleHelper.langAuto, isEmergency: false, category: .needs),
                Phrase(text: "I need to leave now.", language: LocaleHelper.langAuto, isEmergency: false, category: .needs),
                Phrase(text: "Yes, please.", language: LocaleHelper.langAuto, isEmergency: false, category: .social),
                Phrase(text: "No, thank you.", language: LocaleHelper.langAuto, isEmergency: false, category: .social),
                Phrase(text: "Thank you.", language: LocaleHelper.langAuto, isEmergency: false, category: .social),
                Phrase(text: "Are you in pain?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Do you need water or food?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Do you need the restroom?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Are you feeling cold or warm?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Do you want to rest or sleep?", language: LocaleHelper.langAuto, isEmergency: false, category: .care),
                Phrase(text: "Hello.", language: LocaleHelper.langAuto, isEmergency: false, category: .general),
                Phrase(text: "Please repeat that.", language: LocaleHelper.langAuto, isEmergency: false, category: .general)
            ]
        }
    }
    
    public func getPhrases() -> [Phrase] {
        guard let data = userDefaults.data(forKey: keyPhrases) else {
            let defaults = Self.defaultPhrases()
            savePhrases(defaults)
            userDefaults.set(true, forKey: keyMigrated)
            userDefaults.set(true, forKey: keyCareMigrated)
            userDefaults.set(true, forKey: keySafetyConsolidatedMigrated)
            return defaults
        }
        
        do {
            var phrases = try JSONDecoder().decode([Phrase].self, from: data)
            var needsSave = false
            
            // Sanitize legacy "auto" spoken text
            for i in 0..<phrases.count {
                if phrases[i].spokenText == "auto" {
                    phrases[i].spokenText = nil
                    needsSave = true
                }
            }
            
            // Check emergency migration
            let isMigrated = userDefaults.bool(forKey: keyMigrated)
            if !isMigrated {
                if !phrases.contains(where: { $0.isEmergency }) {
                    if let emergencyDefault = Self.defaultPhrases().first(where: { $0.isEmergency }) {
                        phrases.insert(emergencyDefault, at: 0)
                    }
                }
                userDefaults.set(true, forKey: keyMigrated)
                needsSave = true
            }
            
            // Check Care category migration
            let isCareMigrated = userDefaults.bool(forKey: keyCareMigrated)
            if !isCareMigrated {
                if !phrases.contains(where: { $0.category == .care }) {
                    let careDefaults = Self.defaultPhrases().filter { $0.category == .care }
                    phrases.append(contentsOf: careDefaults)
                }
                userDefaults.set(true, forKey: keyCareMigrated)
                needsSave = true
            }

            // One-time upgrade: Consolidate default Safety cards into single contact/area card
            let isSafetyConsolidated = userDefaults.bool(forKey: keySafetyConsolidatedMigrated)
            if !isSafetyConsolidated {
                let oldDefaultSafetyTexts: Set<String> = [
                    "I cannot speak right now. Please read my screen.",
                    "Please call my emergency contact: [Phone Number]",
                    "I live around [Area / Neighborhood]. Please call my contact.",
                    "Saya tidak bisa bicara sekarang. Tolong baca layar saya.",
                    "Tolong hubungi kontak darurat saya: [Nomor Telepon]",
                    "Saya tinggal di sekitar [Area / Lingkungan]. Tolong hubungi kontak saya."
                ]
                let newSafetyDefault = Self.defaultPhrases().first { $0.isEmergency }
                if let newSafetyDefault = newSafetyDefault {
                    let hadOldDefaults = phrases.contains { $0.isEmergency && oldDefaultSafetyTexts.contains($0.text) }
                    if hadOldDefaults {
                        let firstEmergencyIdx = phrases.firstIndex { $0.isEmergency } ?? 0
                        phrases.removeAll { $0.isEmergency && oldDefaultSafetyTexts.contains($0.text) }
                        let insertIdx = min(max(firstEmergencyIdx, 0), phrases.count)
                        if !phrases.contains(where: { $0.isEmergency }) {
                            phrases.insert(newSafetyDefault, at: insertIdx)
                        }
                    } else if !phrases.contains(where: { $0.isEmergency }) {
                        phrases.insert(newSafetyDefault, at: 0)
                    }
                }
                userDefaults.set(true, forKey: keySafetyConsolidatedMigrated)
                needsSave = true
            }
            
            if needsSave {
                savePhrases(phrases)
            }
            
            return phrases.isEmpty ? Self.defaultPhrases() : phrases
        } catch {
            return Self.defaultPhrases()
        }
    }
    
    public func savePhrases(_ phrases: [Phrase]) {
        do {
            let data = try JSONEncoder().encode(phrases)
            userDefaults.set(data, forKey: keyPhrases)
        } catch {
            // Ignore encoding errors
        }
    }
    
    public func getCategories() -> [String] {
        guard let data = userDefaults.data(forKey: keyCategoryOrder),
              let list = try? JSONDecoder().decode([String].self, from: data) else {
            let legacyCustom = getCustomCategories()
            var result = PhraseCategory.defaultCategoryNames
            for custom in legacyCustom {
                if !result.contains(where: { $0.caseInsensitiveCompare(custom) == .orderedSame }) {
                    result.append(custom)
                }
            }
            saveCategories(result)
            return result
        }
        
        var cleanList: [String] = []
        for cat in list {
            let trimmed = cat.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed.uppercased() != "ALL" && !cleanList.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                cleanList.append(trimmed)
            }
        }
        if !cleanList.contains(where: { $0.caseInsensitiveCompare("Emergency") == .orderedSame }) {
            cleanList.insert("Emergency", at: 0)
        }
        if !cleanList.contains(where: { $0.caseInsensitiveCompare("General") == .orderedSame }) {
            cleanList.append("General")
        }
        return cleanList
    }
    
    public func saveCategories(_ categories: [String]) {
        var cleanList: [String] = []
        for cat in categories {
            let trimmed = cat.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed.uppercased() != "ALL" && !cleanList.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                cleanList.append(trimmed)
            }
        }
        if !cleanList.contains(where: { $0.caseInsensitiveCompare("Emergency") == .orderedSame }) {
            cleanList.insert("Emergency", at: 0)
        }
        if !cleanList.contains(where: { $0.caseInsensitiveCompare("General") == .orderedSame }) {
            cleanList.append("General")
        }
        
        if let data = try? JSONEncoder().encode(cleanList) {
            userDefaults.set(data, forKey: keyCategoryOrder)
        }
    }
    
    public func getCustomCategories() -> [String] {
        guard let data = userDefaults.data(forKey: keyCustomCategories),
              let list = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        var result: [String] = []
        for cat in list {
            let trimmed = cat.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !PhraseCategory.isUndeletableCategory(trimmed) && !result.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                result.append(trimmed)
            }
        }
        return result
    }
    
    public func saveCustomCategories(_ categories: [String]) {
        var cleanList: [String] = []
        for cat in categories {
            let trimmed = cat.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !PhraseCategory.isUndeletableCategory(trimmed) && !cleanList.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                cleanList.append(trimmed)
            }
        }
        if let data = try? JSONEncoder().encode(cleanList) {
            userDefaults.set(data, forKey: keyCustomCategories)
        }
    }
}
