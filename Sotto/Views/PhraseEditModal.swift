import SwiftUI

public struct PhraseEditModal: View {
    public let existingPhrase: Phrase?
    public let onSave: (Phrase) -> Void
    public let onDelete: ((Phrase) -> Void)?
    public let onCancel: () -> Void
    
    @State private var text: String
    @State private var selectedCategory: PhraseCategory
    @StateObject private var speechRecognizer = SpeechRecognizerService()
    
    public init(
        existingPhrase: Phrase? = nil,
        onSave: @escaping (Phrase) -> Void,
        onDelete: ((Phrase) -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.existingPhrase = existingPhrase
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        
        _text = State(initialValue: existingPhrase?.text ?? "")
        _selectedCategory = State(initialValue: existingPhrase?.isEmergency == true ? .emergency : (existingPhrase?.category ?? .general))
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Text input with microphone dictation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phrase text")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SottoTheme.textSecondary)
                            
                            HStack(alignment: .top, spacing: 8) {
                                TextEditor(text: $text)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                                    .background(SottoTheme.background)
                                    .foregroundColor(SottoTheme.textPrimary)
                                    .font(.system(size: 16))
                                    .cornerRadius(8)
                                    .padding(4)
                                
                                Button(action: toggleDictation) {
                                    Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                                        .font(.system(size: 20))
                                        .foregroundColor(speechRecognizer.isRecording ? SottoTheme.danger : SottoTheme.textPrimary)
                                        .padding(8)
                                }
                            }
                            .background(SottoTheme.background)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(speechRecognizer.isRecording ? SottoTheme.danger : Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        
                        // Category selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Category")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SottoTheme.textSecondary)
                            
                            HStack(spacing: 8) {
                                ForEach(PhraseCategory.selectableCategories) { category in
                                    let isSelected = selectedCategory == category
                                    let isEmergency = category == .emergency
                                    
                                    Button(action: { selectedCategory = category }) {
                                        HStack(spacing: 4) {
                                            if isEmergency {
                                                Text("🚨")
                                                    .font(.system(size: 12))
                                            }
                                            Text(category.displayName)
                                                .font(.system(size: 13, weight: isSelected ? .bold : .normal))
                                        }
                                        .foregroundColor(
                                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedText :
                                            (isSelected ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                                        )
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedBg :
                                            (isSelected ? SottoTheme.surfaceVariant : SottoTheme.background)
                                        )
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isEmergency && isSelected ? SottoTheme.emergencyBorder : Color.clear, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle(existingPhrase != nil ? "Edit Phrase" : "Add Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(SottoTheme.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    HStack(spacing: 16) {
                        if let existing = existingPhrase, let onDelete = onDelete {
                            Button(action: { onDelete(existing) }) {
                                Text("Delete")
                                    .foregroundColor(SottoTheme.danger)
                            }
                        }
                        
                        Button(action: savePhrase) {
                            Text("Save")
                                .bold()
                                .foregroundColor(SottoTheme.confirm)
                        }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
    
    private func savePhrase() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let isEmergency = selectedCategory == .emergency
        let newPhrase = Phrase(
            id: existingPhrase?.id ?? UUID(),
            text: trimmed,
            language: existingPhrase?.language ?? LocaleHelper.langAuto,
            isEmergency: isEmergency,
            category: selectedCategory
        )
        onSave(newPhrase)
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
