import SwiftUI

public struct QuickSpeakBarView: View {
    @Binding public var text: String
    public let onSpeak: (String) -> Void
    public let onFullscreen: (String) -> Void
    
    @StateObject private var speechRecognizer = SpeechRecognizerService()
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        onSpeak: @escaping (String) -> Void,
        onFullscreen: @escaping (String) -> Void
    ) {
        self._text = text
        self.onSpeak = onSpeak
        self.onFullscreen = onFullscreen
    }
    
    private var isNotEmpty: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 8) {
                // Text Field Container
                HStack(spacing: 6) {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text("Type something to speak…").foregroundColor(SottoTheme.textSecondary.opacity(0.7))
                    )
                    .foregroundColor(SottoTheme.textPrimary)
                    .font(.system(size: 15))
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if isNotEmpty {
                            onSpeak(text)
                        }
                    }
                    
                    // Clear Button
                    if isNotEmpty {
                        Button(action: { text = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(SottoTheme.textSecondary)
                                .font(.system(size: 16))
                        }
                    }
                    
                    // Microphone Button for Dictation
                    Button(action: toggleDictation) {
                        Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                            .foregroundColor(speechRecognizer.isRecording ? SottoTheme.danger : SottoTheme.textPrimary)
                            .font(.system(size: 17))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(SottoTheme.background)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(speechRecognizer.isRecording ? SottoTheme.danger : Color.white.opacity(0.12), lineWidth: 1)
                )
                .demoTarget("quickSpeak_textField")
                
                // Fullscreen Button
                Button(action: {
                    if isNotEmpty {
                        onFullscreen(text)
                    }
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isNotEmpty ? SottoTheme.textPrimary : SottoTheme.textDisabled)
                        .frame(width: 44, height: 44)
                        .background(SottoTheme.background)
                        .cornerRadius(10)
                }
                .disabled(!isNotEmpty)
                .demoTarget("quickSpeak_fullscreenButton")
                
                // Speak Button
                Button(action: {
                    if isNotEmpty {
                        onSpeak(text)
                    }
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isNotEmpty ? SottoTheme.onPrimary : SottoTheme.textDisabled)
                        .frame(width: 44, height: 44)
                        .background(isNotEmpty ? SottoTheme.primary : SottoTheme.surfaceVariant)
                        .cornerRadius(10)
                }
                .disabled(!isNotEmpty)
                .demoTarget("quickSpeak_speakButton")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(SottoTheme.surface)
        }
    }
    
    private func toggleDictation() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            speechRecognizer.requestPermissions { granted in
                if granted {
                    speechRecognizer.startRecording { recognizedText in
                        if text.isEmpty {
                            text = recognizedText
                        } else {
                            text = "\(text) \(recognizedText)"
                        }
                    }
                }
            }
        }
    }
}
