import SwiftUI

public struct PhraseCardView: View {
    @Environment(\.sottoPalette) private var palette
    public let phrase: Phrase
    public let isEditMode: Bool
    public let showAlternateSpeech: Bool
    public let appLanguage: String
    public let cardLayout: String
    public let onTap: () -> Void
    public let onLongPress: () -> Void
    
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
    
    private var hasSpokenText: Bool {
        guard showAlternateSpeech, let spoken = phrase.spokenText?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !spoken.isEmpty
    }
    
    private var accessibilityLabelText: String {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAction(named: "Speak Aloud") {
            onTap()
        }
        .accessibilityAction(named: "Show Fullscreen") {
            onLongPress()
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if !isEditMode {
                        #if canImport(UIKit)
                        let feedback = UIImpactFeedbackGenerator(style: .medium)
                        feedback.impactOccurred()
                        #endif
                        onLongPress()
                    }
                }
        )
    }
    
    @ViewBuilder
    private var emergencyCardContent: some View {
        VStack(spacing: 8) {
            // Safety Badge
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
            
            // Safety Phrase Text
            Text(phrase.text)
                .font(.title3.weight(.medium))
                .foregroundColor(SottoTheme.safetyText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
            
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
        .overlay(alignment: .topTrailing) {
            if isEditMode {
                SottoIconView(.dragHandle, size: 14, tint: palette.textSecondary.opacity(0.6))
                    .padding(10)
                    .accessibilityLabel("Drag to reorder")
            }
        }
    }
    
    @ViewBuilder
    private var regularCardContent: some View {
        VStack {
            Spacer()
            Text(phrase.text)
                .font(.body.weight(.medium))
                .foregroundColor(palette.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(hasSpokenText ? 2 : (isCompact ? 3 : 4))
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 12)
                .padding(.top, 6)
            
            if hasSpokenText, let spoken = phrase.spokenText {
                Spacer().frame(height: 3)
                HStack(spacing: 4) {
                    SottoIconView(.volumeUp, size: 10, tint: palette.textSecondary.opacity(0.85))
                    Text(spoken)
                        .font(.caption)
                        .foregroundColor(palette.textSecondary.opacity(0.85))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 8)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(isCompact ? 1.25 : 1.0, contentMode: .fit)
        .background(isEditMode ? palette.surfaceVariant : palette.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isEditMode ? SottoTheme.confirm : palette.outlineVariant, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if isEditMode {
                SottoIconView(.dragHandle, size: 14, tint: palette.textSecondary.opacity(0.6))
                    .padding(8)
                    .accessibilityLabel("Drag to reorder")
            }
        }
    }
}
