import Foundation

/// Helper for on-device translation and AAC phrase translation dictionary.
public final class TranslationHelper {
    // Built-in offline dictionary for common AAC phrases (English <-> Indonesian)
    private static let enToIdPhrases: [String: String] = [
        "i cannot speak right now. please read my screen.": "Saya tidak bisa bicara sekarang. Tolong baca layar saya.",
        "i need a quiet space.": "Saya butuh tempat tenang.",
        "please give me time.": "Tolong beri saya waktu.",
        "i need to leave now.": "Saya harus pergi sekarang.",
        "yes, please.": "Ya, silakan.",
        "no, thank you.": "Tidak, terima kasih.",
        "thank you.": "Terima kasih.",
        "hello.": "Halo.",
        "please repeat that.": "Tolong ulangi.",
        "i need help.": "Saya butuh bantuan.",
        "i am in pain.": "Saya merasa sakit.",
        "water please.": "Tolong air minum.",
        "where is the restroom?": "Di mana toilet / kamar mandi?",
        "i am overwhelmed.": "Saya merasa kewalahan.",
        "please write it down.": "Tolong tuliskan.",
        "please wait.": "Tolong tunggu sebentar.",
        "i agree.": "Saya setuju.",
        "i disagree.": "Saya tidak setuju.",
        "i am okay.": "Saya baik-baik saja.",
        "i am not okay.": "Saya sedang tidak baik-baik saja.",
        "goodbye.": "Selamat tinggal.",
        "good morning.": "Selamat pagi.",
        "good night.": "Selamat malam.",
        "are you in pain?": "Apakah merasa sakit?",
        "do you need water or food?": "Apakah butuh minum atau makan?",
        "do you need the restroom?": "Apakah perlu ke kamar mandi?",
        "are you feeling cold or warm?": "Apakah merasa dingin atau panas?",
        "do you want to rest or sleep?": "Apakah ingin istirahat atau tidur?",
        "yes": "Ya",
        "no": "Tidak",
        "repeat": "Ulangi",
        "wait": "Tunggu",
        "listening…": "Mendengarkan…",
        "listening...": "Mendengarkan…",
        "please give me a moment.": "Tolong beri saya waktu sebentar."
    ]
    
    private static let idToEnPhrases: [String: String] = [
        "saya tidak bisa bicara sekarang. tolong baca layar saya.": "I cannot speak right now. Please read my screen.",
        "saya butuh tempat tenang.": "I need a quiet space.",
        "tolong beri saya waktu.": "Please give me time.",
        "saya harus pergi sekarang.": "I need to leave now.",
        "ya, silakan.": "Yes, please.",
        "tidak, terima kasih.": "No, thank you.",
        "terima kasih.": "Thank you.",
        "halo.": "Hello.",
        "tolong ulangi.": "Please repeat that.",
        "saya butuh bantuan.": "I need help.",
        "saya merasa sakit.": "I am in pain.",
        "saya sedang merasa sakit.": "I am in pain.",
        "tolong air minum.": "Water please.",
        "di mana toilet / kamar mandi?": "Where is the restroom?",
        "saya merasa kewalahan.": "I am overwhelmed.",
        "tolong tuliskan.": "Please write it down.",
        "tolong tunggu sebentar.": "Please wait.",
        "saya setuju.": "I agree.",
        "saya tidak setuju.": "I disagree.",
        "saya baik-baik saja.": "I am okay.",
        "saya sedang tidak baik-baik saja.": "I am not okay.",
        "selamat tinggal.": "Goodbye.",
        "selamat pagi.": "Good morning.",
        "selamat malam.": "Good night.",
        "apakah merasa sakit?": "Are you in pain?",
        "apakah butuh minum atau makan?": "Do you need water or food?",
        "apakah perlu ke kamar mandi?": "Do you need the restroom?",
        "apakah merasa dingin atau panas?": "Are you feeling cold or warm?",
        "apakah ingin istirahat atau tidur?": "Do you want to rest or sleep?",
        "ya": "Yes",
        "tidak": "No",
        "ulangi": "Repeat",
        "tunggu": "Wait",
        "mendengarkan…": "Listening…",
        "mendengarkan...": "Listening…",
        "tolong beri saya waktu sebentar.": "Please give me a moment."
    ]
    
    /// Normalizes language code to standard 2-letter ISO code
    public static func normalizeLanguageCode(_ code: String) -> String {
        let lower = code.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lower == "in" || lower == "ind" || lower.starts(with: "id") {
            return "id"
        }
        if lower == "eng" || lower.starts(with: "en") {
            return "en"
        }
        return lower
    }
    
    /// Checks the built-in offline phrase dictionary for an exact or punctuation-agnostic match
    public static func dictionaryTranslation(
        for text: String,
        sourceLang: String,
        targetLang: String
    ) -> String? {
        let normalizedSource = normalizeLanguageCode(sourceLang)
        let normalizedTarget = normalizeLanguageCode(targetLang)
        let key = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if (normalizedSource == "en" && normalizedTarget == "id") {
            if let match = enToIdPhrases[key] {
                return match
            }
            let keyNoDot = key.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            for (k, v) in enToIdPhrases {
                if k.trimmingCharacters(in: CharacterSet(charactersIn: ".")) == keyNoDot {
                    return v
                }
            }
        } else if (normalizedSource == "id" && normalizedTarget == "en") {
            if let match = idToEnPhrases[key] {
                return match
            }
            let keyNoDot = key.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            for (k, v) in idToEnPhrases {
                if k.trimmingCharacters(in: CharacterSet(charactersIn: ".")) == keyNoDot {
                    return v
                }
            }
        }
        return nil
    }
}
