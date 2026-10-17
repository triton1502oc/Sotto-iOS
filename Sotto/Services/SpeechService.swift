import Foundation
import AVFoundation

public protocol SpeechServiceDelegate: AnyObject {
    func speechDidStart()
    func speechDidFinish()
}

public final class SpeechService: NSObject, @unchecked Sendable, AVSpeechSynthesizerDelegate {
    public static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    public weak var delegate: SpeechServiceDelegate?
    
    @Published public private(set) var isSpeaking = false
    @Published public private(set) var isReady = true
    public private(set) var lastSpokenText: String?
    public private(set) var lastSpokenLocale: Locale?
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        prewarmAudioSession()
    }
    
    public func prewarmAudioSession() {
        let session = AVAudioSession.sharedInstance()
        guard session.category != .playback || session.mode != .spokenAudio else { return }
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }
    
    public func speak(
        text: String,
        language: String = LocaleHelper.langAuto,
        settings: VoiceSettings,
        completion: (() -> Void)? = nil
    ) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let targetLocale = LocaleHelper.resolvePhraseLocale(
            phraseLang: language,
            phraseText: text,
            appLanguage: settings.appLanguage
        )
        
        self.lastSpokenText = text
        self.lastSpokenLocale = targetLocale
        
        let performSpeak = { [weak self] in
            guard let self = self else { return }
            
            // Ensure audio session is in playback mode (re-apply only if altered by mic/ambient chime)
            self.prewarmAudioSession()
            
            let cleaned = LocaleHelper.cleanPlaceholdersForSpeech(text)
            let speechText = LocaleHelper.formatDigitsForSpeech(cleaned, language: targetLocale.language.languageCode?.identifier)
            let utterance = AVSpeechUtterance(string: speechText)
            
            // Rate mapping: Android 1.0 -> iOS AVSpeechUtteranceDefaultSpeechRate (0.5)
            let mappedRate = AVSpeechUtteranceDefaultSpeechRate * settings.speechRate
            utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, mappedRate))
            
            // Pitch mapping: 1:1 directly
            utterance.pitchMultiplier = max(0.5, min(2.0, settings.speechPitch))
            
            // Voice selection - pick user-selected voice or best available neural/enhanced voice (cached O(1))
            let languageCode = targetLocale.identifier.replacingOccurrences(of: "_", with: "-")
            if let bestVoice = SpeechService.bestVoice(forLanguage: languageCode, preferredIdentifier: settings.voiceIdentifier) {
                utterance.voice = bestVoice
            }
            
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            
            self.synthesizer.speak(utterance)
        }
        
        if settings.playAttentionChime {
            ChimePlayer.shared.play(respectSilentSwitch: settings.respectSilentSwitchForChime)
            // 280ms delay matches Android attention chime spacing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                performSpeak()
            }
        } else {
            performSpeak()
        }
    }
    
    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    public static let noveltyVoiceKeywords: Set<String> = [
        "eloquence", "badnews", "bahh", "bells", "boing", "bubbles", "cellos",
        "deranged", "fred", "goodnews", "hysterical", "junior", "kathy", "organ",
        "princess", "ralph", "trinoids", "whisper", "zarvox", "albert", "gordon"
    ]
    
    public static func isDignifiedVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        let idLower = voice.identifier.lowercased()
        let nameLower = voice.name.lowercased()
        for keyword in noveltyVoiceKeywords {
            if idLower.contains(keyword) || nameLower.contains(keyword) {
                return false
            }
        }
        return true
    }
    
    public static func scoreVoice(_ voice: AVSpeechSynthesisVoice, targetLanguage: String) -> Int {
        var score = 0
        
        // 1. Voice Quality (Premium = 3000, Enhanced = 2000, Default = 1000)
        score += voice.quality.rawValue * 1000
        
        // 2. Penalize toy / novelty voices so they are never auto-selected
        if !isDignifiedVoice(voice) {
            score -= 5000
        }
        
        // 3. Match device's current locale region (e.g. en-US vs en-US)
        let currentRegion = Locale.current.identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        if voice.language.lowercased() == currentRegion {
            score += 300
        }
        
        // 4. Exact language-region match to requested code
        let normalizedCode = targetLanguage.replacingOccurrences(of: "_", with: "-").lowercased()
        if voice.language.lowercased() == normalizedCode {
            score += 200
        }
        
        // 5. Prioritize premier flagship Apple natural voices
        let nameLower = voice.name.lowercased()
        if nameLower.contains("siri") {
            score += 150
        } else if nameLower == "samantha" {
            score += 120
        } else if nameLower == "damayanti" {
            score += 120
        } else if nameLower == "ava" || nameLower == "alex" {
            score += 100
        } else if nameLower == "daniel" {
            score += 80
        } else if nameLower == "karen" {
            score += 80
        }
        
        return score
    }
    
    private static var voiceCache: [String: AVSpeechSynthesisVoice] = [:]
    private static let voiceCacheLock = NSLock()
    
    public static func clearVoiceCache() {
        voiceCacheLock.lock()
        voiceCache.removeAll()
        voiceCacheLock.unlock()
    }
    
    public static func bestVoice(forLanguage languageCode: String, preferredIdentifier: String? = nil) -> AVSpeechSynthesisVoice? {
        let normalizedCode = languageCode.replacingOccurrences(of: "_", with: "-").lowercased()
        let langPrefix = String(normalizedCode.prefix(2))
        let cacheKey = "\(normalizedCode)|\(preferredIdentifier ?? "")"
        
        voiceCacheLock.lock()
        if let cached = voiceCache[cacheKey] {
            voiceCacheLock.unlock()
            return cached
        }
        voiceCacheLock.unlock()
        
        // Only use user-preferred voice if its language matches the target language prefix
        if let id = preferredIdentifier, !id.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: id) {
            let vLang = voice.language.replacingOccurrences(of: "_", with: "-").lowercased()
            if vLang == normalizedCode || vLang.starts(with: langPrefix) {
                voiceCacheLock.lock()
                voiceCache[cacheKey] = voice
                voiceCacheLock.unlock()
                return voice
            }
        }
        
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Filter candidate voices that match either the full code or prefix
        let candidates = allVoices.filter {
            let vLang = $0.language.replacingOccurrences(of: "_", with: "-").lowercased()
            return vLang == normalizedCode || vLang.starts(with: langPrefix)
        }
        
        if let best = candidates.max(by: { scoreVoice($0, targetLanguage: languageCode) < scoreVoice($1, targetLanguage: languageCode) }) {
            voiceCacheLock.lock()
            voiceCache[cacheKey] = best
            voiceCacheLock.unlock()
            return best
        }
        
        if let fallback = AVSpeechSynthesisVoice(language: languageCode) {
            voiceCacheLock.lock()
            voiceCache[cacheKey] = fallback
            voiceCacheLock.unlock()
            return fallback
        }
        return nil
    }
    
    public func getAvailableVoices(forLocale locale: Locale? = nil) -> [AVSpeechSynthesisVoice] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        let filtered: [AVSpeechSynthesisVoice]
        if let locale = locale, let langCode = locale.language.languageCode?.identifier {
            filtered = allVoices.filter { $0.language.lowercased().starts(with: langCode.lowercased()) && SpeechService.isDignifiedVoice($0) }
        } else {
            filtered = allVoices.filter { SpeechService.isDignifiedVoice($0) }
        }
        let targetLang = locale?.identifier ?? "en"
        return filtered.sorted {
            SpeechService.scoreVoice($0, targetLanguage: targetLang) > SpeechService.scoreVoice($1, targetLanguage: targetLang)
        }
    }
    
    public func getAvailableLocales() -> [Locale] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let identifiers = Set(voices.map { $0.language })
        return identifiers.map { Locale(identifier: $0) }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.delegate?.speechDidStart()
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.delegate?.speechDidFinish()
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.delegate?.speechDidFinish()
        }
    }
}
