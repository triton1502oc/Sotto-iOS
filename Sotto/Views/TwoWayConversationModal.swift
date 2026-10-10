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
    public let appLanguage: String
    public let onSpeakResponse: (String) -> Void
    public let onDismiss: () -> Void
    
    @State private var activeTab: CaregiverTab = .freeform
    @State private var displayedText: String = ""
    @State private var isFlipped: Bool = false
    @State private var lastReply: String? = nil
    @State private var showQuestionsSheet: Bool = false
    @State private var selectedPromptCategory: String = "ALL"
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
        appLanguage: String = "system",
        onSpeakResponse: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.allPhrases = allPhrases
        self.categories = categories
        self.whyFinderRepository = whyFinderRepository
        self.appLanguage = appLanguage
        self.onSpeakResponse = onSpeakResponse
        self.onDismiss = onDismiss
        
        let tree = whyFinderRepository.getTree()
        _whySession = StateObject(wrappedValue: WhyFinderSession(tree: tree))
        
        let args = ProcessInfo.processInfo.arguments
        let isId = LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage) == LocaleHelper.langIndonesian
        if args.contains("--whyfinder") || args.contains("--screenshot-whyfinder") {
            _activeTab = State(initialValue: .whyFinder)
        }
        if args.contains("--partner-flip") {
            _isFlipped = State(initialValue: true)
        }
        if (args.contains("--triage") || args.contains("--screenshot-triage")) && !args.contains("--whyfinder") {
            _displayedText = State(initialValue: isId ? "Apakah kamu butuh tempat tenang sekarang?" : "Do you need a quiet space right now?")
        }
    }
    
    private var isIndonesian: Bool {
        LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage) == LocaleHelper.langIndonesian
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
            return isIndonesian ? "Di bagian mana yang terasa sakit atau tidak nyaman?" : "Where does it hurt or feel uncomfortable?"
        case .selectingIntensity:
            return isIndonesian ? "Seberapa parah intensitasnya? (1 = ringan, 5 = sangat parah)" : "How intense is it? (1 = mild, 5 = severe)"
        case .confirmingCause(_, _, let cause, let part, let intensity):
            var details = ""
            if let p = part, !p.isEmpty {
                let partLabel = LocaleHelper.getBodyRegionLabel(p, appLanguage: appLanguage)
                let intensityStr = intensity != nil ? " (\(intensity!)/5)" : ""
                details = " (\(partLabel)\(intensityStr))"
            }
            let title = isIndonesian ? "Apakah ini penyebabnya?" : "Did we figure it out?"
            return "\(title)\n\n\(cause)\(details)"
        case .finished(let outcome, _, let cause, let part, let intensity, _, _, _):
            switch outcome {
            case .found:
                var details = ""
                if let p = part, !p.isEmpty {
                    let partLabel = LocaleHelper.getBodyRegionLabel(p, appLanguage: appLanguage)
                    let intensityStr = intensity != nil ? " (\(intensity!)/5)" : ""
                    details = " (\(partLabel)\(intensityStr))"
                }
                let title = isIndonesian ? "Penyebab Ditemukan" : "Cause Found"
                return "\(title)\n\n\(cause ?? "")\(details)"
            case .notFound:
                return isIndonesian ? "Penyebab Belum Ditemukan" : "Could Not Pinpoint Cause"
            case .stopped:
                return isIndonesian ? "Dihentikan Sementara" : "Stopped for Now"
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
        .onChange(of: isFlipped) { flipped in
            if flipped {
                AppDelegate.orientationLock = .portrait
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                }
            } else {
                AppDelegate.orientationLock = .all
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
                }
            }
        }
        .onChange(of: activeTab) { _ in
            speechRecognizer.stopRecording()
        }
        .onChange(of: isFlipped) { _ in
            speechRecognizer.stopRecording()
        }
        .onDisappear {
            speechRecognizer.stopRecording()
            AppDelegate.orientationLock = .all
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
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
                    let effectiveLang = LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage)
                    let locale = LocaleHelper.getLocaleForLanguage(effectiveLang)
                    speechRecognizer.startRecording(locale: locale)
                }
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
                appLanguage: appLanguage,
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
                appLanguage: appLanguage,
                onYes: {
                    let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "yes", appLanguage: appLanguage)
                    handleUserResponse(displayText: label, ttsText: label)
                    if activeTab == .whyFinder { whySession.answerYes() }
                },
                onNo: {
                    let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "no", appLanguage: appLanguage)
                    handleUserResponse(displayText: label, ttsText: label)
                    if activeTab == .whyFinder { whySession.answerNo() }
                },
                onNotSure: {
                    let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "not_sure", appLanguage: appLanguage)
                    handleUserResponse(displayText: label, ttsText: label)
                    if activeTab == .whyFinder { whySession.answerNotSure() }
                },
                onStop: {
                    let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "stop", appLanguage: appLanguage)
                    handleUserResponse(displayText: label, ttsText: label)
                    if activeTab == .whyFinder { whySession.stop() }
                },
                onSelectBodyPart: { partKey in
                    let label = LocaleHelper.getBodyRegionLabel(partKey, appLanguage: appLanguage)
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
                appLanguage: appLanguage,
                isListening: speechRecognizer.isRecording,
                canStepBack: whySession.canStepBack(),
                canSpeakPrompt: (activeTab == .whyFinder ? !whyPromptText.isEmpty : !activeFreeformText.isEmpty),
                onToggleListening: {
                    toggleListening()
                },
                onSpeakPrompt: {
                    speechRecognizer.stopRecording()
                    let text = activeTab == .whyFinder ? whyPromptText : activeFreeformText
                    if !text.isEmpty { onSpeakResponse(text) }
                },
                onPickCard: {
                    speechRecognizer.stopRecording()
                    showQuestionsSheet = true
                },
                onStepBack: {
                    speechRecognizer.stopRecording()
                    whySession.stepBack()
                },
                onToggleKeyboard: {
                    speechRecognizer.stopRecording()
                    showKeyboardInput.toggle()
                },
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
                    appLanguage: appLanguage,
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
                    appLanguage: appLanguage,
                    onYes: {
                        let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "yes", appLanguage: appLanguage)
                        handleUserResponse(displayText: label, ttsText: label)
                        if activeTab == .whyFinder { whySession.answerYes() }
                    },
                    onNo: {
                        let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "no", appLanguage: appLanguage)
                        handleUserResponse(displayText: label, ttsText: label)
                        if activeTab == .whyFinder { whySession.answerNo() }
                    },
                    onNotSure: {
                        let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "not_sure", appLanguage: appLanguage)
                        handleUserResponse(displayText: label, ttsText: label)
                        if activeTab == .whyFinder { whySession.answerNotSure() }
                    },
                    onStop: {
                        let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "stop", appLanguage: appLanguage)
                        handleUserResponse(displayText: label, ttsText: label)
                        if activeTab == .whyFinder { whySession.stop() }
                    },
                    onSelectBodyPart: { partKey in
                        let label = LocaleHelper.getBodyRegionLabel(partKey, appLanguage: appLanguage)
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
                appLanguage: appLanguage,
                isListening: speechRecognizer.isRecording,
                canStepBack: whySession.canStepBack(),
                canSpeakPrompt: (activeTab == .whyFinder ? !whyPromptText.isEmpty : !activeFreeformText.isEmpty),
                onToggleListening: {
                    toggleListening()
                },
                onSpeakPrompt: {
                    speechRecognizer.stopRecording()
                    let text = activeTab == .whyFinder ? whyPromptText : activeFreeformText
                    if !text.isEmpty { onSpeakResponse(text) }
                },
                onPickCard: {
                    speechRecognizer.stopRecording()
                    showQuestionsSheet = true
                },
                onStepBack: {
                    speechRecognizer.stopRecording()
                    whySession.stepBack()
                },
                onToggleKeyboard: {
                    speechRecognizer.stopRecording()
                    showKeyboardInput.toggle()
                },
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
        speechRecognizer.stopRecording()
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
            TextField(isIndonesian ? "Ketik pesan atau pertanyaan..." : "Type a phrase or prompt...", text: $manualInputText)
                .font(.system(size: 15))
                .foregroundColor(SottoTheme.textPrimary)
                .padding(10)
                .background(SottoTheme.surface)
                .cornerRadius(10)
                .onSubmit {
                    speechRecognizer.stopRecording()
                }
            
            Button(isIndonesian ? "Selesai" : "Done") {
                speechRecognizer.stopRecording()
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
                        
                        // Area Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                let isAll = selectedPromptCategory == "ALL"
                                Button(action: { selectedPromptCategory = "ALL" }) {
                                    Text(LocaleHelper.getCategoryDisplayName("ALL", appLanguage: appLanguage))
                                        .font(.system(size: 13, weight: isAll ? .bold : .regular))
                                        .foregroundColor(isAll ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isAll ? SottoTheme.surfaceVariant : SottoTheme.surface)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                                
                                ForEach(tree.areas, id: \.id) { area in
                                    let isSel = selectedPromptCategory == area.id
                                    Button(action: { selectedPromptCategory = area.id }) {
                                        Text(LocaleHelper.getAreaDisplayName(area.id, appLanguage: appLanguage))
                                            .font(.system(size: 13, weight: isSel ? .bold : .regular))
                                            .foregroundColor(isSel ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(isSel ? SottoTheme.surfaceVariant : SottoTheme.surface)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(tree.areas.enumerated()), id: \.element.id) { aIdx, area in
                                    if selectedPromptCategory == "ALL" || selectedPromptCategory == area.id {
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
                            }
                            .padding(16)
                        }
                    } else {
                        // Phrases Cards (Talk Mode)
                        let effectiveCats = categories.isEmpty ? PhraseCategory.defaultCategoryNames : categories
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                let isAll = selectedPromptCategory == "ALL"
                                Button(action: { selectedPromptCategory = "ALL" }) {
                                    Text(LocaleHelper.getCategoryDisplayName("ALL", appLanguage: appLanguage))
                                        .font(.system(size: 13, weight: isAll ? .bold : .regular))
                                        .foregroundColor(isAll ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isAll ? SottoTheme.surfaceVariant : SottoTheme.surface)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
                                
                                ForEach(effectiveCats, id: \.self) { catName in
                                    let isSel = selectedPromptCategory == catName
                                    Button(action: { selectedPromptCategory = catName }) {
                                        Text(LocaleHelper.getCategoryDisplayName(catName, appLanguage: appLanguage))
                                            .font(.system(size: 13, weight: isSel ? .bold : .regular))
                                            .foregroundColor(isSel ? SottoTheme.textPrimary : SottoTheme.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(isSel ? SottoTheme.surfaceVariant : SottoTheme.surface)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                        
                        let filteredPhrases: [Phrase] = {
                            if selectedPromptCategory == "ALL" {
                                return allPhrases
                            } else if selectedPromptCategory.uppercased() == "EMERGENCY" || selectedPromptCategory.uppercased() == "SAFETY" {
                                return allPhrases.filter { $0.isEmergency }
                            } else {
                                return allPhrases.filter { !$0.isEmergency && $0.category.rawValue == selectedPromptCategory }
                            }
                        }()
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredPhrases) { phrase in
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
            .navigationTitle(activeTab == .whyFinder ? (isIndonesian ? "Pertanyaan Panduan" : "Tree Questions") : (isIndonesian ? "Pilih Kartu" : "Choose Card"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isIndonesian ? "Batal" : "Cancel") {
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
    let appLanguage: String
    let onRestartWhyTree: () -> Void
    let onFinish: () -> Void
    let onReadAloudPrompt: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Status reply / listening badge
            HStack {
                if let reply = lastReply {
                    let prefix = LocaleHelper.getTwoWayActionLabel(actionKey: "replied_prefix", appLanguage: appLanguage)
                    Text("✓ \(prefix)\(reply)")
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
                        Text(LocaleHelper.getTwoWayActionLabel(actionKey: "listening", appLanguage: appLanguage))
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
                let outcomeTitle: String = {
                    switch outcome {
                    case .found: return "🎯 " + LocaleHelper.getTwoWayActionLabel(actionKey: "cause_found", appLanguage: appLanguage)
                    case .stopped: return "⏸ " + LocaleHelper.getTwoWayActionLabel(actionKey: "stopped", appLanguage: appLanguage)
                    default: return "🔍 " + LocaleHelper.getTwoWayActionLabel(actionKey: "unresolved", appLanguage: appLanguage)
                    }
                }()
                
                VStack(spacing: 14) {
                    Text(outcomeTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(SottoTheme.textPrimary)
                    
                    if outcome == .found, let c = cause, !c.isEmpty {
                        VStack(spacing: 4) {
                            Text(c)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(SottoTheme.primary)
                            
                            if let p = part, !p.isEmpty {
                                let partLabel = LocaleHelper.getBodyRegionLabel(p, appLanguage: appLanguage)
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
                            Text("🔄 " + LocaleHelper.getTwoWayActionLabel(actionKey: "restart", appLanguage: appLanguage))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(SottoTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(SottoTheme.surfaceVariant)
                                .cornerRadius(10)
                        }
                        
                        Button(action: onFinish) {
                            Text(LocaleHelper.getTwoWayActionLabel(actionKey: "done", appLanguage: appLanguage))
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
                let hint = LocaleHelper.getTwoWayActionLabel(actionKey: "mic_hint", appLanguage: appLanguage)
                Button(action: onReadAloudPrompt) {
                    Text(prompt.isEmpty ? hint : prompt)
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
    let appLanguage: String
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
        let strYes = LocaleHelper.getTwoWayResponseLabel(responseKey: "yes", appLanguage: appLanguage)
        let strNo = LocaleHelper.getTwoWayResponseLabel(responseKey: "no", appLanguage: appLanguage)
        let strNotSure = LocaleHelper.getTwoWayResponseLabel(responseKey: "not_sure", appLanguage: appLanguage)
        let strStop = LocaleHelper.getTwoWayResponseLabel(responseKey: "stop", appLanguage: appLanguage)
        
        return VStack(spacing: 8) {
            // Row 1: YES & NO
            HStack(spacing: 10) {
                Button(action: onYes) {
                    Text("✓ \(strYes)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(SottoTheme.successText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(SottoTheme.successContainer)
                        .cornerRadius(16)
                }
                
                Button(action: onNo) {
                    Text("✕ \(strNo)")
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
                    Text("? \(strNotSure)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(SottoTheme.warningHighText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SottoTheme.warningHighContainer)
                        .cornerRadius(16)
                }
                
                Button(action: onStop) {
                    Text("⏹ \(strStop)")
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
        let strNotSure = LocaleHelper.getTwoWayResponseLabel(responseKey: "not_sure", appLanguage: appLanguage)
        let strStop = LocaleHelper.getTwoWayResponseLabel(responseKey: "stop", appLanguage: appLanguage)
        
        return VStack(spacing: 8) {
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(BodyRegions.all, id: \.self) { region in
                    Button(action: { onSelectBodyPart(region) }) {
                        Text(LocaleHelper.getBodyRegionLabel(region, appLanguage: appLanguage))
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
                    Text("? \(strNotSure)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(12)
                }
                
                Button(action: onStop) {
                    Text("⏹ \(strStop)")
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
        let strNotSure = LocaleHelper.getTwoWayResponseLabel(responseKey: "not_sure", appLanguage: appLanguage)
        let strStop = LocaleHelper.getTwoWayResponseLabel(responseKey: "stop", appLanguage: appLanguage)
        
        return VStack(spacing: 10) {
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
                    Text("? \(strNotSure)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SottoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(SottoTheme.surfaceVariant)
                        .cornerRadius(12)
                }
                
                Button(action: onStop) {
                    Text("⏹ \(strStop)")
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
    let appLanguage: String
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
            // Guided first, then Talk (matching Android layout)
            HStack {
                HStack(spacing: 8) {
                    Button(action: { activeTab = .whyFinder }) {
                        Text("🧭 \(LocaleHelper.getTwoWayTabLabel(isWhyFinder: true, appLanguage: appLanguage))")
                            .font(.system(size: 13, weight: activeTab == .whyFinder ? .bold : .medium))
                            .foregroundColor(activeTab == .whyFinder ? SottoTheme.onPrimary : SottoTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(activeTab == .whyFinder ? SottoTheme.primary : SottoTheme.surface)
                            .cornerRadius(16)
                    }
                    
                    Button(action: { activeTab = .freeform }) {
                        Text("💬 \(LocaleHelper.getTwoWayTabLabel(isWhyFinder: false, appLanguage: appLanguage))")
                            .font(.system(size: 13, weight: activeTab == .freeform ? .bold : .medium))
                            .foregroundColor(activeTab == .freeform ? SottoTheme.onPrimary : SottoTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(activeTab == .freeform ? SottoTheme.primary : SottoTheme.surface)
                            .cornerRadius(16)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Button(action: { withAnimation(.easeInOut(duration: 0.25)) { isFlipped.toggle() } }) {
                        HStack(spacing: 4) {
                            Text("🔄")
                            Text(LocaleHelper.getTwoWayActionLabel(actionKey: isFlipped ? "flip_back" : "flip", appLanguage: appLanguage))
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
                            Text(LocaleHelper.getTwoWayActionLabel(actionKey: "speak", appLanguage: appLanguage))
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
                            Text(LocaleHelper.getTwoWayActionLabel(actionKey: "cards", appLanguage: appLanguage))
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
                                Text(LocaleHelper.getTwoWayActionLabel(actionKey: "back", appLanguage: appLanguage))
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
                            Text(LocaleHelper.getTwoWayActionLabel(actionKey: "speak", appLanguage: appLanguage))
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
                            Text(LocaleHelper.getTwoWayActionLabel(actionKey: "cards", appLanguage: appLanguage))
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
                            Text(LocaleHelper.getTwoWayActionLabel(actionKey: isListening ? "stop" : "mic", appLanguage: appLanguage))
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
                            Text(LocaleHelper.getTwoWayActionLabel(actionKey: "type", appLanguage: appLanguage))
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
