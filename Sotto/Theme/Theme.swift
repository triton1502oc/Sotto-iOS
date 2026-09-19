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
    
    // Emergency Card & Accents
    public static let emergencyBackground = Color(hex: 0x251E14)
    public static let emergencyBorder = Color(hex: 0xFFB74D)
    public static let emergencyText = Color(hex: 0xFFE0B2)
    public static let emergencyBadgeBg = Color(hex: 0xFFB74D, alpha: 0.2)
    public static let emergencyBadgeText = Color(hex: 0xFFB74D)
    public static let emergencyChipSelectedBg = Color(hex: 0x4E342E)
    public static let emergencyChipSelectedText = Color(hex: 0xFFCC80)
    
    // Actions & States
    public static let confirm = Color(hex: 0x4CAF50)
    public static let danger = Color(hex: 0xEF5350)
    public static let warning = Color(hex: 0xFFC107)
}
