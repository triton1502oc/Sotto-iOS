import Foundation
import Speech
import AVFoundation

@MainActor
public final class SpeechRecognizerService: ObservableObject {
    @Published public var isRecording = false
    @Published public var transcribedText = ""
    @Published public var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    private var silenceTask: Task<Void, Never>?
    private var initialTimeoutTask: Task<Void, Never>?
    
    public init() {}
    
    public func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    if #available(iOS 17.0, macOS 14.0, *) {
                        AVAudioApplication.requestRecordPermission { [weak self] granted in
                            DispatchQueue.main.async {
                                if !granted {
                                    self?.errorMessage = "Microphone permission is required in Settings."
                                    UsabilityTracker.shared.recordFriction("speech_error")
                                }
                                completion(granted)
                            }
                        }
                    } else {
                        #if canImport(UIKit)
                        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                            DispatchQueue.main.async {
                                if !granted {
                                    self?.errorMessage = "Microphone permission is required in Settings."
                                    UsabilityTracker.shared.recordFriction("speech_error")
                                }
                                completion(granted)
                            }
                        }
                        #else
                        completion(true)
                        #endif
                    }
                default:
                    self?.errorMessage = "Speech recognition permission is required in Settings."
                    UsabilityTracker.shared.recordFriction("speech_error")
                    completion(false)
                }
            }
        }
    }
    
    public func startRecording(
        locale: Locale = Locale.current,
        autoStopDelay: TimeInterval = 1.8,
        initialTimeout: TimeInterval = 5.0,
        onUpdate: ((String) -> Void)? = nil
    ) {
        // Stop any active task
        stopRecording()
        
        speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            self.errorMessage = "Offline speech recognition is not available on this device."
            UsabilityTracker.shared.recordFriction("speech_error")
            return
        }
        
        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine
        
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Enforce 100% on-device speech recognition when supported to preserve offline privacy
        if speechRecognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            self.isRecording = true
            self.errorMessage = nil
            self.transcribedText = ""
            
            if initialTimeout > 0 {
                startInitialTimeout(duration: initialTimeout)
            }
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let rawText = result.bestTranscription.formattedString
                    let normalized = Self.normalizeHypothesis(rawText)
                    DispatchQueue.main.async {
                        if !normalized.isEmpty {
                            self.transcribedText = normalized
                            onUpdate?(normalized)
                            self.initialTimeoutTask?.cancel()
                            self.initialTimeoutTask = nil
                            if autoStopDelay > 0 {
                                self.resetSilenceTimer(delay: autoStopDelay)
                            }
                        }
                    }
                }
                
                if error != nil || (result?.isFinal ?? false) {
                    DispatchQueue.main.async {
                        self.stopRecording()
                    }
                }
            }
        } catch {
            self.stopRecording()
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func stopRecording() {
        cancelSilenceTimers()
        
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        self.isRecording = false
        
        // Restore playback audio session
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }
    
    private func resetSilenceTimer(delay: TimeInterval) {
        silenceTask?.cancel()
        guard delay > 0 else { return }
        silenceTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.stopRecording()
            } catch {
                // Cancelled
            }
        }
    }
    
    private func startInitialTimeout(duration: TimeInterval) {
        initialTimeoutTask?.cancel()
        guard duration > 0 else { return }
        initialTimeoutTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.stopRecording()
            } catch {
                // Cancelled
            }
        }
    }
    
    private func cancelSilenceTimers() {
        silenceTask?.cancel()
        silenceTask = nil
        initialTimeoutTask?.cancel()
        initialTimeoutTask = nil
    }
    
    /// Collapses progressive prefix repetitions produced by some on-device STT engines
    /// (e.g. "I I need I need water" -> "I need water") while preserving genuine single-word emphasis.
    nonisolated public static func normalizeHypothesis(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        var words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var changed = true
        while changed && words.count >= 2 {
            changed = false
            let maxPrefix = words.count / 2
            for k in stride(from: maxPrefix, through: 1, by: -1) {
                let prefixMatches = (0..<k).allSatisfy {
                    words[$0].caseInsensitiveCompare(words[k + $0]) == .orderedSame
                }
                if !prefixMatches { continue }
                if k >= 2 {
                    words = Array(words.dropFirst(k))
                    changed = true
                    break
                } else {
                    let remaining = Array(words.dropFirst(1))
                    let maxM = remaining.count / 2
                    let hasFollowup: Bool
                    if maxM >= 2 {
                        hasFollowup = (2...maxM).contains { m in
                            (0..<m).allSatisfy {
                                remaining[$0].caseInsensitiveCompare(remaining[m + $0]) == .orderedSame
                            }
                        }
                    } else {
                        hasFollowup = false
                    }
                    if hasFollowup {
                        words = remaining
                        changed = true
                        break
                    }
                }
            }
        }
        return words.joined(separator: " ")
    }
    
    /// Merges existing draft text with a new STT hypothesis without duplicating overlapping prefixes/suffixes.
    nonisolated public static func mergeDictationText(baseText: String, hypothesis: String) -> String {
        let base = baseText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hyp = normalizeHypothesis(hypothesis)
        if base.isEmpty { return hyp }
        if hyp.isEmpty { return base }
        if hyp.caseInsensitiveCompare(base) == .orderedSame { return hyp }
        if hyp.lowercased().hasPrefix(base.lowercased()) {
            if hyp.count == base.count || hyp[hyp.index(hyp.startIndex, offsetBy: base.count)].isWhitespace {
                return hyp
            }
        }
        if base.lowercased().hasSuffix(hyp.lowercased()) {
            if base.count == hyp.count || base[base.index(base.endIndex, offsetBy: -hyp.count - 1)].isWhitespace {
                return base
            }
        }
        let baseWords = base.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let hypWords = hyp.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let maxOverlap = min(baseWords.count, hypWords.count)
        for k in stride(from: maxOverlap, through: 1, by: -1) {
            if k == 1 && baseWords.count > 1 { continue }
            let overlaps = (0..<k).allSatisfy {
                baseWords[baseWords.count - k + $0].caseInsensitiveCompare(hypWords[$0]) == .orderedSame
            }
            if overlaps {
                return (baseWords + hypWords.dropFirst(k)).joined(separator: " ")
            }
        }
        return "\(base) \(hyp)"
    }
}
