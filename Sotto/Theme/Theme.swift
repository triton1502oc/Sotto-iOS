import SwiftUI

public extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

public enum SottoTheme {
    // Background & Surfaces
    public static let background = Color(hex: 0x121212)
    public static let surface = Color(hex: 0x1E1E1E)
    public static let surfaceVariant = Color(hex: 0x2A2A2A)
    
    // Primary & Content
    public static let primary = Color(hex: 0xE0E0E0)
    public static let onPrimary = Color(hex: 0x121212)
    public static let textPrimary = Color(hex: 0xE0E0E0)
    public static let textSecondary = Color(hex: 0x9E9E9E)
    public static let textDisabled = Color(hex: 0x616161)
    
    // Emergency / Crisis tokens
    public static let emergencyAccent = Color(hex: 0xFFB74D)
    public static let emergencyContainer = Color(hex: 0x1E1710)
    public static let emergencyBackground = Color(hex: 0x251E14)
    public static let emergencyBorder = Color(hex: 0xFFB74D)
    public static let emergencyText = Color(hex: 0xFFE0B2)
    public static let emergencyTextSecondary = Color(hex: 0xFFCC80)
    public static let emergencyBadgeBg = Color(hex: 0xFFB74D, alpha: 0.2)
    public static let emergencyBadgeText = Color(hex: 0xFFB74D)
    public static let emergencyChipBackground = Color(hex: 0x4E342E)
    public static let emergencyChipBackgroundDark = Color(hex: 0x3E2723)
    public static let emergencyChipBg = Color(hex: 0x3E2723)
    public static let emergencyChipSelectedBg = Color(hex: 0x4E342E)
    public static let emergencyChipSelectedText = Color(hex: 0xFFCC80)
    public static let emergencyTranslucent = Color(hex: 0xFFB74D, alpha: 0.2)
    
    // Safety semantic tokens (aliases for emergency)
    public static let safetyAccent = emergencyAccent
    public static let safetyContainer = emergencyContainer
    public static let safetyBackground = emergencyBackground
    public static let safetyBorder = emergencyBorder
    public static let safetyText = emergencyText
    public static let safetyTextSecondary = emergencyTextSecondary
    public static let safetyBadgeBg = emergencyBadgeBg
    public static let safetyBadgeText = emergencyBadgeText
    public static let safetyChipBackground = emergencyChipBackground
    public static let safetyChipBackgroundDark = emergencyChipBackgroundDark
    public static let safetyChipBg = emergencyChipBg
    public static let safetyChipSelectedBg = emergencyChipSelectedBg
    public static let safetyChipSelectedText = emergencyChipSelectedText
    public static let safetyTranslucent = emergencyTranslucent
    
    // Actions & States
    public static let confirm = Color(hex: 0x4CAF50)
    public static let danger = Color(hex: 0xEF5350)
    public static let warning = Color(hex: 0xFFC107)
    public static let destructiveRed = Color(hex: 0xEF5350)
    public static let crisisStopContainer = Color(hex: 0x7F1D1D)
    public static let crisisStopText = Color(hex: 0xFFEBEE)
    public static let crisisNoContainer = Color(hex: 0x5A3030)
    public static let crisisNoText = Color(hex: 0xFBEBE8)
    public static let recordingPulseRed = Color(hex: 0xC62828)
    public static let recordingDotRed = Color(hex: 0xE53935)
    
    // Success / Found / Active
    public static let successGreen = Color(hex: 0x2E7D32)
    public static let successContainer = Color(hex: 0x1B5E20)
    public static let successText = Color(hex: 0xE8F5E9)
    public static let activeGreen = Color(hex: 0x4CAF50)
    public static let downloadedGreen = Color(hex: 0x81C784)
    
    // Warning / Attention
    public static let warningOrange = Color(hex: 0xFFA726)
    public static let warningAmber = Color(hex: 0xFFC107)
    public static let warningHighContainer = Color(hex: 0xE65100)
    public static let warningHighText = Color(hex: 0xFFF3E0)
    
    // Neutral dark controls
    public static let neutralDarkContainer = Color(hex: 0x424242)
    public static let neutralDarkText = Color(hex: 0xEEEEEE)
    public static let neutralStoppedContainer = Color(hex: 0x37474F)
    public static let neutralStoppedText = Color(hex: 0xECEFF1)
    public static let neutralNotFoundContainer = Color(hex: 0x5D4037)
    public static let neutralNotFoundText = Color(hex: 0xEFEBE9)
    
    // Pain / Discomfort 5-Level Intensity Scale
    public static let intensityMild = Color(hex: 0x2E7D32)
    public static let intensityLight = Color(hex: 0x558B2F)
    public static let intensityModerate = Color(hex: 0xF9A825)
    public static let intensityHigh = Color(hex: 0xE65100)
    public static let intensitySevere = Color(hex: 0xB71C1C)
    
    // Dynamic Theme Accessors
    public static func palette(for key: String) -> SottoPalette {
        SottoPalettes.palette(for: key)
    }
    
    public static func background(for theme: String) -> Color { palette(for: theme).background }
    public static func surface(for theme: String) -> Color { palette(for: theme).surface }
    public static func surfaceVariant(for theme: String) -> Color { palette(for: theme).surfaceVariant }
    public static func textPrimary(for theme: String) -> Color { palette(for: theme).textPrimary }
    public static func textSecondary(for theme: String) -> Color { palette(for: theme).textSecondary }
    public static func outline(for theme: String) -> Color { palette(for: theme).outlineVariant }
    public static func accent(for theme: String) -> Color { palette(for: theme).accent }
}

private struct SottoPaletteKey: EnvironmentKey {
    static let defaultValue: SottoPalette = SottoPalettes.charcoal
}

public extension EnvironmentValues {
    var sottoPalette: SottoPalette {
        get { self[SottoPaletteKey.self] }
        set { self[SottoPaletteKey.self] = newValue }
    }
}

public struct SottoPalette: Equatable {
    public let key: String
    public let name: String
    public let description: String
    public let background: Color
    public let surface: Color
    public let surfaceVariant: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let outlineVariant: Color
    public let accent: Color
}

public enum SottoPalettes {
    public static let charcoal = SottoPalette(
        key: VoiceSettings.themeCharcoal,
        name: "Charcoal",
        description: "Balanced low-stimulus dark",
        background: Color(hex: 0x121212),
        surface: Color(hex: 0x1E1E1E),
        surfaceVariant: Color(hex: 0x2A2A2A),
        textPrimary: Color(hex: 0xE0E0E0),
        textSecondary: Color(hex: 0xAAAAAA),
        outlineVariant: Color(hex: 0x383838),
        accent: Color(hex: 0xE0E0E0)
    )
    
    public static let oledBlack = SottoPalette(
        key: VoiceSettings.themeOledBlack,
        name: "OLED Black",
        description: "Pure black, maximum contrast",
        background: Color(hex: 0x000000),
        surface: Color(hex: 0x141414),
        surfaceVariant: Color(hex: 0x222222),
        textPrimary: Color(hex: 0xFFFFFF),
        textSecondary: Color(hex: 0xB0B0B0),
        outlineVariant: Color(hex: 0x333333),
        accent: Color(hex: 0xFFFFFF)
    )
    
    public static let warmAmber = SottoPalette(
        key: VoiceSettings.themeWarmAmber,
        name: "Warm Amber",
        description: "Low blue light, reduced strain",
        background: Color(hex: 0x1A1410),
        surface: Color(hex: 0x271E18),
        surfaceVariant: Color(hex: 0x382C22),
        textPrimary: Color(hex: 0xF2E6D8),
        textSecondary: Color(hex: 0xC4B2A0),
        outlineVariant: Color(hex: 0x4A3A2C),
        accent: Color(hex: 0xDBA368)
    )
    
    public static let slateNavy = SottoPalette(
        key: VoiceSettings.themeSlateNavy,
        name: "Slate Navy",
        description: "Cool slate, calm focus",
        background: Color(hex: 0x0B121C),
        surface: Color(hex: 0x142030),
        surfaceVariant: Color(hex: 0x1E2F46),
        textPrimary: Color(hex: 0xE2E9F3),
        textSecondary: Color(hex: 0x94A7C0),
        outlineVariant: Color(hex: 0x263B54),
        accent: Color(hex: 0x7EA5D8)
    )
    
    public static let softParchment = SottoPalette(
        key: VoiceSettings.themeSoftParchment,
        name: "Soft Parchment",
        description: "Daylight reading, anti-halation",
        background: Color(hex: 0xF6F2EB),
        surface: Color(hex: 0xEAE3D5),
        surfaceVariant: Color(hex: 0xDDD4C2),
        textPrimary: Color(hex: 0x1C1917),
        textSecondary: Color(hex: 0x5C574F),
        outlineVariant: Color(hex: 0xD0C6B4),
        accent: Color(hex: 0x44403C)
    )
    
    public static let all: [SottoPalette] = [
        charcoal, oledBlack, warmAmber, slateNavy, softParchment
    ]
    
    public static func palette(for key: String) -> SottoPalette {
        switch key {
        case VoiceSettings.themeOledBlack: return oledBlack
        case VoiceSettings.themeWarmAmber: return warmAmber
        case VoiceSettings.themeSlateNavy: return slateNavy
        case VoiceSettings.themeSoftParchment: return softParchment
        default: return charcoal
        }
    }
}

public struct SottoCardButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
