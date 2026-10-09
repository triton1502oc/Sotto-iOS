import SwiftUI
import Speech
import AVFoundation

public enum CaregiverTab {
    case whyFinder
    case freeform
}

private struct WhyQuestionOption: Identifiable {
    let id = UUID()
    let text: String
    let isAreaHeader: Bool
    let areaIndex: Int
    let questionIndex: Int
}

public struct TwoWayConversationModal: View {
    public let allPhrases: [Phrase]
    public let categories: [String]
    public let whyFinderRepository: WhyFinderRepositoryProtocol
    public let onSpeakResponse: (String) -> Void
    public let onDismiss: () -> Void
    
    @State private var activeTab: CaregiverTab = .freeform
    @State private var displayedText: String = ""
    @State private var isFlipped: Bool = false
    @State private var lastReply: String? = nil
    @State private var showQuestionsSheet: Bool = false
    @State private var showKeyboardInput: Bool = false
    @State private var manualInputText: String = ""
    @State private var whySessionSaved: Bool = false
    
    // Why Finder session state
    @StateObject private var whySession: WhyFinderSession
    @StateObject private var speechRecognizer = SpeechRecognizerService()
    
    public init(
        allPhrases: [Phrase],
        categories: [String] = [],
        whyFinderRepository: WhyFinderRepositoryProtocol = UserDefaultsWhyFinderRepository.shared,
        onSpeakResponse: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.allPhrases = allPhrases
        self.categories = categories
        self.whyFinderRepository = whyFinderRepository
        self.onSpeakResponse = onSpeakResponse
        self.onDismiss = onDismiss
        
        let tree = whyFinderRepository.getTree()
        _whySession = StateObject(wrappedValue: WhyFinderSession(tree: tree))
    }
    
    private var activeFreeformText: String {
        displayedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? speechRecognizer.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
            : displayedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var whyPromptText: String {
        switch whySession.currentState {
        case .askingArea(_, let area):
            return area.question
        case .askingQuestion(_, _, let q):
            return q.text
        case .selectingBodyPart:
            return "Where does it hurt or feel uncomfortable?"
        case .selectingIntensity:
            return "How intense is it? (1 = mild, 5 = severe)"
        case .confirmingCause(_, _, let cause, let part, let intensity):
            var details = ""
            if let p = part, !p.isEmpty {
                let partLabel = LocaleHelper.getBodyRegionLabel(p)
                let intensityStr = intensity != nil ? " (\(intensity!)/5)" : ""
                details = " (\(partLabel)\(intensityStr))"
            }
            return "Did we figure it out?\n\n\(cause)\(details)"
        case .finished(let outcome, _, let cause, let part, let intensity, _, _, _):
            switch outcome {
            case .found:
                var details = ""
                if let p = part, !p.isEmpty {
                    let partLabel = LocaleHelper.getBodyRegionLabel(p)
                    let intensityStr = intensity != nil ? " (\(intensity!)/5)" : ""
                    details = " (\(partLabel)\(intensityStr))"
                }
                return "Cause Found\n\n\(cause ?? "")\(details)"
            case .notFound:
                return "Could Not Pinpoint Cause"
            case .stopped:
                return "Stopped for Now"
            }
        }
    }
    
    public var body: some View {
        ZStack {
            SottoTheme.background
                .ignoresSafeArea()
            
            if isFlipped {
                flippedLayout
            } else {
                normalLayout
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
        .onChange(of: whySession.currentState) { state in
            if case .finished = state {
                finishAndSaveWhySession()
            }
        }
    }
    
    // MARK: - Normal Side-by-Side Layout
    
    private var normalLayout: some View {
        VStack(spacing: 10) {
            // Receptive display card
            CaregiverDisplayCard(
                activeTab: activeTab,
                whyState: whySession.currentState,
                whyPromptText: whyPromptText,
                activeFreeformText: activeFreeformText,
                lastReply: lastReply,
                isListening: speechRecognizer.isRecording,
                onRestartWhyTree: {
                    whySession.restart()
                    whySessionSaved = false
                },
                onFinish: {
                    speechRecognizer.stopRecording()
                    onDismiss()
                },
                onReadAloudPrompt: {
                    let text = activeTab == .whyFinder ? whyPromptText : activeFreeformText
                    if !text.isEmpty { onSpeakResponse(text) }
                }
            )
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            
            // Response Dock (4 Cards or Body Grid or Intensity Row)
            CaregiverResponseDock(
                activeTab: activeTab,
                whyState: whySession.currentState,
                onYes: {
                    handleUserResponse(displayText: "Yes", ttsText: "Yes")
                    if activeTab == .whyFinder { whySession.answerYes() }
                },
                onNo: {
                    handleUserResponse(displayText: "No", ttsText: "No")
                    if activeTab == .whyFinder { whySession.answerNo() }
                },
                onNotSure: {
                    handleUserResponse(displayText: "Not Sure", ttsText: "Not Sure")
                    if activeTab == .whyFinder { whySession.answerNotSure() }
                },
                onStop: {
                    handleUserResponse(displayText: "Stop", ttsText: "Stop")
                    if activeTab == .whyFinder { whySession.stop() }
                },
                onSelectBodyPart: { partKey in
                    let label = LocaleHelper.getBodyRegionLabel(partKey)
                    handleUserResponse(displayText: label, ttsText: label)
                    whySession.selectBodyPart(partKey)
                },
                onSelectIntensity: { level in
                    handleUserResponse(displayText: "\(level)", ttsText: "\(level)")
                    whySession.selectIntensity(level)
                }
            )
            .padding(.horizontal, 16)
            
            // Keyboard Input Row (if toggled)
            if showKeyboardInput && activeTab == .freeform {
                manualKeyboardRow
                    .padding(.horizontal, 16)
            }
            
            // Bottom Action Menu
            CaregiverBottomMenu(
                activeTab: $activeTab,
                isFlipped: $isFlipped,
                isListening: speechRecognizer.isRecording,
                canStepBack: whySession.canStepBack(),
                canSpeakPrompt: (activeTab == .whyFinder ? !whyPromptText.isEmpty : !activeFreeformText.isEmpty),
                onToggleListening: {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                    } else {
                        displayedText = ""
                        speechRecognizer.startRecording()
                    }
                },
                onSpeakPrompt: {
                    let text = activeTab == .whyFinder ? whyPromptText : activeFreeformText
                    if !text.isEmpty { onSpeakResponse(text) }
                },
                onPickCard: { showQuestionsSheet = true },
                onStepBack: { whySession.stepBack() },
                onToggleKeyboard: { showKeyboardInput.toggle() },
                onDismiss: {
                    speechRecognizer.stopRecording()
                    onDismiss()
                }
            )
        }
        .padding(.top, 8)
    }
    
    // MARK: - Flipped Partner View (180° rotation)
    
    private var flippedLayout: some View {
        VStack(spacing: 8) {
            // Patient display and responses rotated 180° facing partner across the table
            VStack(spacing: 10) {
                CaregiverDisplayCard(
                    activeTab: activeTab,
                    whyState: whySession.currentState,
                    whyPromptText: whyPromptText,
                    activeFreeformText: activeFreeformText,
                    lastReply: lastReply,
                    isListening: speechRecognizer.isRecording,
                    onRestartWhyTree: {
                        whySession.restart()
                        whySessionSaved = false
                    },
                    onFinish: {
                        speechRecognizer.stopRecording()
                        onDismiss()
                    },
                    onReadAloudPrompt: {
                        let text = activeTab == .whyFinder ? whyPromptText : activeFreeformText
                        if !text.isEmpty { onSpeakResponse(text) }
                    }
                )
                .frame(maxHeight: .infinity)
                
                CaregiverResponseDock(
                    activeTab: activeTab,
                    whyState: whySession.currentState,
                    onYes: {
                        handleUserResponse(displayText: "Yes", ttsText: "Yes")
                        if activeTab == .whyFinder { whySession.answerYes() }
                    },
                    onNo: {
                        handleUserResponse(displayText: "No", ttsText: "No")
                        if activeTab == .whyFinder { whySession.answerNo() }
                    },
                    onNotSure: {
                        handleUserResponse(displayText: "Not Sure", ttsText: "Not Sure")
                        if activeTab == .whyFinder { whySession.answerNotSure() }
                    },
                    onStop: {
                        handleUserResponse(displayText: "Stop", ttsText: "Stop")
                        if activeTab == .whyFinder { whySession.stop() }
                    },
                    onSelectBodyPart: { partKey in
                        let label = LocaleHelper.getBodyRegionLabel(partKey)
                        handleUserResponse(displayText: label, ttsText: label)
                        whySession.selectBodyPart(partKey)
                    },
                    onSelectIntensity: { level in
                        handleUserResponse(displayText: "\(level)", ttsText: "\(level)")
                        whySession.selectIntensity(level)
                    }
                )
            }
            .padding(.horizontal, 16)
            .rotationEffect(.degrees(180))
            
            // Caregiver controls facing the caregiver at the bottom
            if showKeyboardInput && activeTab == .freeform {
                manualKeyboardRow
                    .padding(.horizontal, 16)
            }
            
            CaregiverBottomMenu(
                activeTab: $activeTab,
                isFlipped: $isFlipped,
                isListening: speechRecognizer.isRecording,
                canStepBack: whySession.canStepBack(),
                canSpeakPrompt: (activeTab == .whyFinder ? !whyPromptText.isEmpty : !activeFreeformText.isEmpty),
                onToggleListening: {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                    } else {
                        displayedText = ""
                        speechRecognizer.startRecording()
                    }
                },
                onSpeakPrompt: {
                    let text = activeTab == .whyFinder ? whyPromptText : activeFreeformText
                    if !text.isEmpty { onSpeakResponse(text) }
                },
                onPickCard: { showQuestionsSheet = true },
                onStepBack: { whySession.stepBack() },
                onToggleKeyboard: { showKeyboardInput.toggle() },
                onDismiss: {
                    speechRecognizer.stopRecording()
                    onDismiss()
                }
            )
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    private func handleUserResponse(displayText: String, ttsText: String) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        lastReply = displayText
        onSpeakResponse(ttsText)
        
        // Auto-clear reply indicator after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if lastReply == displayText {
                lastReply = nil
            }
        }
    }
    
    private func finishAndSaveWhySession() {
        guard !whySessionSaved else { return }
        if let entry = whySession.toLogEntry(privateNote: nil) {
            whyFinderRepository.addLog(entry)
            whySessionSaved = true
            UsabilityTracker.shared.recordWhyFinder(
                outcome: entry.outcome.rawValue,
                areaId: entry.areaId,
                depth: entry.steps.count,
                notSureCount: entry.steps.filter { $0.answer == "not_sure" }.count,
                bodyPart: entry.bodyPart,
                intensity: entry.intensity,
                durationMs: entry.endedAt - entry.startedAt
            )
        }
    }
    
    private var manualKeyboardRow: some View {
        HStack {
            TextField("Type a phrase or prompt...", text: $manualInputText)
                .font(.system(size: 15))
                .foregroundColor(SottoTheme.textPrimary)
                .padding(10)
                .background(SottoTheme.surface)
                .cornerRadius(10)
            
            Button("Done") {
                if !manualInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    displayedText = manualInputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    manualInputText = ""
                    showKeyboardInput = false
                }
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(SottoTheme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(SottoTheme.surfaceVariant)
            .cornerRadius(10)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Card Picker Sheet
    
    private var questionsPickerSheet: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    if activeTab == .whyFinder {
                        // Why Tree Questions
                        let tree = whyFinderRepository.getTree()
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(tree.areas.enumerated()), id: \.element.id) { aIdx, area in
                                    Button(action: {
                                        whySession.jumpToArea(areaIndex: aIdx)
                                        showQuestionsSheet = false
                                    }) {
                                        HStack {
                                            Text("🏷️ \(area.question)")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(SottoTheme.primary)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(SottoTheme.primary.opacity(0.15))
                                        .cornerRadius(10)
                                    }
                                    
                                    ForEach(Array(area.questions.enumerated()), id: \.element.id) { qIdx, question in
                                        Button(action: {
                                            whySession.jumpToQuestion(areaIndex: aIdx, questionIndex: qIdx)
                                            showQuestionsSheet = false
                                        }) {
                                            HStack {
                                                Text(question.text)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(SottoTheme.textPrimary)
                                                Spacer()
                                            }
                                            .padding(12)
                                            .background(SottoTheme.surfaceVariant.opacity(0.5))
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                        }
                    } else {
                        // Phrases Cards
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(allPhrases) { phrase in
                                    Button(action: {
                                        displayedText = phrase.text
                                        showQuestionsSheet = false
                                    }) {
                                        HStack {
                                            Text(phrase.text)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(SottoTheme.textPrimary)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(SottoTheme.surfaceVariant.opacity(0.5))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle(activeTab == .whyFinder ? "Tree Questions" : "Choose Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showQuestionsSheet = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Receptive Display Card

private struct CaregiverDisplayCard: View {
    let activeTab: CaregiverTab
    let whyState: WhyFinderState
    let whyPromptText: String
    let activeFreeformText: String
    let lastReply: String?
    let isListening: Bool
    let onRestartWhyTree: () -> Void
    let onFinish: () -> Void
    let onReadAloudPrompt: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Status reply / listening badge
            HStack {
                if let reply = lastReply {
                    Text("✓ Replied: \(reply)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(SottoTheme.successGreen)
                        .cornerRadius(12)
                } else if isListening {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(SottoTheme.recordingPulseRed)
                            .frame(width: 8, height: 8)
                        Text("Listening...")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(SottoTheme.recordingPulseRed)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(SottoTheme.recordingPulseRed.opacity(0.15))
                    .cornerRadius(12)
                }
            }
            .frame(height: 24)
            
            Spacer()
            
            if activeTab == .whyFinder, case .finished(let outcome, _, let cause, let part, let intensity, _, _, _) = whyState {
                // Finished State
                VStack(spacing: 14) {
                    Text(outcome == .found ? "🎯 Cause Found" : (outcome == .stopped ? "⏸ Stopped" : "🔍 Unresolved"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(SottoTheme.textPrimary)
                    
                    if outcome == .found, let c = cause, !c.isEmpty {
                        VStack(spacing: 4) {
                            Text(c)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(SottoTheme.primary)
                            
                            if let p = part, !p.isEmpty {
                                let partLabel = LocaleHelper.getBodyRegionLabel(p)
                                let intensityStr = intensity != nil ? " • \(intensity!)/5" : ""
                                Text("\(partLabel)\(intensityStr)")
                                    .font(.system(size: 15))
                                    .foregroundColor(SottoTheme.textSecondary)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(SottoTheme.primary.opacity(0.15))
                        .cornerRadius(12)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: onRestartWhyTree) {
                            Text("🔄 Restart")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(SottoTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(SottoTheme.surfaceVariant)
                                .cornerRadius(10)
                        }
                        
                        Button(action: onFinish) {
                            Text("Done")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(SottoTheme.confirm)
                                .cornerRadius(10)
                        }
                    }
                }
            } else {
                // Active Prompt (Tap to read aloud)
                let prompt = activeTab == .whyFinder ? whyPromptText : activeFreeformText
                Button(action: onReadAloudPrompt) {
                    Text(prompt.isEmpty ? "Tap Mic or Type to begin..." : prompt)
                        .font(.system(size: prompt.count < 40 ? 30 : 22, weight: .bold))
                        .foregroundColor(prompt.isEmpty ? SottoTheme.textSecondary.opacity(0.5) : SottoTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SottoTheme.surface)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Caregiver Response Dock

private struct CaregiverResponseDock: View {
    let activeTab: CaregiverTab
    let whyState: WhyFinderState
    let onYes: () -> Void
    let onNo: () -> Void
    let onNotSure: () -> Void
    let onStop: () -> Void
    let onSelectBodyPart: (String) -> Void
    let onSelectIntensity: (Int) -> Void
    
    var body: some View {
        if activeTab == .whyFinder {
            switch whyState {
            case .selectingBodyPart:
                bodyPartGrid
            case .selectingIntensity:
                intensityScaleRow
            case .finished:
                EmptyView()
            default:
                fourCardDock
            }
        } else {
            fourCardDock
        }
    }
    
    // Four Card Dock
    private var fourCardDock: some View {
        VStack(spacing: 8) {
            // Row 1: YES & NO
            HStack(spacing: 10) {
                Button(action: onYes) {
                    Text("✓ Yes")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(SottoTheme.successText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(SottoTheme.successContainer)
                        .cornerRadius(16)
                }
                
                Button(action: onNo) {
                    Text("✕ No")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(SottoTheme.crisisStopText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(SottoTheme.crisisStopContainer)
                        .cornerRadius(16)
                }
            }
            
            // Row 2: NOT SURE & STOP
            HStack(spacing: 10) {
                Button(action: onNotSure) {
                    Text("? Not Sure")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(SottoTheme.warningHighText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SottoTheme.warningHighContainer)
                        .cornerRadius(16)
                }
                
                Button(action: onStop) {
                    Text("⏹ Stop")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(SottoTheme.neutralStoppedText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SottoTheme.neutralStoppedContainer)
                        .cornerRadius(16)
                }
            }
        }
    }
    
    // Body Part Selection Grid
    private var bodyPartGrid: some View {
        VStack(spacing: 8) {
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(BodyRegions.all, id: \.self) { region in
                    Button(action: { onSelectBodyPart(region) }) {
                        Text(LocaleHelper.getBodyRegionLabel(region))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(SottoTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(SottoTheme.surfaceVariant)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
            }
            
            HStack(spacing: 10) {
                Button(action: onNotSure) {
                    Text("? Not Sure")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(12)
                }
                
                Button(action: onStop) {
                    Text("⏹ Stop")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // Intensity Scale Row (1 to 5)
    private var intensityScaleRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                let colors = [
                    SottoTheme.intensityMild,
                    SottoTheme.intensityLight,
                    SottoTheme.intensityModerate,
                    SottoTheme.intensityHigh,
                    SottoTheme.intensitySevere
                ]
                ForEach(1...5, id: \.self) { level in
                    Button(action: { onSelectIntensity(level) }) {
                        Text("\(level)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(colors[level - 1])
                            .cornerRadius(14)
                    }
                }
            }
            
            HStack(spacing: 10) {
                Button(action: onNotSure) {
                    Text("? Not Sure")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(12)
                }
                
                Button(action: onStop) {
                    Text("⏹ Stop")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Caregiver Bottom Menu

private struct CaregiverBottomMenu: View {
    @Binding var activeTab: CaregiverTab
    @Binding var isFlipped: Bool
    let isListening: Bool
    let canStepBack: Bool
    let canSpeakPrompt: Bool
    let onToggleListening: () -> Void
    let onSpeakPrompt: () -> Void
    let onPickCard: () -> Void
    let onStepBack: () -> Void
    let onToggleKeyboard: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Line 1: Mode Switcher Tabs + Global Controls (Flip & Dismiss)
            HStack {
                HStack(spacing: 8) {
                    Button(action: { activeTab = .freeform }) {
                        Text("💬 Talk")
                            .font(.system(size: 13, weight: activeTab == .freeform ? .bold : .medium))
                            .foregroundColor(activeTab == .freeform ? SottoTheme.onPrimary : SottoTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(activeTab == .freeform ? SottoTheme.primary : SottoTheme.surface)
                            .cornerRadius(16)
                    }
                    
                    Button(action: { activeTab = .whyFinder }) {
                        Text("🧭 Guided")
                            .font(.system(size: 13, weight: activeTab == .whyFinder ? .bold : .medium))
                            .foregroundColor(activeTab == .whyFinder ? SottoTheme.onPrimary : SottoTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(activeTab == .whyFinder ? SottoTheme.primary : SottoTheme.surface)
                            .cornerRadius(16)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Button(action: { withAnimation(.easeInOut(duration: 0.25)) { isFlipped.toggle() } }) {
                        HStack(spacing: 4) {
                            Text("🔄")
                            Text(isFlipped ? "Flip Back" : "Flip")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(SottoTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(SottoTheme.surface)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(SottoTheme.textSecondary)
                            .frame(width: 34, height: 34)
                    }
                }
            }
            
            // Line 2: Mode Actions
            HStack(spacing: 8) {
                if activeTab == .whyFinder {
                    Button(action: onSpeakPrompt) {
                        HStack(spacing: 4) {
                            Text("🔊")
                            Text("Speak")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(10)
                    }
                    .disabled(!canSpeakPrompt)
                    
                    Button(action: onPickCard) {
                        HStack(spacing: 4) {
                            Text("📋")
                            Text("Questions")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(10)
                    }
                    
                    if canStepBack {
                        Button(action: onStepBack) {
                            HStack(spacing: 4) {
                                Text("↩️")
                                Text("Back")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(SottoTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(SottoTheme.surfaceVariant)
                            .cornerRadius(10)
                        }
                    }
                } else {
                    Button(action: onSpeakPrompt) {
                        HStack(spacing: 4) {
                            Text("🔊")
                            Text("Speak")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(10)
                    }
                    .disabled(!canSpeakPrompt)
                    
                    Button(action: onPickCard) {
                        HStack(spacing: 4) {
                            Text("📋")
                            Text("Cards")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(10)
                    }
                    
                    Button(action: onToggleListening) {
                        HStack(spacing: 4) {
                            Text(isListening ? "⏹" : "🎤")
                            Text(isListening ? "Stop" : "Mic")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isListening ? .white : SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(isListening ? SottoTheme.recordingPulseRed : SottoTheme.surfaceVariant)
                        .cornerRadius(10)
                    }
                    
                    Button(action: onToggleKeyboard) {
                        HStack(spacing: 4) {
                            Text("⌨️")
                            Text("Type")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(SottoTheme.surface.opacity(0.85))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}
