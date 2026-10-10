import AppIntents
import SwiftUI

// MARK: - Emergency Launch Action & Manager

public final class EmergencyLaunchManager: ObservableObject {
    public static let shared = EmergencyLaunchManager()
    
    public enum Action: String, Equatable {
        case triage
        case safetyCard
    }
    
    @Published public var pendingAction: Action? = nil
    
    public func trigger(_ action: Action) {
        DispatchQueue.main.async {
            self.pendingAction = action
            NotificationCenter.default.post(name: .sottoEmergencyAction, object: action)
        }
    }
}

extension Notification.Name {
    public static let sottoEmergencyAction = Notification.Name("com.sotto.emergencyAction")
}

// MARK: - App Intents (iOS 16+)

@available(iOS 16.0, *)
public struct OpenEmergencyTriageIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Emergency Triage"
    public static var description = IntentDescription("Opens Sotto directly to the Two-Way crisis triage HUD.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        EmergencyLaunchManager.shared.trigger(.triage)
        return .result()
    }
}

@available(iOS 16.0, *)
public struct OpenSafetyCardIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Safety Card"
    public static var description = IntentDescription("Displays your high-contrast bystander safety card fullscreen.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        EmergencyLaunchManager.shared.trigger(.safetyCard)
        return .result()
    }
}

// MARK: - App Shortcuts Provider (Siri, Shortcuts & Action Button)

@available(iOS 16.0, *)
public struct SottoShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenEmergencyTriageIntent(),
            phrases: [
                "Open Emergency Triage in \(.applicationName)",
                "Open \(.applicationName) Emergency",
                "Caregiver Triage in \(.applicationName)"
            ],
            shortTitle: "Emergency Triage",
            systemImageName: "person.2.wave.2.fill"
        )
        AppShortcut(
            intent: OpenSafetyCardIntent(),
            phrases: [
                "Show Safety Card in \(.applicationName)",
                "Show \(.applicationName) Safety",
                "Emergency Safety Card in \(.applicationName)"
            ],
            shortTitle: "Safety Card",
            systemImageName: "shield.fill"
        )
    }
}
