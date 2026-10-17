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
    @Environment(\.sottoPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var isPromptFocused: Bool

    public let allPhrases: [Phrase]
    public let categories: [String]
    public let whyFinderRepository: WhyFinderRepositoryProtocol
    public let voiceSettings: VoiceSettings
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
    @State private var showPostResolutionPrompt: Bool = false
    @State private var triggerLoggedFeedback: String? = nil
    @State private var showExitConfirmation: Bool = false
    
    // Why Finder session state
    @StateObject private var whySession: WhyFinderSession
    @StateObject private var speechRecognizer = SpeechRecognizerService()
    
    public init(
        allPhrases: [Phrase],
        categories: [String] = [],
        whyFinderRepository: WhyFinderRepositoryProtocol = UserDefaultsWhyFinderRepository.shared,
        voiceSettings: VoiceSettings = UserDefaultsVoiceSettingsRepository().getVoiceSettings(),
        appLanguage: String = "system",
        onSpeakResponse: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.allPhrases = allPhrases
        self.categories = categories
        self.whyFinderRepository = whyFinderRepository
        self.voiceSettings = voiceSettings
        self.appLanguage = appLanguage
        self.onSpeakResponse = onSpeakResponse
        self.onDismiss = onDismiss
        
        let tree = whyFinderRepository.getTree()
        _whySession = StateObject(wrappedValue: WhyFinderSession(tree: tree))
        
        let args = ProcessInfo.processInfo.arguments
        let isId = LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage) == LocaleHelper.langIndonesian
        
        let savedTab = UserDefaults.standard.string(forKey: "partner_mode_last_tab")
        let defaultTab: CaregiverTab = (savedTab == "whyFinder") ? .whyFinder : .freeform
        var initialTab = defaultTab
        if args.contains("--whyfinder") || args.contains("--screenshot-whyfinder") {
            initialTab = .whyFinder
        } else if args.contains("--triage") || args.contains("--screenshot-triage") || args.contains("--partner") {
            initialTab = .freeform
        }
        _activeTab = State(initialValue: initialTab)
        
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
            palette.background
                .ignoresSafeArea()
            
            if reduceMotion {
                conversationLayout
                    .id(isFlipped)
                    .transition(.opacity)
            } else {
                conversationLayout
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
        .onChange(of: speechRecognizer.errorMessage) { newError in
            if let err = newError, !err.isEmpty {
                UsabilityTracker.shared.recordFriction("speech_error", voiceSettings: voiceSettings)
            }
        }
        .onChange(of: whySession.currentState) { state in
            if case .finished = state {
                finishAndSaveWhySession()
            }
        }
        .onChange(of: isFlipped) { flipped in
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let contextTag = isPad ? "ipad" : "phone"
            UsabilityTracker.shared.startIntent("partner_flip")
            UsabilityTracker.shared.endIntent(
                "partner_flip",
                outcome: flipped ? "flipped" : "unflipped",
                contextTag: contextTag,
                voiceSettings: voiceSettings
            )
            isPromptFocused = true
            
            if flipped {
                if !isPad {
                    AppDelegate.orientationLock = .portrait
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                    }
                }
            } else {
                if !isPad {
                    AppDelegate.orientationLock = .all
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
                    }
                }
            }
        }
        .onChange(of: activeTab) { newTab in
            speechRecognizer.stopRecording()
            UserDefaults.standard.set(newTab == .whyFinder ? "whyFinder" : "freeform", forKey: "partner_mode_last_tab")
        }
        .onChange(of: isFlipped) { _ in
            speechRecognizer.stopRecording()
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            speechRecognizer.stopRecording()
            AppDelegate.orientationLock = .all
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
            }
        }
        .alert(isIndonesian ? "Keluar Mode Mitra?" : "Exit Partner Mode?", isPresented: $showExitConfirmation) {
            Button(isIndonesian ? "Lanjutkan" : "Continue", role: .cancel) { }
            Button(isIndonesian ? "Keluar" : "Exit", role: .destructive) {
                confirmDismiss()
            }
        } message: {
            Text(isIndonesian ? "Pemeriksaan aktif sedang berlangsung. Ingin keluar? Sesi akan disimpan sebagai berhenti." : "An active check-in is in progress. Do you want to exit? Your session will be saved as stopped.")
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
    
    // MARK: - Animated Unified Conversation Layout (180° Flip Support)
    
    private var conversationLayout: some View {
        VStack(spacing: 8) {
            // Patient display and responses rotated 180° facing partner across table when flipped
            VStack(spacing: 10) {
                CaregiverDisplayCard(
                    activeTab: activeTab,
                    whyState: whySession.currentState,
                    whyPromptText: whyPromptText,
                    activeFreeformText: activeFreeformText,
                    lastReply: lastReply,
                    isListening: speechRecognizer.isRecording,
                    appLanguage: appLanguage,
                    isPromptFocused: $isPromptFocused,
                    onRestartWhyTree: {
                        whySession.restart()
                        whySessionSaved = false
                    },
                    onFinish: {
                        handleDismissRequest()
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
                        handlePartnerResponse(action: "yes")
                    },
                    onNo: {
                        handlePartnerResponse(action: "no")
                    },
                    onWait: {
                        handlePartnerResponse(action: "wait")
                    },
                    onRepeat: {
                        handlePartnerResponse(action: "repeat")
                    },
                    onNotSure: {
                        handlePartnerResponse(action: "not_sure")
                    },
                    onStop: {
                        handlePartnerResponse(action: "stop")
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
            .rotationEffect(.degrees(isFlipped ? 180 : 0))
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: isFlipped)
            
            // Caregiver controls facing the caregiver at the bottom
            if let speechErr = speechRecognizer.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(SottoTheme.warning)
                    Text(speechErr)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.textPrimary)
                        .lineLimit(2)
                    Spacer()
                    Button(action: { speechRecognizer.errorMessage = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.textSecondary)
                    }
                    .accessibilityLabel("Dismiss dictation error")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(palette.surfaceVariant)
                .cornerRadius(10)
                .padding(.horizontal, 16)
            }

            if let feedback = triggerLoggedFeedback {
                Text(feedback)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(SottoTheme.successText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(SottoTheme.successContainer.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            }
            
            if showPostResolutionPrompt && activeTab == .freeform {
                PostResolutionTriggerLogger(
                    appLanguage: appLanguage,
                    voiceSettings: voiceSettings,
                    onLogTrigger: { logPostResolutionTrigger($0) },
                    onDismiss: { showPostResolutionPrompt = false }
                )
                .padding(.horizontal, 16)
            }
            
            if showKeyboardInput && activeTab == .freeform {
                manualKeyboardRow
                    .padding(.horizontal, 16)
            }
            
            if isFlipped {
                CaregiverMirrorHUD(
                    activeTab: activeTab,
                    whyState: whySession.currentState,
                    currentPrompt: activeTab == .whyFinder ? whyPromptText : activeFreeformText,
                    lastReply: lastReply,
                    appLanguage: appLanguage,
                    onRestartWhyTree: {
                        whySession.restart()
                        whySessionSaved = false
                    },
                    onDone: {
                        handleDismissRequest()
                    }
                )
                .padding(.horizontal, 16)
                .transition(.opacity)
            }
            
            CaregiverBottomMenu(
                activeTab: $activeTab,
                isFlipped: $isFlipped,
                showPostResolutionPrompt: $showPostResolutionPrompt,
                hasWhyFinder: !whySession.tree.areas.isEmpty,
                appLanguage: appLanguage,
                voiceSettings: voiceSettings,
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
                    handleDismissRequest()
                }
            )
        }
        .padding(.top, 8)
    }
    
    private var isSessionActive: Bool {
        if activeTab == .whyFinder {
            switch whySession.currentState {
            case .finished:
                return false
            case .askingArea(let index, _):
                return index > 0 || whySession.canStepBack() || !whySession.steps.isEmpty
            default:
                return true
            }
        } else {
            return lastReply != nil || !displayedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func handleDismissRequest() {
        if isSessionActive {
            showExitConfirmation = true
        } else {
            confirmDismiss()
        }
    }
    
    private func confirmDismiss() {
        speechRecognizer.stopRecording()
        if activeTab == .whyFinder {
            if case .finished = whySession.currentState {
                // already finished and saved
            } else {
                whySession.stop()
                finishAndSaveWhySession()
            }
        }
        onDismiss()
    }
    
    private func handlePartnerResponse(action: String) {
        UsabilityTracker.shared.startIntent("partner_response")
        UsabilityTracker.shared.endIntent(
            "partner_response",
            outcome: action,
            voiceSettings: voiceSettings
        )
        
        switch action {
        case "yes":
            let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "yes", appLanguage: appLanguage)
            handleUserResponse(displayText: label, ttsText: label)
            if activeTab == .whyFinder {
                whySession.answerYes()
            } else {
                showPostResolutionPrompt = true
            }
        case "no":
            let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "no", appLanguage: appLanguage)
            handleUserResponse(displayText: label, ttsText: label)
            if activeTab == .whyFinder {
                whySession.answerNo()
            } else {
                showPostResolutionPrompt = true
            }
        case "wait":
            let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "wait", appLanguage: appLanguage)
            handleUserResponse(displayText: label, ttsText: label)
        case "repeat":
            let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "repeat", appLanguage: appLanguage)
            handleUserResponse(displayText: label, ttsText: label)
        case "not_sure":
            let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "not_sure", appLanguage: appLanguage)
            handleUserResponse(displayText: label, ttsText: label)
            if activeTab == .whyFinder { whySession.answerNotSure() }
        case "stop":
            let label = LocaleHelper.getTwoWayResponseLabel(responseKey: "stop", appLanguage: appLanguage)
            handleUserResponse(displayText: label, ttsText: label)
            if activeTab == .whyFinder { whySession.stop() }
        default:
            break
        }
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
    
    private func logPostResolutionTrigger(_ triggerKey: String) {
        let areaId: String
        switch triggerKey {
        case "Pain": areaId = UserDefaultsWhyFinderRepository.areaBody
        case "Noise": areaId = UserDefaultsWhyFinderRepository.areaSenses
        case "Task": areaId = UserDefaultsWhyFinderRepository.areaHappened
        case "Emotion": areaId = UserDefaultsWhyFinderRepository.areaFeelings
        default: areaId = "other"
        }
        
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let promptText = activeFreeformText.isEmpty ? (isIndonesian ? "Pemeriksaan Ya/Tidak Langsung" : "Direct Yes/No Check-in") : activeFreeformText
        let entry = WhyLogEntry(
            id: UUID().uuidString,
            startedAt: now - 3000,
            endedAt: now,
            outcome: .found,
            areaId: areaId,
            causeText: triggerKey,
            bodyPart: nil,
            intensity: nil,
            note: nil,
            privateNote: nil,
            steps: [
                WhyStep(
                    questionText: promptText,
                    answer: "yes"
                )
            ]
        )
        whyFinderRepository.addLog(entry)
        UsabilityTracker.shared.recordActivation(key: "why_log_quick_trigger")
        UsabilityTracker.shared.recordWhyFinder(
            outcome: "found",
            areaId: areaId,
            depth: 1,
            notSureCount: 0,
            bodyPart: nil,
            intensity: nil,
            durationMs: 3000
        )
        
        let label = LocaleHelper.getTriggerLabel(triggerKey, appLanguage: appLanguage)
        triggerLoggedFeedback = LocaleHelper.getTriggerLoggedFeedback(label, appLanguage: appLanguage)
        showPostResolutionPrompt = false
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            triggerLoggedFeedback = nil
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
    @Environment(\.sottoPalette) private var palette
    let activeTab: CaregiverTab
    let whyState: WhyFinderState
    let whyPromptText: String
    let activeFreeformText: String
    let lastReply: String?
    let isListening: Bool
    let appLanguage: String
    var isPromptFocused: AccessibilityFocusState<Bool>.Binding
    let onRestartWhyTree: () -> Void
    let onFinish: () -> Void
    let onReadAloudPrompt: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Status reply / steady listening badge
            HStack {
                if let reply = lastReply {
                    let prefix = LocaleHelper.getTwoWayActionLabel(actionKey: "replied_prefix", appLanguage: appLanguage)
                    HStack(spacing: 6) {
                        SottoIconView(.check, size: 12, tint: .white)
                        Text("\(prefix)\(reply)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(SottoTheme.successGreen)
                    .cornerRadius(12)
                } else if isListening {
                    HStack(spacing: 6) {
                        SottoIconView(.mic, size: 12, tint: SottoTheme.recordingPulseRed)
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
                let (outcomeIcon, outcomeTitle): (SottoIcon, String) = {
                    switch outcome {
                    case .found: return (.target, LocaleHelper.getTwoWayActionLabel(actionKey: "cause_found", appLanguage: appLanguage))
                    case .stopped: return (.pause, LocaleHelper.getTwoWayActionLabel(actionKey: "stopped", appLanguage: appLanguage))
                    default: return (.search, LocaleHelper.getTwoWayActionLabel(actionKey: "unresolved", appLanguage: appLanguage))
                    }
                }()
                
                VStack(spacing: 14) {
                    HStack(spacing: 8) {
                        SottoIconView(outcomeIcon, size: 22, tint: palette.textPrimary)
                        Text(outcomeTitle)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                    }
                    
                    if outcome == .found, let c = cause, !c.isEmpty {
                        VStack(spacing: 4) {
                            Text(c)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(palette.accent)
                            
                            if let p = part, !p.isEmpty {
                                let partLabel = LocaleHelper.getBodyRegionLabel(p, appLanguage: appLanguage)
                                let intensityStr = intensity != nil ? " • \(intensity!)/5" : ""
                                Text("\(partLabel)\(intensityStr)")
                                    .font(.system(size: 15))
                                    .foregroundColor(palette.textSecondary)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(palette.accent.opacity(0.15))
                        .cornerRadius(12)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: onRestartWhyTree) {
                            HStack(spacing: 6) {
                                SottoIconView(.refresh, size: 15, tint: palette.textPrimary)
                                Text(LocaleHelper.getTwoWayActionLabel(actionKey: "restart", appLanguage: appLanguage))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(palette.surfaceVariant)
                            .cornerRadius(10)
                        }
                        .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: "restart", appLanguage: appLanguage))
                        
                        Button(action: onFinish) {
                            Text(LocaleHelper.getTwoWayActionLabel(actionKey: "done", appLanguage: appLanguage))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(SottoTheme.confirm)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: "done", appLanguage: appLanguage))
                    }
                }
            } else {
                // Active Prompt (Tap to read aloud)
                let prompt = activeTab == .whyFinder ? whyPromptText : activeFreeformText
                let hint = LocaleHelper.getTwoWayActionLabel(actionKey: "mic_hint", appLanguage: appLanguage)
                Button(action: onReadAloudPrompt) {
                    Text(prompt.isEmpty ? hint : prompt)
                        .font(.system(size: prompt.count < 40 ? 30 : 22, weight: .bold))
                        .foregroundColor(prompt.isEmpty ? palette.textSecondary.opacity(0.6) : palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .accessibilityFocused(isPromptFocused)
                .accessibilityLabel(prompt.isEmpty ? hint : prompt)
                .accessibilityHint(LocaleHelper.getTwoWayActionLabel(actionKey: "speak", appLanguage: appLanguage))
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.surface)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(palette.outlineVariant.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Caregiver Response Dock

private struct CaregiverResponseDock: View {
    @Environment(\.sottoPalette) private var palette
    let activeTab: CaregiverTab
    let whyState: WhyFinderState
    let appLanguage: String
    let onYes: () -> Void
    let onNo: () -> Void
    let onWait: () -> Void
    let onRepeat: () -> Void
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
                fourCardDock(isWhyFinder: true)
            }
        } else {
            fourCardDock(isWhyFinder: false)
        }
    }
    
    // Unified Tactile Response Dock (20pt radius shapes, tonal tactile palettes, haptics)
    private func fourCardDock(isWhyFinder: Bool) -> some View {
        let strYes = LocaleHelper.getTwoWayResponseLabel(responseKey: "yes", appLanguage: appLanguage)
        let strNo = LocaleHelper.getTwoWayResponseLabel(responseKey: "no", appLanguage: appLanguage)
        let strNotSure = LocaleHelper.getTwoWayResponseLabel(responseKey: "not_sure", appLanguage: appLanguage)
        let strStop = LocaleHelper.getTwoWayResponseLabel(responseKey: "stop", appLanguage: appLanguage)
        let strWait = LocaleHelper.getTwoWayResponseLabel(responseKey: "wait", appLanguage: appLanguage)
        let isId = LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage) == LocaleHelper.langIndonesian
        
        return VStack(spacing: 8) {
            // Row 1: YES & NO (Primary Crisis Buttons >= 80pt frame height with tactile haptics)
            HStack(spacing: 10) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    onYes()
                }) {
                    HStack(spacing: 8) {
                        SottoIconView(.check, size: 24, tint: SottoTheme.successText)
                        Text(strYes)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(SottoTheme.successText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 80, maxHeight: 92)
                    .background(SottoTheme.successContainer)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 2)
                }
                .accessibilityLabel(strYes)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(isId ? "Ketuk dua kali untuk konfirmasi ya" : "Double tap to confirm yes")
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    onNo()
                }) {
                    HStack(spacing: 8) {
                        SottoIconView(.close, size: 24, tint: SottoTheme.crisisNoText)
                        Text(strNo)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(SottoTheme.crisisNoText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 80, maxHeight: 92)
                    .background(SottoTheme.crisisNoContainer)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 2)
                }
                .accessibilityLabel(strNo)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(isId ? "Ketuk dua kali untuk mengatakan tidak" : "Double tap to say no")
            }
            
            // Row 2: Secondary choices (Unified tactile row: Wait, Not Sure, Stop >= 54pt minHeight)
            HStack(spacing: 8) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onWait()
                }) {
                    HStack(spacing: 6) {
                        SottoIconView(.hourglass, size: 18, tint: SottoTheme.neutralDarkText)
                        Text(strWait)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SottoTheme.neutralDarkText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(SottoTheme.neutralDarkContainer)
                    .cornerRadius(18)
                }
                .accessibilityLabel(strWait)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(isId ? "Ketuk dua kali untuk meminta jeda waktu" : "Double tap to request a moment to pause")
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onNotSure()
                }) {
                    HStack(spacing: 6) {
                        SottoIconView(.questionmark, size: 18, tint: SottoTheme.warningHighText)
                        Text(strNotSure)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SottoTheme.warningHighText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(SottoTheme.warningHighContainer)
                    .cornerRadius(18)
                }
                .accessibilityLabel(strNotSure)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(isId ? "Ketuk dua kali jika ragu atau belum yakin" : "Double tap if unsure or not certain")
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onStop()
                }) {
                    HStack(spacing: 6) {
                        SottoIconView(.stop, size: 18, tint: SottoTheme.neutralStoppedText)
                        Text(strStop)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SottoTheme.neutralStoppedText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(SottoTheme.neutralStoppedContainer)
                    .cornerRadius(18)
                }
                .accessibilityLabel(strStop)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(isId ? "Ketuk dua kali untuk menghentikan pemeriksaan" : "Double tap to pause or stop check-in")
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
                            .foregroundColor(palette.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(palette.surfaceVariant)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(palette.outlineVariant.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
            }
            
            HStack(spacing: 10) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onNotSure()
                }) {
                    HStack(spacing: 6) {
                        SottoIconView(.questionmark, size: 16, tint: palette.textPrimary)
                        Text(strNotSure)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(palette.surfaceVariant)
                    .cornerRadius(20)
                }
                .accessibilityLabel(strNotSure)
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onStop()
                }) {
                    HStack(spacing: 6) {
                        SottoIconView(.stop, size: 16, tint: palette.textPrimary)
                        Text(strStop)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(palette.surfaceVariant)
                    .cornerRadius(20)
                }
                .accessibilityLabel(strStop)
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
                            .cornerRadius(16)
                    }
                }
            }
            
            HStack(spacing: 10) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onNotSure()
                }) {
                    HStack(spacing: 6) {
                        SottoIconView(.questionmark, size: 16, tint: palette.textPrimary)
                        Text(strNotSure)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(palette.surfaceVariant)
                    .cornerRadius(20)
                }
                .accessibilityLabel(strNotSure)
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onStop()
                }) {
                    HStack(spacing: 6) {
                        SottoIconView(.stop, size: 16, tint: palette.textPrimary)
                        Text(strStop)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(palette.surfaceVariant)
                    .cornerRadius(20)
                }
                .accessibilityLabel(strStop)
            }
        }
    }
}

// MARK: - Post-Resolution Pattern Logger

private struct PostResolutionTriggerLogger: View {
    @Environment(\.sottoPalette) private var palette
    let appLanguage: String
    let voiceSettings: VoiceSettings
    let onLogTrigger: (String) -> Void
    let onDismiss: () -> Void
    
    private let triggers: [(key: String, icon: SottoIcon)] = [
        ("Pain", .crossCase),
        ("Noise", .speakerWave3),
        ("Task", .checklist),
        ("Emotion", .heart),
        ("Other", .ellipsisCircle)
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    SottoIconView(.noteAlt, size: 16, tint: palette.textSecondary)
                    Text(LocaleHelper.getTriggerLogHeader(appLanguage: appLanguage))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                }
                Spacer()
                Button(action: onDismiss) {
                    SottoIconView(.close, size: 14, tint: palette.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: "dismiss", appLanguage: appLanguage))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(triggers, id: \.key) { item in
                        let label = LocaleHelper.getTriggerLabel(item.key, appLanguage: appLanguage)
                        Button(action: {
                            UsabilityTracker.shared.startIntent("trigger_logged")
                            UsabilityTracker.shared.endIntent(
                                "trigger_logged",
                                outcome: item.key.lowercased(),
                                voiceSettings: voiceSettings
                            )
                            onLogTrigger(item.key)
                        }) {
                            HStack(spacing: 6) {
                                SottoIconView(item.icon, size: 14, tint: palette.accent)
                                Text(label)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .frame(minHeight: 44)
                            .background(palette.surfaceVariant)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(palette.outlineVariant.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel(label)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(12)
        .background(palette.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(palette.outlineVariant.opacity(0.6), lineWidth: 1)
        )
    }
}

// MARK: - Caregiver Bottom Menu

private struct CaregiverBottomMenu: View {
    @Environment(\.sottoPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var activeTab: CaregiverTab
    @Binding var isFlipped: Bool
    @Binding var showPostResolutionPrompt: Bool
    let hasWhyFinder: Bool
    let appLanguage: String
    let voiceSettings: VoiceSettings
    let isListening: Bool
    let canStepBack: Bool
    let canSpeakPrompt: Bool
    let onToggleListening: () -> Void
    let onSpeakPrompt: () -> Void
    let onPickCard: () -> Void
    let onStepBack: () -> Void
    let onToggleKeyboard: () -> Void
    let onDismiss: () -> Void
    
    private var isIndonesian: Bool {
        LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage) == LocaleHelper.langIndonesian
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Line 1: Mode Switcher Tabs + Tool Capsule + Standalone Dismissal
            HStack(spacing: 8) {
                // Tabs: Guided / Talk
                HStack(spacing: 6) {
                    if hasWhyFinder {
                        Button(action: {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                                activeTab = .whyFinder
                            }
                        }) {
                            HStack(spacing: 4) {
                                SottoIconView(
                                    .branch,
                                    size: 14,
                                    tint: activeTab == .whyFinder ? palette.background : palette.textSecondary
                                )
                                Text(LocaleHelper.getTwoWayTabLabel(isWhyFinder: true, appLanguage: appLanguage))
                                    .font(.system(size: 13, weight: activeTab == .whyFinder ? .bold : .medium))
                                    .lineLimit(1)
                            }
                            .foregroundColor(activeTab == .whyFinder ? palette.background : palette.textSecondary)
                            .padding(.horizontal, 10)
                            .frame(height: 34)
                            .background(activeTab == .whyFinder ? palette.accent : palette.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(palette.outlineVariant.opacity(activeTab == .whyFinder ? 0 : 0.6), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel(isIndonesian ? "Mode panduan" : "Guided mode")
                        .accessibilityAddTraits(activeTab == .whyFinder ? [.isSelected, .isButton] : [.isButton])

                        Button(action: {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                                activeTab = .freeform
                            }
                        }) {
                            HStack(spacing: 4) {
                                SottoIconView(
                                    .chat,
                                    size: 14,
                                    tint: activeTab == .freeform ? palette.background : palette.textSecondary
                                )
                                Text(LocaleHelper.getTwoWayTabLabel(isWhyFinder: false, appLanguage: appLanguage))
                                    .font(.system(size: 13, weight: activeTab == .freeform ? .bold : .medium))
                                    .lineLimit(1)
                            }
                            .foregroundColor(activeTab == .freeform ? palette.background : palette.textSecondary)
                            .padding(.horizontal, 10)
                            .frame(height: 34)
                            .background(activeTab == .freeform ? palette.accent : palette.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(palette.outlineVariant.opacity(activeTab == .freeform ? 0 : 0.6), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel(isIndonesian ? "Mode bicara" : "Talk mode")
                        .accessibilityAddTraits(activeTab == .freeform ? [.isSelected, .isButton] : [.isButton])
                    }
                }
                
                Spacer()
                
                // Global Controls: Tool Capsule + Standalone Dismissal
                HStack(spacing: 6) {
                    // Tool Capsule: Log (Talk tab only) + Flip
                    HStack(spacing: 2) {
                        if activeTab == .freeform && hasWhyFinder {
                            Button(action: {
                                UsabilityTracker.shared.startIntent("partner_tool")
                                UsabilityTracker.shared.endIntent(
                                    "partner_tool",
                                    outcome: "log",
                                    voiceSettings: voiceSettings
                                )
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                                    showPostResolutionPrompt.toggle()
                                }
                            }) {
                                SottoIconView(
                                    .noteAlt,
                                    size: 16,
                                    tint: showPostResolutionPrompt ? palette.accent : palette.textSecondary
                                )
                                .frame(width: 34, height: 34)
                                .background(showPostResolutionPrompt ? palette.accent.opacity(0.18) : Color.clear)
                                .cornerRadius(8)
                            }
                            .accessibilityLabel(isIndonesian ? "Catat pemicu" : "Log trigger")
                            .accessibilityAddTraits(showPostResolutionPrompt ? [.isSelected, .isButton] : [.isButton])
                        }
                        
                        Button(action: {
                            UsabilityTracker.shared.startIntent("partner_tool")
                            UsabilityTracker.shared.endIntent(
                                "partner_tool",
                                outcome: "flip",
                                voiceSettings: voiceSettings
                            )
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                                isFlipped.toggle()
                            }
                        }) {
                            SottoIconView(
                                .flipPartner,
                                size: 16,
                                tint: isFlipped ? palette.background : palette.textPrimary
                            )
                            .rotationEffect(.degrees(isFlipped ? 180 : 0))
                            .frame(width: 34, height: 34)
                            .background(isFlipped ? palette.accent : Color.clear)
                            .cornerRadius(8)
                        }
                        .accessibilityLabel(
                            isFlipped
                                ? LocaleHelper.getTwoWayActionLabel(actionKey: "flip_back", appLanguage: appLanguage)
                                : LocaleHelper.getTwoWayActionLabel(actionKey: "flip", appLanguage: appLanguage)
                        )
                        .accessibilityAddTraits(isFlipped ? [.isSelected, .isButton] : [.isButton])
                    }
                    .padding(2)
                    .background(palette.surfaceVariant)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(palette.outlineVariant, lineWidth: 1)
                    )
                    
                    // Standalone Modal Dismissal (36pt visual, 44pt touch area)
                    Button(action: {
                        UsabilityTracker.shared.startIntent("partner_tool")
                        UsabilityTracker.shared.endIntent(
                            "partner_tool",
                            outcome: "close",
                            voiceSettings: voiceSettings
                        )
                        onDismiss()
                    }) {
                        SottoIconView(
                            .close,
                            size: 16,
                            tint: palette.textSecondary
                        )
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(isIndonesian ? "Tutup" : "Dismiss")
                }
            }
            
            // Line 2: Mode Actions (Asymmetric Dock & ViewThatFits Collapse)
            GeometryReader { geo in
                let availableWidth = geo.size.width
                if activeTab == .whyFinder {
                    let buttonCount: CGFloat = canStepBack ? 3 : 2
                    let spacing: CGFloat = 8
                    let btnWidth = max(44, (availableWidth - spacing * (buttonCount - 1)) / buttonCount)
                    
                    HStack(spacing: spacing) {
                        // Speak prompt
                        Button(action: {
                            UsabilityTracker.shared.startIntent("caregiver_action")
                            UsabilityTracker.shared.endIntent(
                                "caregiver_action",
                                outcome: "speak",
                                voiceSettings: voiceSettings
                            )
                            onSpeakPrompt()
                        }) {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 4) {
                                    SottoIconView(.volumeUp, size: 16, tint: palette.textPrimary)
                                    Text(LocaleHelper.getTwoWayActionLabel(actionKey: "speak", appLanguage: appLanguage))
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 4)
                                
                                SottoIconView(.volumeUp, size: 18, tint: palette.textPrimary)
                            }
                            .foregroundColor(palette.textPrimary)
                            .frame(width: btnWidth, height: 44)
                            .background(palette.surfaceVariant)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(palette.outlineVariant, lineWidth: 1)
                            )
                        }
                        .disabled(!canSpeakPrompt)
                        .opacity(canSpeakPrompt ? 1.0 : 0.4)
                        .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: "speak", appLanguage: appLanguage))
                        
                        // Pick card
                        Button(action: {
                            UsabilityTracker.shared.startIntent("caregiver_action")
                            UsabilityTracker.shared.endIntent(
                                "caregiver_action",
                                outcome: "cards",
                                voiceSettings: voiceSettings
                            )
                            onPickCard()
                        }) {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 4) {
                                    SottoIconView(.cards, size: 16, tint: palette.textPrimary)
                                    Text(LocaleHelper.getTwoWayActionLabel(actionKey: "cards", appLanguage: appLanguage))
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 4)
                                
                                SottoIconView(.cards, size: 18, tint: palette.textPrimary)
                            }
                            .foregroundColor(palette.textPrimary)
                            .frame(width: btnWidth, height: 44)
                            .background(palette.surfaceVariant)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(palette.outlineVariant, lineWidth: 1)
                            )
                        }
                        .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: "cards", appLanguage: appLanguage))
                        
                        // Step back
                        if canStepBack {
                            Button(action: {
                                UsabilityTracker.shared.startIntent("caregiver_action")
                                UsabilityTracker.shared.endIntent(
                                    "caregiver_action",
                                    outcome: "back",
                                    voiceSettings: voiceSettings
                                )
                                onStepBack()
                            }) {
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: 4) {
                                        SottoIconView(.replay, size: 16, tint: palette.textPrimary)
                                        Text(LocaleHelper.getTwoWayActionLabel(actionKey: "back", appLanguage: appLanguage))
                                            .font(.system(size: 13, weight: .semibold))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 4)
                                    
                                    SottoIconView(.replay, size: 18, tint: palette.textPrimary)
                                }
                                .foregroundColor(palette.textPrimary)
                                .frame(width: btnWidth, height: 44)
                                .background(palette.surfaceVariant)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(palette.outlineVariant, lineWidth: 1)
                                )
                            }
                            .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: "back", appLanguage: appLanguage))
                        }
                    }
                } else {
                    // Talk tab: Asymmetric Dock (Speak, Cards, Hero Listen (1.5x), Type)
                    let spacing: CGFloat = 6
                    let unitWidth = max(44, (availableWidth - spacing * 3) / 4.5)
                    let heroWidth = unitWidth * 1.5
                    let companionWidth = unitWidth
                    
                    HStack(spacing: spacing) {
                        // Companion 1: Speak
                        Button(action: {
                            UsabilityTracker.shared.startIntent("caregiver_action")
                            UsabilityTracker.shared.endIntent(
                                "caregiver_action",
                                outcome: "speak",
                                voiceSettings: voiceSettings
                            )
                            onSpeakPrompt()
                        }) {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 4) {
                                    SottoIconView(.volumeUp, size: 16, tint: palette.textPrimary)
                                    Text(LocaleHelper.getTwoWayActionLabel(actionKey: "speak", appLanguage: appLanguage))
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 2)
                                
                                SottoIconView(.volumeUp, size: 18, tint: palette.textPrimary)
                            }
                            .foregroundColor(palette.textPrimary)
                            .frame(width: companionWidth, height: 44)
                            .background(palette.surfaceVariant)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(palette.outlineVariant, lineWidth: 1)
                            )
                        }
                        .disabled(!canSpeakPrompt)
                        .opacity(canSpeakPrompt ? 1.0 : 0.4)
                        .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: "speak", appLanguage: appLanguage))
                        
                        // Companion 2: Cards
                        Button(action: {
                            UsabilityTracker.shared.startIntent("caregiver_action")
                            UsabilityTracker.shared.endIntent(
                                "caregiver_action",
                                outcome: "cards",
                                voiceSettings: voiceSettings
                            )
                            onPickCard()
                        }) {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 4) {
                                    SottoIconView(.cards, size: 16, tint: palette.textPrimary)
                                    Text(LocaleHelper.getTwoWayActionLabel(actionKey: "cards", appLanguage: appLanguage))
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 2)
                                
                                SottoIconView(.cards, size: 18, tint: palette.textPrimary)
                            }
                            .foregroundColor(palette.textPrimary)
                            .frame(width: companionWidth, height: 44)
                            .background(palette.surfaceVariant)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(palette.outlineVariant, lineWidth: 1)
                            )
                        }
                        .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: "cards", appLanguage: appLanguage))
                        
                        // HERO: Listen / Mic (weight 1.5x)
                        Button(action: {
                            UsabilityTracker.shared.startIntent("caregiver_action")
                            UsabilityTracker.shared.endIntent(
                                "caregiver_action",
                                outcome: "listen",
                                voiceSettings: voiceSettings
                            )
                            onToggleListening()
                        }) {
                            let heroLabel = LocaleHelper.getTwoWayActionLabel(actionKey: isListening ? "stop" : "mic", appLanguage: appLanguage)
                            let heroBg = isListening ? SottoTheme.recordingPulseRed : palette.accent
                            let heroContentColor = isListening ? Color.white : palette.background
                            
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 4) {
                                    SottoIconView(isListening ? .stop : .mic, size: 16, tint: heroContentColor)
                                    Text(heroLabel)
                                        .font(.system(size: 13, weight: .bold))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 4)
                                
                                SottoIconView(isListening ? .stop : .mic, size: 18, tint: heroContentColor)
                            }
                            .foregroundColor(heroContentColor)
                            .frame(width: heroWidth, height: 44)
                            .background(heroBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isListening ? SottoTheme.recordingDotRed : palette.accent, lineWidth: 1)
                            )
                        }
                        .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: isListening ? "stop" : "mic", appLanguage: appLanguage))
                        
                        // Companion 3: Type
                        Button(action: {
                            UsabilityTracker.shared.startIntent("caregiver_action")
                            UsabilityTracker.shared.endIntent(
                                "caregiver_action",
                                outcome: "type",
                                voiceSettings: voiceSettings
                            )
                            onToggleKeyboard()
                        }) {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 4) {
                                    SottoIconView(.keyboard, size: 16, tint: palette.textPrimary)
                                    Text(LocaleHelper.getTwoWayActionLabel(actionKey: "type", appLanguage: appLanguage))
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 2)
                                
                                SottoIconView(.keyboard, size: 18, tint: palette.textPrimary)
                            }
                            .foregroundColor(palette.textPrimary)
                            .frame(width: companionWidth, height: 44)
                            .background(palette.surfaceVariant)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(palette.outlineVariant, lineWidth: 1)
                            )
                        }
                        .accessibilityLabel(LocaleHelper.getTwoWayActionLabel(actionKey: "type", appLanguage: appLanguage))
                    }
                }
            }
            .frame(height: 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(palette.surface.opacity(0.92))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(palette.outlineVariant.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

// MARK: - Upright Caregiver Mirror HUD (Facing Caregiver across table when flipped 180°)

private struct CaregiverMirrorHUD: View {
    @Environment(\.sottoPalette) private var palette
    let activeTab: CaregiverTab
    let whyState: WhyFinderState
    let currentPrompt: String
    let lastReply: String?
    let appLanguage: String
    let onRestartWhyTree: () -> Void
    let onDone: () -> Void
    
    private var isIndonesian: Bool {
        LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage) == LocaleHelper.langIndonesian
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if activeTab == .whyFinder, case .finished(let outcome, _, let cause, _, _, _, _, _) = whyState {
                let outcomeLabel: String = {
                    switch outcome {
                    case .found:
                        let prefix = isIndonesian ? "Penyebab Ditemukan" : "Cause Found"
                        return cause != nil ? "\(prefix): \(cause!)" : prefix
                    case .stopped:
                        return isIndonesian ? "Dihentikan Sementara" : "Stopped for Now"
                    case .notFound:
                        return isIndonesian ? "Penyebab Belum Ditemukan" : "Could Not Pinpoint Cause"
                    }
                }()
                
                Text(outcomeLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: onRestartWhyTree) {
                    Text(isIndonesian ? "Ulangi" : "Restart")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(palette.surface)
                        .cornerRadius(8)
                }
                
                Button(action: onDone) {
                    Text(isIndonesian ? "Selesai" : "Done")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(SottoTheme.onPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(palette.accent)
                        .cornerRadius(8)
                }
            } else {
                Image(systemName: activeTab == .whyFinder ? "questionmark.circle.fill" : "person.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(palette.accent)
                
                Text(currentPrompt.isEmpty ? (isIndonesian ? "Mode dengar aktif..." : "Listening...") : currentPrompt)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(palette.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let reply = lastReply, !reply.isEmpty {
                    Text(reply)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(SottoTheme.successText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(SottoTheme.successContainer)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(palette.surfaceVariant)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(palette.outlineVariant.opacity(0.5), lineWidth: 1)
        )
    }
}

