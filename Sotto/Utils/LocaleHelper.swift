import Foundation
import NaturalLanguage

public enum LocaleHelper {
    public static let langAuto = "auto"
    public static let langSystem = "system"
    public static let langEnglish = "en"
    public static let langIndonesian = "id"
    
    // Common Indonesian words used to detect if a phrase is Indonesian
    private static let indonesianWords: Set<String> = [
        "saya", "aku", "kami", "kita", "kamu", "anda", "dia", "mereka",
        "ini", "itu", "tolong", "bisa", "dapat", "ya", "tidak", "bukan",
        "terima", "kasih", "butuh", "tempat", "tenang", "sebentar",
        "merespons", "merasa", "kewalahan", "tuliskan", "kirim", "pesan",
        "ada", "di", "ke", "dari", "yang", "dan", "untuk", "dengan", "mau",
        "ingin", "makan", "minum", "sakit", "halo", "selamat", "pagi", "siang",
        "sore", "malam", "apa", "siapa", "mengapa", "kenapa", "bagaimana",
        "kapan", "mana", "sudah", "belum", "lagi", "bantu", "permisi", "air"
    ]
    
    // Common English words used to detect if a phrase is English
    private static let englishWords: Set<String> = [
        "i", "me", "my", "we", "our", "you", "your", "he", "she", "it", "they",
        "this", "that", "the", "a", "an", "is", "am", "are", "was", "were", "be",
        "have", "has", "had", "do", "does", "did", "need", "please", "moment",
        "respond", "yes", "no", "feeling", "overwhelmed", "write", "text",
        "water", "food", "help", "hello", "quiet", "space", "right", "now",
        "can", "could", "would", "what", "where", "when", "why", "how", "fine",
        "thank", "thanks", "sorry", "good", "morning", "night", "want"
    ]
    
    public static func getLocaleForLanguage(_ languageCode: String) -> Locale {
        switch languageCode {
        case langSystem:
            return Locale.current
        case langIndonesian, "in":
            return Locale(identifier: "id_ID")
        case langEnglish:
            return Locale(identifier: "en_US")
        default:
            return Locale(identifier: languageCode)
        }
    }
    
    public static func getLanguageDisplayName(_ code: String) -> String {
        if code == langSystem {
            return "System Default"
        }
        let locale = getLocaleForLanguage(code)
        let nativeName = locale.localizedString(forIdentifier: code)?.capitalized ?? code
        let englishLocale = Locale(identifier: "en_US")
        let englishName = englishLocale.localizedString(forIdentifier: code)?.capitalized ?? ""
        
        if nativeName.caseInsensitiveCompare(englishName) == .orderedSame || englishName.isEmpty {
            return nativeName
        } else {
            return "\(nativeName) (\(englishName))"
        }
    }
    
    public static func getAvailableLanguages(installedLocales: [Locale] = []) -> [(code: String, name: String)] {
        var codes = Set<String>()
        codes.insert("en")
        codes.insert("id")
        
        for loc in installedLocales {
            if let langCode = loc.language.languageCode?.identifier, !langCode.isEmpty {
                codes.insert(langCode)
            }
        }
        
        var list = codes.map { (code: $0, name: getLanguageDisplayName($0)) }
        list.sort { $0.name < $1.name }
        return [(code: langSystem, name: "System Default")] + list
    }
    
    public static func getEffectiveLanguage(appLanguage: String) -> String {
        if appLanguage == langSystem {
            let sysLang = Locale.current.language.languageCode?.identifier ?? "en"
            return (sysLang == "in") ? langIndonesian : sysLang
        }
        return (appLanguage == "in") ? langIndonesian : appLanguage
    }
    
    public static func detectLocale(phrase: String, appLanguage: String) -> Locale {
        let tokens = phrase.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        var idCount = 0
        var enCount = 0
        
        for token in tokens {
            if indonesianWords.contains(token) { idCount += 1 }
            if englishWords.contains(token) { enCount += 1 }
        }
        
        if idCount > enCount {
            return Locale(identifier: "id_ID")
        } else if enCount > idCount {
            return Locale(identifier: "en_US")
        }
        
        // Fall back to NaturalLanguage recognizer if word count is tied or zero
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(phrase)
        if let dominant = recognizer.dominantLanguage?.rawValue {
            if dominant == "id" {
                return Locale(identifier: "id_ID")
            } else if dominant == "en" {
                return Locale(identifier: "en_US")
            }
        }
        
        return getLocaleForLanguage(getEffectiveLanguage(appLanguage: appLanguage))
    }
    
    public static func resolvePhraseLocale(phraseLang: String, phraseText: String, appLanguage: String) -> Locale {
        switch phraseLang {
        case langIndonesian, "in":
            return Locale(identifier: "id_ID")
        case langEnglish:
            return Locale(identifier: "en_US")
        case langAuto, "":
            return detectLocale(phrase: phraseText, appLanguage: appLanguage)
        case langSystem:
            return getLocaleForLanguage(getEffectiveLanguage(appLanguage: appLanguage))
        default:
            return getLocaleForLanguage(phraseLang)
        }
    }
    
    public static func getCategoryDisplayName(_ catKey: String, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        switch catKey.uppercased() {
        case "ALL": return isIndonesian ? "Semua" : "All"
        case "EMERGENCY": return isIndonesian ? "Darurat" : "Emergency"
        case "NEEDS": return isIndonesian ? "Kebutuhan" : "Needs"
        case "SOCIAL": return isIndonesian ? "Sosial" : "Social"
        case "CARE": return isIndonesian ? "Perawatan" : "Care"
        case "GENERAL": return isIndonesian ? "Umum" : "General"
        default: return catKey
        }
    }
    
    public static func getAreaDisplayName(_ areaId: String?, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        switch areaId {
        case UserDefaultsWhyFinderRepository.areaBody:
            return isIndonesian ? "Fisik / Tubuh" : "Physical / Body"
        case UserDefaultsWhyFinderRepository.areaSenses:
            return isIndonesian ? "Indra / Lingkungan" : "Senses / Environment"
        case UserDefaultsWhyFinderRepository.areaFeelings:
            return isIndonesian ? "Perasaan / Emosi" : "Feelings / Emotions"
        case UserDefaultsWhyFinderRepository.areaPerson:
            return isIndonesian ? "Seseorang" : "A Person"
        case UserDefaultsWhyFinderRepository.areaHappened:
            return isIndonesian ? "Sesuatu Terjadi" : "Something Happened"
        case UserDefaultsWhyFinderRepository.areaComingUp:
            return isIndonesian ? "Akan Datang" : "Coming Up"
        default:
            return areaId ?? ""
        }
    }
    
    public static func getBodyRegionLabel(_ regionKey: String, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        switch regionKey {
        case BodyRegions.head: return isIndonesian ? "Kepala" : "Head"
        case BodyRegions.eyes: return isIndonesian ? "Mata" : "Eyes"
        case BodyRegions.ears: return isIndonesian ? "Telinga" : "Ears"
        case BodyRegions.teeth: return isIndonesian ? "Gigi / Mulut" : "Teeth / Mouth"
        case BodyRegions.throat: return isIndonesian ? "Tenggorokan" : "Throat"
        case BodyRegions.chest: return isIndonesian ? "Dada" : "Chest"
        case BodyRegions.stomach: return isIndonesian ? "Perut" : "Stomach"
        case BodyRegions.back: return isIndonesian ? "Punggung" : "Back"
        case BodyRegions.armsHands: return isIndonesian ? "Lengan / Tangan" : "Arms / Hands"
        case BodyRegions.legsFeet: return isIndonesian ? "Kaki" : "Legs / Feet"
        case BodyRegions.skin: return isIndonesian ? "Kulit" : "Skin"
        default: return regionKey
        }
    }
}
