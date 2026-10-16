import SwiftUI
import AVFoundation

public final class AppDelegate: NSObject, UIApplicationDelegate {
    public static var orientationLock = UIInterfaceOrientationMask.all

    public func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return Self.orientationLock
    }
}

@main
struct SottoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("sotto_app_theme") private var appTheme: String = VoiceSettings.themeCharcoal
    
    init() {
        // Configure default audio session for assistive communication playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // Safe fallback
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(appTheme == VoiceSettings.themeSoftParchment ? .light : .dark)
        }
    }
}
