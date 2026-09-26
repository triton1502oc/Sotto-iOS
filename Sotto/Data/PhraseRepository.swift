import Foundation

public protocol PhraseRepositoryProtocol {
    func getPhrases() -> [Phrase]
    func savePhrases(_ phrases: [Phrase])
}

public final class UserDefaultsPhraseRepository: PhraseRepositoryProtocol {
    private let userDefaults: UserDefaults
    private let keyPhrases = "saved_phrases"
    private let keyMigrated = "v2_migrated"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public static func defaultPhrases(forLanguage language: String = Locale.current.language.languageCode?.identifier ?? "en") -> [Phrase] {
        let isIndonesian = (language == "id" || language == "in")
        if isIndonesian {
            return [
                Phrase(text: "Saya tidak bisa bicara sekarang. Tolong baca layar saya.", language: LocaleHelper.langAuto, isEmergency: true, category: .emergency),
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
                Phrase(text: "I cannot speak right now. Please read my screen.", language: LocaleHelper.langAuto, isEmergency: true, category: .emergency),
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
            userDefaults.set(true, forKey: "care_migrated")
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
            let keyCareMigrated = "care_migrated"
            let isCareMigrated = userDefaults.bool(forKey: keyCareMigrated)
            if !isCareMigrated {
                if !phrases.contains(where: { $0.category == .care }) {
                    let careDefaults = Self.defaultPhrases().filter { $0.category == .care }
                    phrases.append(contentsOf: careDefaults)
                }
                userDefaults.set(true, forKey: keyCareMigrated)
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
}
