import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Target Registry for Pixel-Perfect Coordinates

public final class DemoTargetRegistry {
    public static let shared = DemoTargetRegistry()
    private var targets: [String: CGRect] = [:]
    private let lock = NSLock()
    private let logPath = "/tmp/sotto_targets.log"
    
    public func register(id: String, frame: CGRect) {
        lock.lock()
        defer { lock.unlock() }
        targets[id] = frame
        let line = "\(id): origin=(\(Int(frame.origin.x)),\(Int(frame.origin.y))) size=(\(Int(frame.size.width)),\(Int(frame.size.height))) center=(\(Int(frame.midX)),\(Int(frame.midY)))\n"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let handle = FileHandle(forWritingAtPath: logPath) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
    }
    
    public func center(for id: String) -> CGPoint? {
        lock.lock()
        defer { lock.unlock() }
        guard let rect = targets[id], rect.width > 0, rect.height > 0 else { return nil }
        return CGPoint(x: rect.midX, y: rect.midY)
    }
}

public struct DemoTargetModifier: ViewModifier {
    let id: String
    
    public func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        DemoTargetRegistry.shared.register(id: id, frame: geo.frame(in: .global))
                    }
                    .onChange(of: geo.frame(in: .global)) { newFrame in
                        DemoTargetRegistry.shared.register(id: id, frame: newFrame)
                    }
            }
        )
    }
}

extension View {
    public func demoTarget(_ id: String) -> some View {
        self.modifier(DemoTargetModifier(id: id))
    }
}

// MARK: - Automation Runner

public final class DemoAutomationRunner: ObservableObject {
    public static let shared = DemoAutomationRunner()
    
    @Published public var touchPosition: CGPoint? = nil
    @Published public var isTouching: Bool = false
    @Published public var isRunning: Bool = false
    
    private var startTime: TimeInterval = 0
    private let eventsFilePath = "/tmp/sotto_demo_events.txt"
    private let triggerFilePath = "/tmp/sotto_start_demo.txt"
    private var overlayWindow: Any?
    
    public var isDemoRequested: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("--demo-flow-en") || args.contains("--demo-flow-id")
    }
    
    public var isScreenshotRequested: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("--screenshot-main") ||
               args.contains("--screenshot-triage") ||
               args.contains("--screenshot-whyfinder") ||
               args.contains("--screenshot-whylog") ||
               args.contains("--screenshot-safety") ||
               args.contains("--screenshot-settings") ||
               args.contains("--capture-screenshots")
    }
    
    public var isIndonesian: Bool {
        ProcessInfo.processInfo.arguments.contains("--demo-flow-id")
    }
    
    public func logEvent(_ name: String) {
        let elapsed = Date().timeIntervalSince1970 - startTime
        let line = String(format: "%@:%.3f\n", name, elapsed)
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: eventsFilePath) {
                if let fileHandle = FileHandle(forWritingAtPath: eventsFilePath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: eventsFilePath))
            }
        }
    }
    
    public func startScreenshotCapture(viewModel: MainViewModel) {
        setupScreenshotState(viewModel: viewModel)
        let args = ProcessInfo.processInfo.arguments
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if args.contains("--screenshot-triage") || args.contains("--screenshot-whyfinder") {
                viewModel.showTwoWayDialog = true
            } else if args.contains("--screenshot-whylog") {
                viewModel.showWhyLogDialog = true
            } else if args.contains("--screenshot-safety") {
                if let emergency = viewModel.phrases.first(where: { $0.isEmergency }) {
                    viewModel.activeFullscreenPhrase = emergency
                }
            } else if args.contains("--screenshot-settings") {
                viewModel.showVoiceSettingsDialog = true
            }
        }
    }
    
    private func setupScreenshotState(viewModel: MainViewModel) {
        viewModel.voiceSettings.appLanguage = "en"
        viewModel.voiceSettings.playAttentionChime = false
        viewModel.voiceSettings.showLanguageSwitcher = false
        viewModel.voiceSettings.secondaryLanguage = "id"
        viewModel.phrases = [
            Phrase(text: "I cannot speak right now. Please read my screen.", language: "auto", isEmergency: true, category: .emergency),
            Phrase(text: "Please give me time.", language: "auto", isEmergency: false, category: .needs),
            Phrase(text: "I need a quiet space.", spokenText: "Saya butuh tempat tenang.", spokenLanguage: "id", language: "auto", isEmergency: false, category: .needs),
            Phrase(text: "I need to leave now.", language: "auto", isEmergency: false, category: .needs),
            Phrase(text: "Yes, please.", language: "auto", isEmergency: false, category: .social),
            Phrase(text: "No, thank you.", language: "auto", isEmergency: false, category: .social),
            Phrase(text: "Thank you.", language: "auto", isEmergency: false, category: .social),
            Phrase(text: "Are you in pain?", language: "auto", isEmergency: false, category: .care),
            Phrase(text: "Do you need water or food?", language: "auto", isEmergency: false, category: .care),
            Phrase(text: "Do you need the restroom?", language: "auto", isEmergency: false, category: .care),
            Phrase(text: "Are you feeling cold or warm?", language: "auto", isEmergency: false, category: .care),
            Phrase(text: "Do you want to rest or sleep?", language: "auto", isEmergency: false, category: .care),
            Phrase(text: "Hello.", language: "auto", isEmergency: false, category: .general),
            Phrase(text: "Please repeat that.", language: "auto", isEmergency: false, category: .general)
        ]
        viewModel.selectedCategory = .all
        viewModel.isEditMode = false
        viewModel.activeFullscreenPhrase = nil
        viewModel.showVoiceSettingsDialog = false
        viewModel.showTwoWayDialog = false
        viewModel.showWhyLogDialog = false
        viewModel.quickText = ""
    }
    
    public func startDemo(viewModel: MainViewModel, size: CGSize) {
        guard !isRunning && isDemoRequested else { return }
        isRunning = true
        
        // Remove old events and trigger file if any
        try? FileManager.default.removeItem(atPath: eventsFilePath)
        try? FileManager.default.removeItem(atPath: "/tmp/sotto_targets.log")
        
        // Setup initial demo state matching Android
        setupInitialState(viewModel: viewModel)
        
        Task { @MainActor in
            #if canImport(UIKit)
            if let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
                let window = UIWindow(windowScene: windowScene)
                window.windowLevel = .alert + 1000
                let hosting = UIHostingController(rootView: DemoTouchOverlay(runner: self))
                hosting.view.backgroundColor = .clear
                window.rootViewController = hosting
                window.isHidden = false
                window.isUserInteractionEnabled = false
                self.overlayWindow = window
            }
            #endif
            
            // Wait for video recording to start via trigger file
            print("DemoAutomationRunner: Waiting for trigger file at \(triggerFilePath)...")
            var triggerReceived = false
            for _ in 0..<300 { // up to 30 seconds
                if FileManager.default.fileExists(atPath: triggerFilePath) {
                    if let content = try? String(contentsOfFile: triggerFilePath, encoding: .utf8),
                       let epoch = Double(content.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        startTime = epoch
                    } else {
                        startTime = Date().timeIntervalSince1970
                    }
                    triggerReceived = true
                    print("DemoAutomationRunner: Trigger received! Start epoch: \(startTime)")
                    break
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            
            if !triggerReceived {
                print("DemoAutomationRunner: No trigger received, starting with current time.")
                startTime = Date().timeIntervalSince1970
            }
            
            await runFlow(viewModel: viewModel, size: size)
        }
    }
    
    private func setupInitialState(viewModel: MainViewModel) {
        if isIndonesian {
            viewModel.voiceSettings.appLanguage = "id"
            viewModel.voiceSettings.playAttentionChime = false
            viewModel.voiceSettings.showLanguageSwitcher = false
            viewModel.voiceSettings.secondaryLanguage = "en"
            viewModel.phrases = [
                Phrase(text: "Saya tidak bisa bicara sekarang. Tolong baca layar saya.", language: "auto", isEmergency: true, category: .emergency),
                Phrase(text: "Tolong beri saya waktu.", language: "auto", isEmergency: false, category: .needs),
                Phrase(text: "Saya butuh tempat tenang.", spokenText: "I need a quiet space.", spokenLanguage: "en", language: "auto", isEmergency: false, category: .needs),
                Phrase(text: "Saya harus pergi sekarang.", language: "auto", isEmergency: false, category: .needs),
                Phrase(text: "Ya, silakan.", language: "auto", isEmergency: false, category: .social),
                Phrase(text: "Tidak, terima kasih.", language: "auto", isEmergency: false, category: .social),
                Phrase(text: "Terima kasih.", language: "auto", isEmergency: false, category: .social),
                Phrase(text: "Halo.", language: "auto", isEmergency: false, category: .general),
                Phrase(text: "Tolong ulangi.", language: "auto", isEmergency: false, category: .general)
            ]
        } else {
            viewModel.voiceSettings.appLanguage = "en"
            viewModel.voiceSettings.playAttentionChime = false
            viewModel.voiceSettings.showLanguageSwitcher = false
            viewModel.voiceSettings.secondaryLanguage = "id"
            viewModel.phrases = [
                Phrase(text: "I cannot speak right now. Please read my screen.", language: "auto", isEmergency: true, category: .emergency),
                Phrase(text: "Please give me time.", language: "auto", isEmergency: false, category: .needs),
                Phrase(text: "I need a quiet space.", spokenText: "Saya butuh tempat tenang.", spokenLanguage: "id", language: "auto", isEmergency: false, category: .needs),
                Phrase(text: "I need to leave now.", language: "auto", isEmergency: false, category: .needs),
                Phrase(text: "Yes, please.", language: "auto", isEmergency: false, category: .social),
                Phrase(text: "No, thank you.", language: "auto", isEmergency: false, category: .social),
                Phrase(text: "Thank you.", language: "auto", isEmergency: false, category: .social),
                Phrase(text: "Hello.", language: "auto", isEmergency: false, category: .general),
                Phrase(text: "Please repeat that.", language: "auto", isEmergency: false, category: .general)
            ]
        }
        viewModel.selectedCategory = .all
        viewModel.isEditMode = false
        viewModel.activeFullscreenPhrase = nil
        viewModel.showVoiceSettingsDialog = false
        viewModel.quickText = ""
        viewModel.activeSpeechTarget = "primary"
    }
    
    private func targetCenter(_ id: String, fallback: CGPoint) -> CGPoint {
        DemoTargetRegistry.shared.center(for: id) ?? fallback
    }
    
    @MainActor
    private func runFlow(viewModel: MainViewModel, size: CGSize) async {
        let w = size.width
        let h = size.height
        
        let quickSpeakPhrase = isIndonesian ? "Tolong beri saya waktu." : "I need a moment, please"
        let speakEvent1 = isIndonesian ? "speak_waktu_1" : "speak_moment_1"
        let speakEvent2 = isIndonesian ? "speak_waktu_2" : "speak_moment_2"
        let emergencyEvent = isIndonesian ? "speak_darurat" : "speak_emergency"
        
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // ==================== SCENE 1: Instant Quick Speak ====================
        // Move to Quick Speak text field
        let textFieldPos = targetCenter("quickSpeak_textField", fallback: CGPoint(x: w * 0.35, y: h - 65))
        await animateMove(to: textFieldPos, duration: 0.6)
        await performTap()
        
        // Type characters
        for char in quickSpeakPhrase {
            viewModel.quickText.append(char)
            try? await Task.sleep(nanoseconds: 40_000_000)
        }
        try? await Task.sleep(nanoseconds: 700_000_000)
        
        // Tap 🔊 Speak button
        let speakBtnPos = targetCenter("quickSpeak_speakButton", fallback: CGPoint(x: w - 36, y: h - 65))
        await animateMove(to: speakBtnPos, duration: 0.5)
        await performTapWithEvent(speakEvent1) {
            viewModel.speakQuickText(viewModel.quickText)
        }
        try? await Task.sleep(nanoseconds: 2_400_000_000)
        
        // ==================== SCENE 2: Large Visual Presentation Mode ====================
        // Tap ⛶ Fullscreen button
        let fullscreenBtnPos = targetCenter("quickSpeak_fullscreenButton", fallback: CGPoint(x: w - 84, y: h - 65))
        await animateMove(to: fullscreenBtnPos, duration: 0.5)
        await performTap()
        viewModel.activeFullscreenPhrase = Phrase(text: viewModel.quickText, language: LocaleHelper.langAuto)
        try? await Task.sleep(nanoseconds: 600_000_000) // Wait for modal animation
        
        // Tap Speak Aloud button in fullscreen modal
        let modalSpeakBtnPos = targetCenter("fullscreen_speakButton", fallback: CGPoint(x: w / 2, y: h - 100))
        await animateMove(to: modalSpeakBtnPos, duration: 0.5)
        await performTapWithEvent(speakEvent2) {
            viewModel.speakText(viewModel.quickText)
        }
        try? await Task.sleep(nanoseconds: 2_400_000_000)
        
        // Dismiss fullscreen modal (Tap close button at top-right)
        let modalDismissPos = targetCenter("fullscreen_dismissButton", fallback: CGPoint(x: w - 36, y: 65))
        await animateMove(to: modalDismissPos, duration: 0.5)
        await performTap()
        viewModel.activeFullscreenPhrase = nil
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // ==================== SCENE 3: Phrase Categories & Emergency ====================
        // Tap "Needs" / "Kebutuhan"
        let needsChipPos = targetCenter("chip_Needs", fallback: CGPoint(x: 180, y: 105))
        await animateMove(to: needsChipPos, duration: 0.5)
        await performTap()
        viewModel.selectedCategory = .needs
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        
        // Tap "Social" / "Sosial"
        let socialChipPos = targetCenter("chip_Social", fallback: CGPoint(x: 270, y: 105))
        await animateMove(to: socialChipPos, duration: 0.5)
        await performTap()
        viewModel.selectedCategory = .social
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        
        // Tap "Emergency" / "Darurat"
        let emergencyChipPos = targetCenter("chip_Emergency", fallback: CGPoint(x: 100, y: 105))
        await animateMove(to: emergencyChipPos, duration: 0.5)
        await performTap()
        viewModel.selectedCategory = .emergency
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        
        // Long-press emergency card to open full-screen emergency
        let emergencyCardPos = targetCenter("emergencyCard", fallback: CGPoint(x: w / 2, y: 200))
        await animateMove(to: emergencyCardPos, duration: 0.5)
        await performLongPress()
        if let emergencyPhrase = viewModel.phrases.first(where: { $0.isEmergency }) {
            viewModel.activeFullscreenPhrase = emergencyPhrase
        }
        try? await Task.sleep(nanoseconds: 600_000_000) // Wait for modal
        
        // Tap Speak Aloud button in emergency fullscreen
        let emergModalSpeakPos = targetCenter("fullscreen_speakButton", fallback: CGPoint(x: w / 2, y: h - 100))
        await animateMove(to: emergModalSpeakPos, duration: 0.5)
        await performTapWithEvent(emergencyEvent) {
            if let emergencyPhrase = viewModel.phrases.first(where: { $0.isEmergency }) {
                viewModel.speak(phrase: emergencyPhrase)
            }
        }
        try? await Task.sleep(nanoseconds: 3_600_000_000)
        
        // Dismiss emergency modal
        let emergModalDismissPos = targetCenter("fullscreen_dismissButton", fallback: CGPoint(x: w - 36, y: 65))
        await animateMove(to: emergModalDismissPos, duration: 0.4)
        await performTap()
        viewModel.activeFullscreenPhrase = nil
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // Return to "All" / "Semua"
        let allChipPos = targetCenter("chip_ALL", fallback: CGPoint(x: 45, y: 105))
        await animateMove(to: allChipPos, duration: 0.5)
        await performTap()
        viewModel.selectedCategory = .all
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // ==================== SCENE 4: Voice Customization & Dual-Language Enable ====================
        // Tap "Edit"
        let editBtnPos = targetCenter("topBar_editButton", fallback: CGPoint(x: w - 50, y: 60))
        await animateMove(to: editBtnPos, duration: 0.5)
        await performTap()
        viewModel.isEditMode = true
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        // Tap "Voice" button in edit mode
        let voiceBtnPos = targetCenter("topBar_voiceButton", fallback: CGPoint(x: w - 105, y: 60))
        await animateMove(to: voiceBtnPos, duration: 0.5)
        await performTap()
        viewModel.showVoiceSettingsDialog = true
        try? await Task.sleep(nanoseconds: 800_000_000) // Wait for sheet animation
        
        // Tap "Attention chime before speaking" switch
        let chimeSwitchPos = targetCenter("voice_chimeToggle", fallback: CGPoint(x: w - 55, y: h * 0.40))
        await animateMove(to: chimeSwitchPos, duration: 0.5)
        await performTap()
        viewModel.voiceSettings.playAttentionChime.toggle()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Tap "Test Voice" button
        let testVoicePos = targetCenter("voice_testVoiceButton", fallback: CGPoint(x: w / 2, y: h * 0.48))
        await animateMove(to: testVoicePos, duration: 0.5)
        await performTapWithEvent("test_voice") {
            viewModel.testVoice(with: viewModel.voiceSettings)
        }
        try? await Task.sleep(nanoseconds: 3_200_000_000)
        
        // Enable Dual-Language Speech toggle
        let dualLangTogglePos = targetCenter("voice_dualLanguageToggle", fallback: CGPoint(x: w - 55, y: h * 0.60))
        await animateMove(to: dualLangTogglePos, duration: 0.5)
        await performTap()
        viewModel.voiceSettings.showLanguageSwitcher = true
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        // Dismiss Voice Settings modal (Tap Done button at top-right of sheet)
        let voiceDonePos = targetCenter("voice_doneButton", fallback: CGPoint(x: w - 40, y: h * 0.15))
        await animateMove(to: voiceDonePos, duration: 0.4)
        await performTap()
        viewModel.showVoiceSettingsDialog = false
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // ==================== SCENE 5: Dual-Language Speech in Action ====================
        // Tap Language Switcher pill in Top Bar to switch to secondary language
        let langSwitchSecPos = targetCenter("langSwitch_secondary", fallback: CGPoint(x: w - 150, y: 60))
        await animateMove(to: langSwitchSecPos, duration: 0.5)
        await performTap()
        viewModel.activeSpeechTarget = "secondary"
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        
        // Tap "Done" to exit edit mode
        let doneBtnPos = targetCenter("topBar_doneButton", fallback: CGPoint(x: w - 45, y: 60))
        await animateMove(to: doneBtnPos, duration: 0.5)
        await performTap()
        viewModel.isEditMode = false
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Open the Dual-Language card in fullscreen modal
        let dualCardPos = targetCenter("dualLanguageCard", fallback: CGPoint(x: w * 0.28, y: 320))
        await animateMove(to: dualCardPos, duration: 0.5)
        await performLongPress()
        if let dualPhrase = viewModel.phrases.first(where: { $0.spokenText != nil }) {
            viewModel.activeFullscreenPhrase = dualPhrase
        }
        try? await Task.sleep(nanoseconds: 800_000_000) // Wait for modal
        
        // In Fullscreen Modal:
        // 1. Tap Speak (Secondary) button -> speaks in secondary language!
        let speakSecBtnPos = targetCenter("fullscreen_speakSecondary", fallback: CGPoint(x: w * 0.72, y: h - 100))
        await animateMove(to: speakSecBtnPos, duration: 0.5)
        await performTapWithEvent("speak_dual_secondary") {
            if let dualPhrase = viewModel.phrases.first(where: { $0.spokenText != nil }),
               let spoken = dualPhrase.spokenText {
                viewModel.speakText(spoken, language: dualPhrase.spokenLanguage ?? viewModel.voiceSettings.secondaryLanguage)
            }
        }
        try? await Task.sleep(nanoseconds: 3_200_000_000)
        
        // 2. Tap Speak (Primary) button -> speaks in primary language!
        let speakPrimBtnPos = targetCenter("fullscreen_speakPrimary", fallback: CGPoint(x: w * 0.28, y: h - 100))
        await animateMove(to: speakPrimBtnPos, duration: 0.5)
        await performTapWithEvent("speak_dual_primary") {
            if let dualPhrase = viewModel.phrases.first(where: { $0.spokenText != nil }) {
                viewModel.speakText(dualPhrase.text, language: dualPhrase.language)
            }
        }
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        // Dismiss fullscreen modal
        await animateMove(to: modalDismissPos, duration: 0.4)
        await performTap()
        viewModel.activeFullscreenPhrase = nil
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Hide touch pointer
        withAnimation(.easeOut(duration: 0.3)) {
            touchPosition = nil
        }
        
        #if canImport(UIKit)
        if let window = self.overlayWindow as? UIWindow {
            window.isHidden = true
            self.overlayWindow = nil
        }
        #endif
        
        logEvent("end")
        print("Demo flow completed successfully.")
        isRunning = false
    }
    
    // MARK: - Touch Animations
    
    @MainActor
    private func animateMove(to target: CGPoint, duration: Double) async {
        let steps = 20
        let stepDuration = duration / Double(steps)
        let current = touchPosition ?? target
        
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let ease = t < 0.5 ? 2.0 * t * t : -1.0 + (4.0 - 2.0 * t) * t
            let nextX = current.x + (target.x - current.x) * CGFloat(ease)
            let nextY = current.y + (target.y - current.y) * CGFloat(ease)
            touchPosition = CGPoint(x: nextX, y: nextY)
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
        touchPosition = target
    }
    
    @MainActor
    private func performTap() async {
        withAnimation(.easeInOut(duration: 0.12)) {
            isTouching = true
        }
        try? await Task.sleep(nanoseconds: 120_000_000)
        withAnimation(.easeOut(duration: 0.15)) {
            isTouching = false
        }
        try? await Task.sleep(nanoseconds: 150_000_000)
    }
    
    @MainActor
    private func performTapWithEvent(_ eventName: String, action: () -> Void) async {
        withAnimation(.easeInOut(duration: 0.12)) {
            isTouching = true
        }
        logEvent(eventName)
        action()
        try? await Task.sleep(nanoseconds: 120_000_000)
        withAnimation(.easeOut(duration: 0.15)) {
            isTouching = false
        }
        try? await Task.sleep(nanoseconds: 150_000_000)
    }
    
    @MainActor
    private func performLongPress() async {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTouching = true
        }
        try? await Task.sleep(nanoseconds: 700_000_000)
        withAnimation(.easeOut(duration: 0.2)) {
            isTouching = false
        }
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
}

// MARK: - Touch Overlay View

public struct DemoTouchOverlay: View {
    @ObservedObject var runner: DemoAutomationRunner
    
    public init(runner: DemoAutomationRunner = .shared) {
        self.runner = runner
    }
    
    public var body: some View {
        GeometryReader { _ in
            if let pos = runner.touchPosition {
                ZStack {
                    // Outer ripple during touch
                    if runner.isTouching {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 56, height: 56)
                            .scaleEffect(1.2)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Touch pointer circle
                    Circle()
                        .fill(Color.white.opacity(runner.isTouching ? 0.85 : 0.65))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
                        .scaleEffect(runner.isTouching ? 0.9 : 1.0)
                }
                .position(pos)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.15), value: runner.isTouching)
            }
        }
        .ignoresSafeArea()
    }
}
