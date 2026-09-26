import SwiftUI

public struct QuickSpeakBarView: View {
    @Binding public var text: String
    public let onSpeak: (String) -> Void
    public let onFullscreen: (String) -> Void
    public var onSaveAsCard: ((String) -> Void)?
    
    @StateObject private var speechRecognizer = SpeechRecognizerService()
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        onSpeak: @escaping (String) -> Void,
        onFullscreen: @escaping (String) -> Void,
        onSaveAsCard: ((String) -> Void)? = nil
    ) {
        self._text = text
        self.onSpeak = onSpeak
        self.onFullscreen = onFullscreen
        self.onSaveAsCard = onSaveAsCard
    }
    
    private var isNotEmpty: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Tier 1: Multi-Line Text Input (1 to 4 lines) with Smart Mic/Clear Toggle
            HStack(alignment: .bottom, spacing: 8) {
                TextField(
                    "",
                    text: $text,
                    prompt: Text("Type something to speak…").foregroundColor(SottoTheme.textSecondary.opacity(0.7)),
                    axis: .vertical
                )
                .lineLimit(1...4)
                .foregroundColor(SottoTheme.textPrimary)
                .font(.system(size: 15))
                .focused($isFocused)
                
                // Smart Trailing Icon: Clear when text present, Dictation mic when empty
                if isNotEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(SottoTheme.textSecondary)
                            .font(.system(size: 17))
                            .padding(.bottom, 2)
                    }
                } else {
                    Button(action: toggleDictation) {
                        Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                            .foregroundColor(speechRecognizer.isRecording ? SottoTheme.danger : SottoTheme.textPrimary)
                            .font(.system(size: 17))
                            .padding(.bottom, 2)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(SottoTheme.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(speechRecognizer.isRecording ? SottoTheme.danger : Color.white.opacity(0.12), lineWidth: 1)
            )
            .demoTarget("quickSpeak_textField")
            .padding(.horizontal, 12)
            
            // Tier 2: Action Row (Fullscreen, Save as Card, Speak)
            HStack {
                HStack(spacing: 8) {
                    // Fullscreen Button
                    Button(action: {
                        if isNotEmpty {
                            onFullscreen(text)
                        }
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isNotEmpty ? SottoTheme.textPrimary : SottoTheme.textDisabled)
                            .frame(width: 40, height: 38)
                            .background(SottoTheme.background)
                            .cornerRadius(10)
                    }
                    .disabled(!isNotEmpty)
                    .demoTarget("quickSpeak_fullscreenButton")
                    
                    // Save as Card Button (visible when text is entered)
                    if isNotEmpty, let onSaveAsCard = onSaveAsCard {
                        Button(action: {
                            onSaveAsCard(text)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(SottoTheme.primary)
                                .frame(width: 40, height: 38)
                                .background(SottoTheme.background)
                                .cornerRadius(10)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // Speak Button
                Button(action: {
                    if isNotEmpty {
                        onSpeak(text)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(isNotEmpty ? SottoTheme.onPrimary : SottoTheme.textDisabled)
                    .frame(width: 52, height: 38)
                    .background(isNotEmpty ? SottoTheme.primary : SottoTheme.surfaceVariant)
                    .cornerRadius(10)
                }
                .disabled(!isNotEmpty)
                .demoTarget("quickSpeak_speakButton")
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .background(SottoTheme.surface)
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
