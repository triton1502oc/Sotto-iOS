import SwiftUI
import Speech
import AVFoundation

public struct TwoWayConversationModal: View {
    public let allPhrases: [Phrase]
    public let onSpeakResponse: (String) -> Void
    public let onDismiss: () -> Void
    
    @State private var displayedText: String = ""
    @State private var isFlipped: Bool = false
    @State private var lastReply: String? = nil
    @State private var showQuestionsSheet: Bool = false
    @State private var showKeyboardInput: Bool = false
    @State private var manualInputText: String = ""
    @State private var selectedPromptCategory: PhraseCategory = .care
    
    @StateObject private var speechRecognizer = SpeechRecognizerService()
    
    private var activeText: String {
        displayedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? speechRecognizer.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
            : displayedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public init(
        allPhrases: [Phrase],
        onSpeakResponse: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.allPhrases = allPhrases
        self.onSpeakResponse = onSpeakResponse
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            SottoTheme.background
                .ignoresSafeArea()
            
            if isFlipped {
                flippedView
            } else {
                normalView
            }
        }
        .sheet(isPresented: $showQuestionsSheet) {
            questionsPickerSheet
        }
        .onChange(of: speechRecognizer.transcribedText) { newText in
            if !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                displayedText = newText
            }
        }
    }
    
    // MARK: - Normal Mode
    
    private var normalView: some View {
        VStack(spacing: 12) {
            // Top Action Bar (Caregiver Tools)
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isFlipped = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("🔄")
                        Text("Flip")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(SottoTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(SottoTheme.surface)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                
                Button(action: { showQuestionsSheet = true }) {
                    HStack(spacing: 4) {
                        Text("📋")
                        Text("Questions")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(SottoTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(SottoTheme.surface)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                
                Spacer()
                
                if !activeText.isEmpty {
                    Button(action: {
                        displayedText = ""
                        speechRecognizer.stopRecording()
                    }) {
                        Text("🗑️")
                            .font(.system(size: 18))
                            .frame(width: 36, height: 36)
                    }
                }
                
                Button(action: {
                    speechRecognizer.stopRecording()
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Middle: Receptive Display Card
            receptiveDisplayCard
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
            
            // Bottom: User Rapid-Response Dock
            userResponseDock
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }
    
    // MARK: - Flipped Mode (180° Face-to-Face Partner View)
    
    private var flippedView: some View {
        VStack(spacing: 8) {
            // Patient area inverted 180° so the person across the table sees it right-side-up
            VStack(spacing: 10) {
                receptiveDisplayCard
                    .frame(maxHeight: .infinity)
                
                userResponseDock
            }
            .padding(.horizontal, 16)
            .rotationEffect(.degrees(180))
            
            // Bottom Caregiver Controls facing the caregiver holding the device
            VStack(spacing: 6) {
                if showKeyboardInput {
                    manualKeyboardRow
                        .padding(.horizontal, 16)
                }
                
                HStack(spacing: 6) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isFlipped = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("🔄")
                            Text("Flip")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(SottoTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(20)
                    }
                    
                    Button(action: { showQuestionsSheet = true }) {
                        HStack(spacing: 4) {
                            Text("📋")
                            Text("Questions")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(SottoTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(SottoTheme.surface)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    
                    // Mic button
                    Button(action: toggleListening) {
                        Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 15))
                            .foregroundColor(speechRecognizer.isRecording ? .white : SottoTheme.onPrimary)
                            .frame(width: 36, height: 36)
                            .background(speechRecognizer.isRecording ? SottoTheme.danger : SottoTheme.primary)
                            .clipShape(Circle())
                    }
                    
                    // Read aloud button
                    if !activeText.isEmpty {
                        Button(action: { onSpeakResponse(activeText) }) {
                            Text("🔊")
                                .font(.system(size: 17))
                                .frame(width: 36, height: 36)
                        }
                    }
                    
                    // Keyboard toggle
                    Button(action: {
                        withAnimation { showKeyboardInput.toggle() }
                    }) {
                        Text("⌨️")
                            .font(.system(size: 17))
                            .frame(width: 36, height: 36)
                    }
                    
                    // Close button
                    Button(action: {
                        speechRecognizer.stopRecording()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(SottoTheme.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
    }
    
    // MARK: - Receptive Display Card
    
    private var receptiveDisplayCard: some View {
        VStack(spacing: 0) {
            // Status Badge (Replied / Listening)
            statusBadge
                .padding(.top, 14)
            
            Spacer()
            
            // Giant Prompt Text
            giantPromptText
                .padding(.horizontal, 16)
            
            Spacer()
            
            // Caregiver Controls (Normal mode inline)
            if !isFlipped {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        // Mic Button
                        Button(action: toggleListening) {
                            HStack(spacing: 6) {
                                Text(speechRecognizer.isRecording ? "⏹" : "🎤")
                                Text(speechRecognizer.isRecording ? "Tap to stop" : "Listen & Read")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(speechRecognizer.isRecording ? .white : SottoTheme.onPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(speechRecognizer.isRecording ? SottoTheme.danger : SottoTheme.primary)
                            .cornerRadius(24)
                        }
                        
                        // Read Aloud Button
                        if !activeText.isEmpty {
                            Button(action: { onSpeakResponse(activeText) }) {
                                HStack(spacing: 4) {
                                    Text("🔊")
                                    Text("Read Aloud")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(SottoTheme.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(SottoTheme.surface)
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(SottoTheme.primary.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Keyboard toggle button
                        Button(action: {
                            withAnimation { showKeyboardInput.toggle() }
                        }) {
                            Text("⌨️")
                                .font(.system(size: 18))
                                .frame(width: 40, height: 40)
                                .background(SottoTheme.surfaceVariant)
                                .clipShape(Circle())
                        }
                    }
                    
                    if showKeyboardInput {
                        manualKeyboardRow
                    }
                }
                .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity)
        .background(SottoTheme.surface)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        HStack {
            if let reply = lastReply {
                Text("Replied: \(reply)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 46/255, green: 125/255, blue: 50/255))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
            } else if speechRecognizer.isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 9, height: 9)
                    Text("Listening…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(SottoTheme.textSecondary)
                }
            } else {
                Text(" ")
                    .font(.system(size: 13))
            }
        }
        .frame(height: 28)
    }
    
    // MARK: - Giant Prompt Text
    
    private var giantPromptText: some View {
        Group {
            if !activeText.isEmpty {
                let len = activeText.count
                let fontSize: CGFloat = {
                    if len < 30 { return 32 }
                    if len < 70 { return 26 }
                    if len < 140 { return 20 }
                    return 17
                }()
                
                Text(activeText)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(SottoTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .minimumScaleFactor(0.7)
            } else if speechRecognizer.isRecording {
                Text("Listening…")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(SottoTheme.primary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Tap mic to speak to user…")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(SottoTheme.textSecondary.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Manual Keyboard Input Row
    
    private var manualKeyboardRow: some View {
        HStack(spacing: 8) {
            TextField("Type a question…", text: $manualInputText)
                .font(.system(size: 14))
                .foregroundColor(SottoTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(SottoTheme.background)
                .cornerRadius(10)
                .submitLabel(.done)
                .onSubmit { submitManualInput() }
            
            Button(action: submitManualInput) {
                Text("✓")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(SottoTheme.onPrimary)
                    .frame(width: 36, height: 36)
                    .background(SottoTheme.primary)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 12)
    }
    
    private func submitManualInput() {
        let trimmed = manualInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            displayedText = trimmed
            manualInputText = ""
            showKeyboardInput = false
        }
    }
    
    // MARK: - User 4-Button Rapid-Response Dock
    
    private var userResponseDock: some View {
        VStack(spacing: 8) {
            // Row 1: YES & NO (Primary large touch targets)
            HStack(spacing: 10) {
                Button(action: {
                    handleResponse(displayText: "Yes", ttsText: "Yes")
                }) {
                    Text("✓ Yes")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 232/255, green: 245/255, blue: 233/255))
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color(red: 27/255, green: 94/255, blue: 32/255))
                        .cornerRadius(16)
                }
                
                Button(action: {
                    handleResponse(displayText: "No", ttsText: "No")
                }) {
                    Text("✕ No")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 255/255, green: 235/255, blue: 238/255))
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color(red: 127/255, green: 29/255, blue: 29/255))
                        .cornerRadius(16)
                }
            }
            
            // Row 2: REPEAT & WAIT
            HStack(spacing: 10) {
                Button(action: {
                    handleResponse(displayText: "Repeat", ttsText: "Please repeat that.")
                }) {
                    Text("🔁 Repeat")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(16)
                }
                
                Button(action: {
                    handleResponse(displayText: "Wait", ttsText: "Please give me a moment.")
                }) {
                    Text("⏳ Wait")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Questions Picker Sheet
    
    private var questionsPickerSheet: some View {
        NavigationView {
            ZStack {
                SottoTheme.background
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Category Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PhraseCategory.filterCategories, id: \.self) { category in
                                let isSelected = selectedPromptCategory == category
                                Button(action: { selectedPromptCategory = category }) {
                                    Text(category.displayName)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                                        .foregroundColor(isSelected ? SottoTheme.onPrimary : SottoTheme.textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? SottoTheme.primary : SottoTheme.surfaceVariant)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                    
                    let availablePhrases: [Phrase] = {
                        switch selectedPromptCategory {
                        case .all:
                            return allPhrases
                        case .emergency:
                            return allPhrases.filter { $0.isEmergency }
                        default:
                            return allPhrases.filter { !$0.isEmergency && $0.category == selectedPromptCategory }
                        }
                    }()
                    
                    if availablePhrases.isEmpty {
                        VStack {
                            Spacer()
                            Text("No phrases in this category")
                                .foregroundColor(SottoTheme.textSecondary)
                                .font(.system(size: 14))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        List {
                            ForEach(availablePhrases) { phrase in
                                Button(action: {
                                    displayedText = phrase.text
                                    showQuestionsSheet = false
                                }) {
                                    Text(phrase.text)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(SottoTheme.textPrimary)
                                        .padding(.vertical, 4)
                                }
                                .listRowBackground(SottoTheme.surface)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showQuestionsSheet = false }
                        .foregroundColor(SottoTheme.primary)
                }
            }
        }
    }
    
    // MARK: - Actions & Feedback
    
    private func handleResponse(displayText: String, ttsText: String) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation {
            lastReply = displayText
        }
        onSpeakResponse(ttsText)
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                withAnimation {
                    if lastReply == displayText {
                        lastReply = nil
                    }
                }
            }
        }
    }
    
    private func toggleListening() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            speechRecognizer.requestPermissions { granted in
                if granted {
                    displayedText = ""
                    speechRecognizer.startRecording { text in
                        displayedText = text
                    }
                }
            }
        }
    }
}
