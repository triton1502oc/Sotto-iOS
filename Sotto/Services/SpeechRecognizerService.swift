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
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    if #available(iOS 17.0, macOS 14.0, *) {
                        AVAudioApplication.requestRecordPermission { granted in
                            DispatchQueue.main.async {
                                completion(granted)
                            }
                        }
                    } else {
                        #if canImport(UIKit)
                        AVAudioSession.sharedInstance().requestRecordPermission { granted in
                            DispatchQueue.main.async {
                                completion(granted)
                            }
                        }
                        #else
                        completion(true)
                        #endif
                    }
                default:
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
            self.errorMessage = "Speech recognition is not available."
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
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.transcribedText = text
                        onUpdate?(text)
                        
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
}
