import SwiftUI

public struct PhraseCardView: View, Equatable {
    @Environment(\.sottoPalette) private var palette
    @Environment(\.sizeCategory) private var sizeCategory
    public let phrase: Phrase
    public let isEditMode: Bool
    public let showAlternateSpeech: Bool
    public let appLanguage: String
    public let cardLayout: String
    public let onTap: () -> Void
    public let onLongPress: () -> Void
    
    public static func == (lhs: PhraseCardView, rhs: PhraseCardView) -> Bool {
        lhs.phrase == rhs.phrase &&
        lhs.isEditMode == rhs.isEditMode &&
        lhs.showAlternateSpeech == rhs.showAlternateSpeech &&
        lhs.appLanguage == rhs.appLanguage &&
        lhs.cardLayout == rhs.cardLayout
    }
    
    public init(
        phrase: Phrase,
        isEditMode: Bool,
        showAlternateSpeech: Bool = false,
        appLanguage: String = "system",
        cardLayout: String = VoiceSettings.cardLayoutSquare,
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) {
        self.phrase = phrase
        self.isEditMode = isEditMode
        self.showAlternateSpeech = showAlternateSpeech
        self.appLanguage = appLanguage
        self.cardLayout = cardLayout
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    private var isCompact: Bool {
        cardLayout == VoiceSettings.cardLayoutCompact
    }
    
    private var isIndonesian: Bool {
        let lang = LocaleHelper.getEffectiveLanguage(appLanguage: appLanguage)
        return lang == LocaleHelper.langIndonesian || lang == "in"
    }
    
    private var isUnresolvedSafety: Bool {
        phrase.isEmergency && LocaleHelper.hasUnresolvedPlaceholders(phrase.text)
    }
    
    private var hasSpokenText: Bool {
        guard showAlternateSpeech, let spoken = phrase.spokenText?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !spoken.isEmpty
    }
    
    private var accessibilityLabelText: String {
        if isUnresolvedSafety {
            return isIndonesian ? "Atur Kontak Darurat: \(phrase.text)" : "Set Up Emergency Contact: \(phrase.text)"
        }
        let typePrefix = phrase.isEmergency ? "Safety phrase, \(phrase.category.displayName)" : "\(phrase.category.displayName) phrase"
        if hasSpokenText, let spoken = phrase.spokenText {
            return "\(typePrefix): \(phrase.text). Alternate speech: \(spoken)"
        }
        return "\(typePrefix): \(phrase.text)"
    }
    
    private var accessibilityHintText: String {
        if isEditMode {
            return "Double tap to edit card."
        }
        if isUnresolvedSafety {
            return isIndonesian ? "Ketuk dua kali untuk mengatur kontak darurat." : "Double tap to configure emergency contact details."
        }
        return "Double tap to speak aloud. Double tap and hold to show fullscreen."
    }
    
    public var body: some View {
        Button(action: onTap) {
            if phrase.isEmergency {
                emergencyCardContent
            } else {
                regularCardContent
            }
        }
        .buttonStyle(SottoCardButtonStyle())
        .hoverEffect(.highlight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: isEditMode ? "Edit Card" : (isUnresolvedSafety ? "Set Up Emergency Contact" : "Speak Aloud")) {
            onTap()
        }
        .accessibilityAction(named: "Show Fullscreen") {
            if !isEditMode {
                onLongPress()
            }
        }
        .modifier(CardLongPressModifier(isEditMode: isEditMode, onLongPress: onLongPress))
    }
    
    private struct CardLongPressModifier: ViewModifier {
        let isEditMode: Bool
        let onLongPress: () -> Void
        
        func body(content: Content) -> some View {
            if isEditMode {
                content
            } else {
                content.simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            #if canImport(UIKit)
                            let feedback = UIImpactFeedbackGenerator(style: .medium)
                            feedback.impactOccurred()
                            #endif
                            onLongPress()
                        }
                )
            }
        }
    }
    
    @ViewBuilder
    private var emergencyCardContent: some View {
        VStack(spacing: 10) {
            // Header Row: Safety Badge on Left, 1-Tap Fullscreen & Speak (or Drag Handle) on Right
            HStack {
                HStack(spacing: 5) {
                    SottoIconView(.shield, size: 12, tint: SottoTheme.safetyBadgeText)
                    Text(LocaleHelper.getCategoryDisplayName("EMERGENCY", appLanguage: appLanguage))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SottoTheme.safetyBadgeText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(SottoTheme.safetyBadgeBg)
                .cornerRadius(6)
                
                Spacer()
                
                if isEditMode {
                    SottoIconView(.dragHandle, size: 14, tint: palette.textSecondary.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Drag to reorder")
                } else {
                    HStack(spacing: 4) {
                        Button(action: onLongPress) {
                            SottoIconView(.fullscreen, size: 18, tint: SottoTheme.safetyBadgeText)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isIndonesian ? "Tampilkan layar penuh" : "Show fullscreen")
                        
                        Button(action: onTap) {
                            SottoIconView(.volumeUp, size: 18, tint: SottoTheme.safetyBadgeText)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isIndonesian ? "Bicara" : "Speak")
                    }
                }
            }
            
            // Safety Phrase Text
            Text(phrase.text)
                .font(.title3.weight(.medium))
                .foregroundColor(SottoTheme.safetyText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
            
            if isUnresolvedSafety {
                HStack(spacing: 5) {
                    SottoIconView(.edit, size: 12, tint: SottoTheme.safetyBadgeText)
                    Text(isIndonesian ? "Ketuk untuk mengatur" : "Tap to configure")
                        .font(.caption.weight(.bold))
                        .foregroundColor(SottoTheme.safetyBadgeText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(SottoTheme.safetyBadgeBg)
                .cornerRadius(8)
            }
            
            if hasSpokenText, let spoken = phrase.spokenText {
                HStack(spacing: 5) {
                    SottoIconView(.volumeUp, size: 12, tint: Color(hex: 0xFFFFCC80).opacity(0.8))
                    Text(spoken)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: 0xFFFFCC80).opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(isEditMode ? palette.surfaceVariant : SottoTheme.safetyBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SottoTheme.safetyBorder, lineWidth: 1.5)
        )
    }
    
    @ViewBuilder
    private var regularCardContent: some View {
        VStack {
            Spacer()
            Text(phrase.text)
                .font(.body.weight(.medium))
                .foregroundColor(palette.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(sizeCategory.isAccessibilityCategory ? nil : (hasSpokenText ? 2 : (isCompact ? 3 : 4)))
                .minimumScaleFactor(sizeCategory.isAccessibilityCategory ? 0.6 : 0.75)
                .padding(.horizontal, 12)
                .padding(.top, 6)
            
            if hasSpokenText, let spoken = phrase.spokenText {
                Spacer().frame(height: 3)
                HStack(spacing: 4) {
                    SottoIconView(.volumeUp, size: 10, tint: palette.textSecondary.opacity(0.85))
                    Text(spoken)
                        .font(.caption)
                        .foregroundColor(palette.textSecondary.opacity(0.85))
                        .lineLimit(sizeCategory.isAccessibilityCategory ? 2 : 1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 8)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .modifier(CardAspectRatioModifier(isAccessibility: sizeCategory.isAccessibilityCategory, isCompact: isCompact))
        .background(isEditMode ? palette.surfaceVariant : palette.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isEditMode ? SottoTheme.confirm : palette.outlineVariant, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if isEditMode {
                SottoIconView(.dragHandle, size: 14, tint: palette.textSecondary.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Drag to reorder")
            }
        }
    }
    
    private struct CardAspectRatioModifier: ViewModifier {
        let isAccessibility: Bool
        let isCompact: Bool
        
        func body(content: Content) -> some View {
            if isAccessibility {
                content
                    .frame(minHeight: isCompact ? 110 : 130)
                    .padding(.vertical, 8)
            } else {
                content
                    .aspectRatio(isCompact ? 1.25 : 1.0, contentMode: .fit)
            }
        }
    }
}
