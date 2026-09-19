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
            return defaults
        }
        
        do {
            var phrases = try JSONDecoder().decode([Phrase].self, from: data)
            
            // Check emergency migration
            let isMigrated = userDefaults.bool(forKey: keyMigrated)
            if !isMigrated {
                if !phrases.contains(where: { $0.isEmergency }) {
                    if let emergencyDefault = Self.defaultPhrases().first(where: { $0.isEmergency }) {
                        phrases.insert(emergencyDefault, at: 0)
                    }
                }
                userDefaults.set(true, forKey: keyMigrated)
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
