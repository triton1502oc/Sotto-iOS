import SwiftUI

public struct QuickSpeakBarView: View {
    @Environment(\.sottoPalette) private var palette
    @Binding public var text: String
    public let onSpeak: (String) -> Void
    public let onFullscreen: (String) -> Void
    public var onSaveAsCard: ((String) -> Void)?
    public var onClear: (() -> Void)?
    
    @StateObject private var speechRecognizer = SpeechRecognizerService()
    @FocusState private var isFocused: Bool
    @State private var baseTextBeforeRecording: String = ""
    
    public init(
        text: Binding<String>,
        onSpeak: @escaping (String) -> Void,
        onFullscreen: @escaping (String) -> Void,
        onSaveAsCard: ((String) -> Void)? = nil,
        onClear: (() -> Void)? = nil
    ) {
        self._text = text
        self.onSpeak = onSpeak
        self.onFullscreen = onFullscreen
        self.onSaveAsCard = onSaveAsCard
        self.onClear = onClear
    }
    
    private var isNotEmpty: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Divider()
                .background(palette.outlineVariant.opacity(0.6))
            
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
                .onSubmit {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                    }
                }
                
                // Trailing Controls: Always show active Stop Mic button when recording; show Clear and Mic when idle
                if speechRecognizer.isRecording {
                    if isNotEmpty {
                        Button(action: {
                            speechRecognizer.stopRecording()
                            onClear?()
                            text = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(SottoTheme.textSecondary)
                                .font(.system(size: 18))
                                .frame(width: 36, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Clear text and stop listening")
                    }
                    
                    Button(action: toggleDictation) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(SottoTheme.danger)
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Stop recording speech")
                    .accessibilityHint("Turns off microphone listening mode")
                } else {
                    if isNotEmpty {
                        Button(action: {
                            onClear?()
                            text = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(SottoTheme.textSecondary)
                                .font(.system(size: 18))
                                .frame(width: 36, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Clear text")
                    }
                    
                    Button(action: toggleDictation) {
                        Image(systemName: "mic")
                            .foregroundColor(isNotEmpty ? palette.textSecondary : palette.textPrimary)
                            .font(.system(size: 18))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Start recording speech")
                    .accessibilityHint("Dictates spoken words into the Quick-Speak bar")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(palette.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(speechRecognizer.isRecording ? SottoTheme.danger : palette.outlineVariant, lineWidth: 1)
            )
            .demoTarget("quickSpeak_textField")
            .padding(.horizontal, 12)
            
            // Tier 2: Action Row (Fullscreen, Save as Card, Speak)
            HStack {
                HStack(spacing: 10) {
                    // Fullscreen Button
                    Button(action: {
                        if isNotEmpty {
                            if speechRecognizer.isRecording {
                                speechRecognizer.stopRecording()
                            }
                            onFullscreen(text)
                        }
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isNotEmpty ? palette.textPrimary : SottoTheme.textDisabled)
                            .frame(width: 44, height: 44)
                            .background(palette.background)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(palette.outlineVariant.opacity(0.7), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                    }
                    .disabled(!isNotEmpty)
                    .accessibilityLabel("Fullscreen view")
                    .accessibilityHint("Shows text in large high-contrast display")
                    .demoTarget("quickSpeak_fullscreenButton")
                    
                    // Save as Card Button (visible when text is entered)
                    if isNotEmpty, let onSaveAsCard = onSaveAsCard {
                        Button(action: {
                            if speechRecognizer.isRecording {
                                speechRecognizer.stopRecording()
                            }
                            onSaveAsCard(text)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(palette.accent)
                                .frame(width: 44, height: 44)
                                .background(palette.background)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(palette.outlineVariant.opacity(0.7), lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Save as phrase card")
                        .accessibilityHint("Adds text to phrase library")
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // Speak Button
                Button(action: {
                    if isNotEmpty {
                        if speechRecognizer.isRecording {
                            speechRecognizer.stopRecording()
                        }
                        onSpeak(text)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(isNotEmpty ? palette.background : SottoTheme.textDisabled)
                    .frame(width: 56, height: 44)
                    .background(isNotEmpty ? palette.accent : palette.surfaceVariant)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                }
                .disabled(!isNotEmpty)
                .accessibilityLabel("Speak aloud")
                .accessibilityHint("Speaks the entered text using text to speech")
                .demoTarget("quickSpeak_speakButton")
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .background(palette.surface)
        .onDisappear {
            speechRecognizer.stopRecording()
        }
    }
    
    private func toggleDictation() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            speechRecognizer.requestPermissions { granted in
                if granted {
                    baseTextBeforeRecording = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    speechRecognizer.startRecording { recognizedText in
                        let cleanRecognized = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if baseTextBeforeRecording.isEmpty {
                            text = cleanRecognized
                        } else {
                            text = "\(baseTextBeforeRecording) \(cleanRecognized)"
                        }
                    }
                }
            }
        }
    }
}
