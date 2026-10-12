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
        HStack(spacing: 8) {
            // Main Dock Capsule (single row ~52-54pt)
            HStack(spacing: 4) {
                // Leading: Fullscreen Button
                Button(action: {
                    if isNotEmpty {
                        if speechRecognizer.isRecording { speechRecognizer.stopRecording() }
                        onFullscreen(text.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }) {
                    SottoIconView(
                        .fullscreen,
                        size: 18,
                        tint: isNotEmpty ? palette.accent : palette.textSecondary.opacity(0.38)
                    )
                    .frame(width: 38, height: 44)
                    .contentShape(Rectangle())
                }
                .disabled(!isNotEmpty)
                .accessibilityLabel("Fullscreen view")
                .accessibilityHint("Shows text in large high-contrast display")
                .demoTarget("quickSpeak_fullscreenButton")
                
                // Center: Text Field (1 to 4 lines)
                TextField(
                    "",
                    text: $text,
                    prompt: Text("Type something to speak…").foregroundColor(palette.textSecondary.opacity(0.5)),
                    axis: .vertical
                )
                .lineLimit(1...4)
                .foregroundColor(palette.textPrimary)
                .font(.system(size: 15))
                .focused($isFocused)
                .onSubmit {
                    if speechRecognizer.isRecording { speechRecognizer.stopRecording() }
                    if isNotEmpty {
                        onSpeak(text.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
                .demoTarget("quickSpeak_textField")
                
                // Trailing Inline Actions: Stop Mic / Clear / Add Card / Mic
                if speechRecognizer.isRecording {
                    Button(action: toggleDictation) {
                        SottoIconView(.stop, size: 16, tint: SottoTheme.destructiveRed)
                            .frame(width: 36, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Stop recording speech")
                }
                
                if isNotEmpty {
                    Button(action: {
                        if speechRecognizer.isRecording { speechRecognizer.stopRecording() }
                        onClear?()
                        text = ""
                    }) {
                        SottoIconView(.close, size: 14, tint: palette.textSecondary.opacity(0.65))
                            .frame(width: 34, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Clear text")
                    
                    if let onSaveAsCard = onSaveAsCard {
                        Button(action: {
                            if speechRecognizer.isRecording { speechRecognizer.stopRecording() }
                            onSaveAsCard(text.trimmingCharacters(in: .whitespacesAndNewlines))
                        }) {
                            SottoIconView(.add, size: 18, tint: palette.accent)
                                .frame(width: 34, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Save as phrase card")
                        .accessibilityHint("Adds text to phrase library")
                        .transition(.scale.combined(with: .opacity))
                    }
                } else if !speechRecognizer.isRecording {
                    Button(action: toggleDictation) {
                        SottoIconView(.mic, size: 17, tint: palette.textSecondary)
                            .frame(width: 36, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Start recording speech")
                    .accessibilityHint("Dictates spoken words into the Quick-Speak bar")
                }
            }
            .padding(.horizontal, 6)
            .frame(minHeight: 52)
            .background(palette.surfaceVariant)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(speechRecognizer.isRecording ? SottoTheme.destructiveRed : palette.outlineVariant.opacity(0.35), lineWidth: 1)
            )
            
            // Filled Speak CTA Button
            Button(action: {
                if isNotEmpty {
                    if speechRecognizer.isRecording { speechRecognizer.stopRecording() }
                    onSpeak(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }) {
                SottoIconView(
                    .volumeUp,
                    size: 20,
                    tint: isNotEmpty ? palette.background : palette.textSecondary.opacity(0.38)
                )
                .frame(width: 52, height: 52)
                .background(isNotEmpty ? palette.accent : palette.surfaceVariant)
                .clipShape(Circle())
                .contentShape(Circle())
            }
            .disabled(!isNotEmpty)
            .accessibilityLabel("Speak aloud")
            .accessibilityHint("Speaks the entered text using text to speech")
            .demoTarget("quickSpeak_speakButton")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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
