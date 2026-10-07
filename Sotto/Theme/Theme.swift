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
    
    // Actions & States
    public static let confirm = Color(hex: 0x4CAF50)
    public static let danger = Color(hex: 0xEF5350)
    public static let warning = Color(hex: 0xFFC107)
    public static let destructiveRed = Color(hex: 0xEF5350)
    public static let crisisStopContainer = Color(hex: 0x7F1D1D)
    public static let crisisStopText = Color(hex: 0xFFEBEE)
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
}
