import Foundation
import AVFoundation

public protocol SpeechServiceDelegate: AnyObject {
    func speechDidStart()
    func speechDidFinish()
}

public final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    public static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    public weak var delegate: SpeechServiceDelegate?
    
    @Published public private(set) var isSpeaking = false
    @Published public private(set) var isReady = true
    
    private override init() {
        super.init()
        synthesizer.delegate = self
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
        
        let performSpeak = { [weak self] in
            guard let self = self else { return }
            
            // Set audio session to playback to ensure sound is played even in silent mode
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                try session.setActive(true)
            } catch {
                // Ignore audio session errors
            }
            
            let utterance = AVSpeechUtterance(string: text)
            
            // Rate mapping: Android 1.0 -> iOS AVSpeechUtteranceDefaultSpeechRate (0.5)
            let mappedRate = AVSpeechUtteranceDefaultSpeechRate * settings.speechRate
            utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, mappedRate))
            
            // Pitch mapping: 1:1 directly
            utterance.pitchMultiplier = max(0.5, min(2.0, settings.speechPitch))
            
            // Voice selection
            if let voiceId = settings.voiceIdentifier,
               let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
                utterance.voice = voice
            } else {
                let languageCode = targetLocale.identifier.replacingOccurrences(of: "_", with: "-")
                if let voice = AVSpeechSynthesisVoice(language: languageCode) {
                    utterance.voice = voice
                } else if let voice = AVSpeechSynthesisVoice(language: targetLocale.language.languageCode?.identifier) {
                    utterance.voice = voice
                }
            }
            
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            
            self.synthesizer.speak(utterance)
        }
        
        if settings.playAttentionChime {
            ChimePlayer.shared.play()
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
    
    public func getAvailableVoices(forLocale locale: Locale? = nil) -> [AVSpeechSynthesisVoice] {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        if let locale = locale, let langCode = locale.language.languageCode?.identifier {
            return allVoices.filter { $0.language.lowercased().starts(with: langCode.lowercased()) }
        }
        return allVoices
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
