import Foundation
import Network

/// Lightweight, privacy-preserving usability metrics tracker for Sotto iOS (Telemetry v2).
/// Strictly collects anonymous interaction durations, rapid-tap signals, and intent completions.
/// Strictly NEVER collects user-typed text, phrase content, or audio recordings.
public final class UsabilityTracker {
    public static let shared = UsabilityTracker()

    public static let defaultWebhookURL =
        "https://script.google.com/macros/s/AKfycbyvnBbI2WBF4UhSoZc-kb9AIbh3-ofDdzwleyUmTFeujYePSLqeAJbR28C_OdvXamHn/exec"

    public static let maxBufferSize = 500
    private let rapidTapThresholdNs: UInt64 = 350_000_000 // 350ms
    private let hesitationThresholdMs: Int = 10_000 // 10s

    public let sessionId: String = String(UUID().uuidString.prefix(8)).lowercased()

    private let queue = DispatchQueue(label: "com.sotto.usabilityTracker", qos: .utility)
    private var activeIntents: [String: DispatchTime] = [:]
    private var eventBuffer: [UsabilityEvent] = []

    private var lastTapTime: DispatchTime = .now()
    private var lastTapTarget: String = ""

    private let pathMonitor = NWPathMonitor()
    private var isWifiConnected: Bool = false
    
    private var lastAppOpenDay: String = ""
    private var lastAppOpenHour: Int = -1
    private var recordedActivations: Set<String> = []

    private var inMemoryTapCounts: [String: Int] = [:]
    private var inMemoryAggDay: String? = nil
    private var inMemoryAggHour: Int = -1

    public struct UsabilityEvent: Codable, Equatable {
        public let intent: String
        public let durationMs: Int
        public let outcome: String
        public let frictionTag: String
        public let contextTag: String
        public let day: String
        public let hourBucket: Int

        public init(
            intent: String,
            durationMs: Int,
            outcome: String,
            frictionTag: String = "none",
            contextTag: String = "",
            day: String = UsabilityTracker.getTodayDate(),
            hourBucket: Int = UsabilityTracker.getCurrentHourBucket()
        ) {
            self.intent = intent
            self.durationMs = durationMs
            self.outcome = outcome
            self.frictionTag = frictionTag
            self.contextTag = contextTag
            self.day = day
            self.hourBucket = hourBucket
        }

        public func toJsonArray() -> [Any] {
            return [intent, durationMs, outcome, frictionTag, contextTag, day, hourBucket]
        }

        public static func fromJsonArray(_ arr: [Any]) -> UsabilityEvent? {
            guard arr.count >= 7,
                  let intent = arr[0] as? String,
                  let outcome = arr[2] as? String else {
                return nil
            }
            let durationMs = (arr[1] as? NSNumber)?.intValue ?? 0
            let frictionTag = (arr[3] as? String) ?? "none"
            let contextTag = (arr[4] as? String) ?? ""
            let day = (arr[5] as? String) ?? getTodayDate()
            let hourBucket = (arr[6] as? NSNumber)?.intValue ?? getCurrentHourBucket()
            return UsabilityEvent(
                intent: intent,
                durationMs: durationMs,
                outcome: outcome,
                frictionTag: frictionTag,
                contextTag: contextTag,
                day: day,
                hourBucket: hourBucket
            )
        }
    }

    public static func getTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    public static func getCurrentHourBucket() -> Int {
        let hour = Calendar.current.component(.hour, from: Date())
        return min(max(hour / 4, 0), 5)
    }

    private init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.isWifiConnected = path.usesInterfaceType(.wifi)
        }
        pathMonitor.start(queue: queue)
    }

    deinit {
        pathMonitor.cancel()
    }

    public func startIntent(_ name: String) {
        queue.async {
            self.activeIntents[name] = .now()
        }
    }

    public func endIntent(
        _ name: String,
        outcome: String,
        frictionTag: String = "none",
        contextTag: String = "",
        voiceSettings: VoiceSettings
    ) {
        guard voiceSettings.shareUsabilityMetrics else { return }

        queue.async {
            let startTime = self.activeIntents.removeValue(forKey: name)
            let durationMs: Int
            if let start = startTime {
                let elapsedNs = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
                durationMs = Int(elapsedNs / 1_000_000)
            } else {
                durationMs = 0
            }

            let resolvedFriction = (frictionTag == "none" && durationMs >= self.hesitationThresholdMs) ? "hesitation_high" : frictionTag

            let event = UsabilityEvent(
                intent: name,
                durationMs: durationMs,
                outcome: outcome,
                frictionTag: resolvedFriction,
                contextTag: contextTag
            )
            self.appendAndSync(event, voiceSettings: voiceSettings)
        }
    }

    public static func categoryType(category: String, isEmergency: Bool = false) -> String {
        if isEmergency || category.caseInsensitiveCompare("Emergency") == .orderedSame {
            return "emergency"
        }
        let builtIns = ["needs", "social", "care", "general"]
        let lower = category.lowercased()
        if builtIns.contains(lower) {
            return lower
        }
        return "custom"
    }

    public static func categoryType(_ category: String, isEmergency: Bool = false) -> String {
        categoryType(category: category, isEmergency: isEmergency)
    }

    public func recordCardTap(category: String, phraseId: String, isEmergency: Bool = false, voiceSettings: VoiceSettings) {
        guard voiceSettings.shareUsabilityMetrics else { return }

        queue.async {
            let now = DispatchTime.now()
            let intervalNs = now.uptimeNanoseconds - self.lastTapTime.uptimeNanoseconds
            let isRapid = (phraseId == self.lastTapTarget && intervalNs < self.rapidTapThresholdNs)

            self.lastTapTime = now
            self.lastTapTarget = phraseId

            let catType = Self.categoryType(category: category, isEmergency: isEmergency)

            if isRapid {
                let intervalMs = min(Int(intervalNs / 1_000_000), 30_000)
                let event = UsabilityEvent(
                    intent: "SpeakCard",
                    durationMs: intervalMs,
                    outcome: "rapid_tap",
                    frictionTag: "rapid_clicking",
                    contextTag: "cat_\(catType)"
                )
                self.appendAndSync(event, voiceSettings: voiceSettings)
            } else {
                self.recordAggregatedTap(catType: catType, voiceSettings: voiceSettings)
            }
        }
    }

    private func recordAggregatedTap(catType: String, voiceSettings: VoiceSettings) {
        let today = Self.getTodayDate()
        let currentHour = Self.getCurrentHourBucket()

        if let aggDay = inMemoryAggDay, (aggDay != today || inMemoryAggHour != currentHour) {
            flushAggregatedTapsLocked(voiceSettings: voiceSettings)
        }

        inMemoryAggDay = today
        inMemoryAggHour = currentHour
        inMemoryTapCounts[catType, default: 0] += 1
    }

    public func flushAggregatedTaps(voiceSettings: VoiceSettings) {
        queue.async {
            self.flushAggregatedTapsLocked(voiceSettings: voiceSettings)
        }
    }

    private func flushAggregatedTapsLocked(voiceSettings: VoiceSettings) {
        guard let storedDay = inMemoryAggDay, inMemoryAggHour != -1 else { return }
        let storedHour = inMemoryAggHour
        let categories = ["emergency", "needs", "social", "care", "general", "custom"]
        var nonZeroTags: [String] = []
        for cat in categories {
            let count = inMemoryTapCounts[cat] ?? 0
            if count > 0 {
                nonZeroTags.append("\(cat)=\(count)")
            }
        }

        inMemoryTapCounts.removeAll()
        inMemoryAggDay = nil
        inMemoryAggHour = -1

        if !nonZeroTags.isEmpty {
            let summaryEvent = UsabilityEvent(
                intent: "CardTapsSummary",
                durationMs: 0,
                outcome: "completed",
                frictionTag: "none",
                contextTag: nonZeroTags.joined(separator: ";"),
                day: storedDay,
                hourBucket: storedHour
            )
            appendAndSync(summaryEvent, voiceSettings: voiceSettings)
        }
    }

    public func recordAppOpen(voiceSettings: VoiceSettings) {
        guard voiceSettings.shareUsabilityMetrics else { return }
        queue.async {
            let today = Self.getTodayDate()
            let hourBucket = Self.getCurrentHourBucket()
            if self.lastAppOpenDay != today || self.lastAppOpenHour != hourBucket {
                self.lastAppOpenDay = today
                self.lastAppOpenHour = hourBucket
                let event = UsabilityEvent(
                    intent: "AppOpen",
                    durationMs: 0,
                    outcome: "active",
                    day: today,
                    hourBucket: hourBucket
                )
                self.appendAndSync(event, voiceSettings: voiceSettings)
            }
        }
    }

    public func recordRoleSet(role: String, voiceSettings: VoiceSettings) {
        guard voiceSettings.shareUsabilityMetrics else { return }
        queue.async {
            let event = UsabilityEvent(intent: "RoleSet", durationMs: 0, outcome: role)
            self.appendAndSync(event, voiceSettings: voiceSettings)
        }
    }

    public func recordActivation(key: String, voiceSettings: VoiceSettings) {
        guard voiceSettings.shareUsabilityMetrics else { return }
        queue.async {
            if !self.recordedActivations.contains(key) {
                self.recordedActivations.insert(key)
                let event = UsabilityEvent(intent: "Activation", durationMs: 0, outcome: key)
                self.appendAndSync(event, voiceSettings: voiceSettings)
            }
        }
    }

    public func recordEmergencyShortcutLaunched(target: String, voiceSettings: VoiceSettings) {
        guard voiceSettings.shareUsabilityMetrics else { return }
        queue.async {
            let event = UsabilityEvent(intent: "EmergencyShortcut", durationMs: 0, outcome: target)
            self.appendAndSync(event, voiceSettings: voiceSettings)
        }
        recordActivation(key: "emergency_shortcut_launched", voiceSettings: voiceSettings)
    }

    public func recordSafetyCardSaved(voiceSettings: VoiceSettings) {
        guard voiceSettings.shareUsabilityMetrics else { return }
        queue.async {
            let event = UsabilityEvent(intent: "SafetyCardSetup", durationMs: 0, outcome: "saved")
            self.appendAndSync(event, voiceSettings: voiceSettings)
        }
        recordActivation(key: "safety_card_setup", voiceSettings: voiceSettings)
    }

    public func recordWhyFinder(
        outcome: String,
        areaId: String?,
        depth: Int,
        notSureCount: Int,
        bodyPart: String?,
        intensity: Int?,
        durationMs: Int64,
        voiceSettings: VoiceSettings? = nil
    ) {
        let settings = voiceSettings ?? UserDefaultsVoiceSettingsRepository().getVoiceSettings()
        guard settings.shareUsabilityMetrics else { return }
        queue.async {
            let safeArea: String
            if let areaId = areaId, UserDefaultsWhyFinderRepository.builtInAreas.contains(areaId) {
                safeArea = areaId
            } else if let areaId = areaId, !areaId.isEmpty {
                safeArea = "custom"
            } else {
                safeArea = "none"
            }
            let safePart = bodyPart ?? "none"
            let safeIntensity = intensity?.description ?? "none"

            let event = UsabilityEvent(
                intent: "WhyFinder",
                durationMs: Int(durationMs),
                outcome: outcome,
                contextTag: "area_\(safeArea)_d\(depth)_ns\(notSureCount)_bp_\(safePart)_int_\(safeIntensity)"
            )
            self.appendAndSync(event, voiceSettings: settings)
        }
        recordActivation(key: "why_finder", voiceSettings: settings)
    }

    public func recordWhyLogViewed(count: Int, voiceSettings: VoiceSettings) {
        guard voiceSettings.shareUsabilityMetrics else { return }
        queue.async {
            let bucket: String
            switch count {
            case 0: bucket = "0"
            case 1...5: bucket = "1_5"
            case 6...20: bucket = "6_20"
            default: bucket = "20_plus"
            }
            let event = UsabilityEvent(intent: "WhyLogViewed", durationMs: 0, outcome: bucket)
            self.appendAndSync(event, voiceSettings: voiceSettings)
        }
    }

    public func recordBackupAction(
        isExport: Bool,
        includesPhrases: Bool,
        includesTree: Bool,
        includesLog: Bool,
        isReplace: Bool,
        voiceSettings: VoiceSettings
    ) {
        guard voiceSettings.shareUsabilityMetrics else { return }
        queue.async {
            let intentName = isExport ? "Export" : "Import"
            let p = includesPhrases ? "1" : "0"
            let t = includesTree ? "1" : "0"
            let l = includesLog ? "1" : "0"
            let mode = (!isExport && isReplace) ? "replace" : "merge"
            let event = UsabilityEvent(
                intent: intentName,
                durationMs: 0,
                outcome: mode,
                contextTag: "p\(p)_t\(t)_l\(l)"
            )
            self.appendAndSync(event, voiceSettings: voiceSettings)
        }
    }

    public func recordSurvey(
        pmfScore: String,
        primaryBenefit: String,
        confirmedRole: String,
        voiceSettings: VoiceSettings
    ) {
        guard voiceSettings.shareUsabilityMetrics else { return }
        queue.async {
            let event = UsabilityEvent(
                intent: "Survey",
                durationMs: 0,
                outcome: pmfScore,
                contextTag: "benefit=\(primaryBenefit);role=\(confirmedRole)"
            )
            self.appendAndSync(event, voiceSettings: voiceSettings)
        }
    }

    public func recordThemeSelected(theme: String, voiceSettings: VoiceSettings) {
        guard voiceSettings.shareUsabilityMetrics else { return }
        queue.async {
            let event = UsabilityEvent(intent: "ThemeSelected", durationMs: 0, outcome: theme)
            self.appendAndSync(event, voiceSettings: voiceSettings)
        }
    }

    public func recordSettingsState(settings: VoiceSettings, customPhraseCount: Int) {
        guard settings.shareUsabilityMetrics else { return }
        queue.async {
            let chime = settings.playAttentionChime ? 1 : 0
            let bilingual = settings.showLanguageSwitcher ? 1 : 0
            let secLang = (settings.showLanguageSwitcher && !settings.secondaryLanguage.isEmpty) ? settings.secondaryLanguage : "none"
            let rateBucket: String
            if settings.speechRate < 0.9 { rateBucket = "slow" }
            else if settings.speechRate > 1.1 { rateBucket = "fast" }
            else { rateBucket = "normal" }
            let customBucket: String
            switch customPhraseCount {
            case 0: customBucket = "0"
            case 1...5: customBucket = "1_5"
            case 6...20: customBucket = "6_20"
            default: customBucket = "20_plus"
            }
            let safety = settings.showSafetyCards ? 1 : 0
            let tag = "chime=\(chime);bi=\(bilingual);sec=\(secLang);rate=\(rateBucket);cust=\(customBucket);theme=\(settings.appTheme);safety_cards_visible=\(safety)"
            let event = UsabilityEvent(
                intent: "SettingsState",
                durationMs: 0,
                outcome: "active",
                contextTag: tag
            )
            self.appendAndSync(event, voiceSettings: settings)
        }
    }

    public func getPendingEvents(voiceSettings: VoiceSettings? = nil) -> [UsabilityEvent] {
        return queue.sync {
            if let settings = voiceSettings {
                self.flushAggregatedTapsLocked(voiceSettings: settings)
            }
            return self.eventBuffer
        }
    }

    public static var currentAppVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.6.1"
        return "v\(version)"
    }

    public func generatePreviewPayload(installId: String, role: String, uiLang: String, voiceSettings: VoiceSettings? = nil) -> String {
        let events = getPendingEvents(voiceSettings: voiceSettings)
        let payload: [String: Any] = [
            "schema": 3,
            "installId": installId,
            "role": role,
            "uiLang": uiLang,
            "appVersion": Self.currentAppVersion,
            "platform": "iOS",
            "sessionId": sessionId,
            "eventsCount": events.count,
            "events": events.map { $0.toJsonArray() }
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    public func generatePreviewPayload(voiceSettings: VoiceSettings) -> String {
        let repo = UserDefaultsVoiceSettingsRepository()
        let installId = repo.getInstallId() ?? "not_assigned"
        let uiLang = LocaleHelper.getEffectiveLanguage(appLanguage: LocaleHelper.langSystem)
        return generatePreviewPayload(installId: installId, role: voiceSettings.userRole, uiLang: uiLang, voiceSettings: voiceSettings)
    }

    public func clearBuffer() {
        queue.async {
            self.eventBuffer.removeAll()
            self.inMemoryTapCounts.removeAll()
            self.inMemoryAggDay = nil
            self.inMemoryAggHour = -1
        }
    }

    private func appendAndSync(_ event: UsabilityEvent, voiceSettings: VoiceSettings) {
        if eventBuffer.count >= Self.maxBufferSize {
            eventBuffer.removeFirst()
        }
        eventBuffer.append(event)

        guard isWifiConnected else { return } // Wi-Fi only

        let eventsToSend = eventBuffer
        sendToGoogleSheet(eventsToSend, voiceSettings: voiceSettings)
    }

    private func sendToGoogleSheet(_ events: [UsabilityEvent], voiceSettings: VoiceSettings) {
        guard let url = URL(string: Self.defaultWebhookURL) else { return }

        let payload: [String: Any] = [
            "schema": 3,
            "appVersion": Self.currentAppVersion,
            "platform": "iOS",
            "sessionId": sessionId,
            "role": voiceSettings.userRole,
            "events": events.map { $0.toJsonArray() }
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        request.timeoutInterval = 3.0

        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self, error == nil else { return }
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                self.queue.async {
                    self.eventBuffer.removeAll { sent in
                        events.contains(sent)
                    }
                }
            }
        }
        task.resume()
    }
}
