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
        case "EMERGENCY", "SAFETY": return isIndonesian ? "Keselamatan" : "Safety"
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
    
    public static func getActionEdit(isEditMode: Bool, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        if isEditMode {
            return isIndonesian ? "Selesai" : "Done"
        } else {
            return isIndonesian ? "Ubah" : "Edit"
        }
    }
    
    public static func getTwoWayResponseLabel(responseKey: String, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        switch responseKey.lowercased() {
        case "yes": return isIndonesian ? "Ya" : "Yes"
        case "no": return isIndonesian ? "Tidak" : "No"
        case "not_sure", "not sure": return isIndonesian ? "Tidak Yakin" : "Not Sure"
        case "stop": return isIndonesian ? "Berhenti" : "Stop"
        case "repeat": return isIndonesian ? "Ulangi" : "Repeat"
        case "wait": return isIndonesian ? "Tunggu" : "Wait"
        default: return responseKey
        }
    }
    
    public static func getTwoWayTabLabel(isWhyFinder: Bool, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        if isWhyFinder {
            return isIndonesian ? "Panduan" : "Guided"
        } else {
            return isIndonesian ? "Bicara" : "Talk"
        }
    }
    
    public static func getTwoWayActionLabel(actionKey: String, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        switch actionKey.lowercased() {
        case "flip": return isIndonesian ? "Putar" : "Flip"
        case "flip_back": return isIndonesian ? "Kembali" : "Flip Back"
        case "speak": return isIndonesian ? "Bicara" : "Speak"
        case "cards": return isIndonesian ? "Kartu" : "Cards"
        case "back": return isIndonesian ? "Kembali" : "Back"
        case "type": return isIndonesian ? "Ketik" : "Type"
        case "mic": return isIndonesian ? "Mik" : "Mic"
        case "stop": return isIndonesian ? "Berhenti" : "Stop"
        case "listening": return isIndonesian ? "Mendengarkan…" : "Listening…"
        case "replied_prefix": return isIndonesian ? "Menjawab: " : "Replied: "
        case "restart": return isIndonesian ? "Ulangi" : "Restart"
        case "done": return isIndonesian ? "Selesai" : "Done"
        case "cause_found": return isIndonesian ? "Penyebab Ditemukan" : "Cause Found"
        case "unresolved": return isIndonesian ? "Belum Selesai" : "Unresolved"
        case "stopped": return isIndonesian ? "Berhenti" : "Stopped"
        case "dismiss": return isIndonesian ? "Tutup" : "Dismiss"
        case "mic_hint": return isIndonesian ? "Ketuk mikrofon untuk bicara…" : "Tap mic to speak to user…"
        default: return actionKey
        }
    }
    
    public static func getTriggerLabel(_ triggerKey: String, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        switch triggerKey.lowercased() {
        case "pain": return isIndonesian ? "Nyeri" : "Pain"
        case "noise": return isIndonesian ? "Bising" : "Noise"
        case "task": return isIndonesian ? "Tugas" : "Task"
        case "emotion": return isIndonesian ? "Emosi" : "Emotion"
        case "other": return isIndonesian ? "Lainnya" : "Other"
        default: return triggerKey
        }
    }
    
    public static func getTriggerLogHeader(appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        return isIndonesian ? "Catat pemicu ke Catatan Why" : "Log crisis trigger to Why Log"
    }
    
    public static func getTriggerLoggedFeedback(_ triggerLabel: String, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        return isIndonesian ? "Pemicu tercatat: \(triggerLabel) ✓" : "Trigger logged: \(triggerLabel) ✓"
    }
    
    public static func getSettingsTabTitle(tab: Int, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        switch tab {
        case 0:
            return isIndonesian ? "Suara & Ucapan" : "Voice & Speech"
        case 1:
            return isIndonesian ? "Tampilan & Keamanan" : "Appearance & Safety"
        default:
            return isIndonesian ? "Data & Cadangan" : "Data & Backup"
        }
    }
    
    public static func getCardLayoutTitle(appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        return isIndonesian ? "Proporsi Kartu Frasa" : "Phrase Card Proportions"
    }
    
    public static func getCardLayoutDesc(appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        return isIndonesian ? "Pilih antara kartu persegi klasik atau persegi panjang ringkas (+25% kepadatan)" : "Choose between classic square or compact rectangular cards (+25% density)"
    }
    
    public static func getCardLayoutOption(isCompact: Bool, appLanguage: String = "system") -> String {
        let isIndonesian = getEffectiveLanguage(appLanguage: appLanguage) == langIndonesian
        if isCompact {
            return isIndonesian ? "Persegi Panjang Ringkas (1.25:1)" : "Compact Rectangular (1.25:1)"
        } else {
            return isIndonesian ? "Persegi Klasik (1:1)" : "Classic Square (1:1)"
        }
    }
    
    public static func hasUnresolvedPlaceholders(_ text: String) -> Bool {
        text.contains("[") && text.contains("]")
    }

    public static func cleanPlaceholdersForSpeech(_ text: String) -> String {
        guard hasUnresolvedPlaceholders(text) else { return text }
        let pattern = "\\[.*?\\]"
        var cleaned = text.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: ":", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func formatIndonesianDigits(_ matchedStr: String) -> String {
        let digitWords: [Character: String] = [
            "0": "nol",
            "1": "satu",
            "2": "dua",
            "3": "tiga",
            "4": "empat",
            "5": "lima",
            "6": "enam",
            "7": "tujuh",
            "8": "delapan",
            "9": "sembilan"
        ]
        let trimmed = matchedStr.trimmingCharacters(in: .whitespacesAndNewlines)
        let startsWithPlus = trimmed.hasPrefix("+")
        let clean = startsWithPlus ? String(trimmed.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) : trimmed
        
        var sb = ""
        if startsWithPlus {
            sb.append("plus ")
        }
        
        let digitsOnly = clean.filter { $0.isNumber }
        let is62CountryCode = clean.hasPrefix("62") && digitsOnly.count > 8
        var chars = Array(clean)
        var i = 0
        if is62CountryCode {
            sb.append("enam dua, ")
            var digitsSkipped = 0
            while i < chars.count && digitsSkipped < 2 {
                if chars[i].isNumber {
                    digitsSkipped += 1
                }
                i += 1
            }
            while i < chars.count && (chars[i] == " " || chars[i] == "-" || chars[i] == "/" || chars[i] == ".") {
                i += 1
            }
        }
        
        var groupCount = 0
        while i < chars.count {
            let char = chars[i]
            if char.isNumber {
                let word = digitWords[char] ?? String(char)
                sb.append("\(word) ")
                groupCount += 1
                if groupCount == 4 {
                    sb.append(", ")
                    groupCount = 0
                }
            } else if char == "-" || char == "/" || char == " " || char == "." || char == "," || char == "(" || char == ")" {
                if groupCount > 0 {
                    sb.append(", ")
                    groupCount = 0
                }
            }
            i += 1
        }
        
        var result = sb.replacingOccurrences(of: "\\s*,\\s*", with: ", ", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasSuffix(",") {
            result.removeLast()
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func formatDigitsForSpeech(_ text: String, language: String? = nil) -> String {
        let isIndonesian: Bool
        if let lang = language {
            isIndonesian = lang.lowercased().hasPrefix("id") || lang.lowercased().hasPrefix("in")
        } else {
            let detected = detectLocale(phrase: text, appLanguage: "system").identifier
            isIndonesian = detected.lowercased().hasPrefix("id") || detected.lowercased().hasPrefix("in")
        }
        
        // Matches sequences of digits (phone numbers) with optional international prefix, dashes, parens, spaces
        let pattern = "(\\+?[0-9][0-9\\s\\-\\(\\)]{3,}[0-9])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        var result = text
        for match in matches.reversed() {
            let matchedStr = nsString.substring(with: match.range)
            let digitCount = matchedStr.filter { $0.isNumber }.count
            // Format only if there are at least 5 digits (phone numbers, card numbers)
            if digitCount >= 5 {
                let formatted: String
                if isIndonesian {
                    formatted = formatIndonesianDigits(matchedStr)
                } else {
                    var str = ""
                    for char in matchedStr {
                        if char.isNumber {
                            str.append("\(char) ")
                        } else if char == "-" || char == "/" || char == "," {
                            str.append("- ")
                        }
                    }
                    str = str.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    formatted = str.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if let range = Range(match.range, in: result) {
                    result.replaceSubrange(range, with: formatted)
                }
            }
        }
        return result
    }
}

