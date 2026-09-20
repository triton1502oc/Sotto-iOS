import SwiftUI

public struct PhraseCardView: View {
    public let phrase: Phrase
    public let isEditMode: Bool
    public let showAlternateSpeech: Bool
    public let onTap: () -> Void
    public let onLongPress: () -> Void
    
    public init(
        phrase: Phrase,
        isEditMode: Bool,
        showAlternateSpeech: Bool = false,
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) {
        self.phrase = phrase
        self.isEditMode = isEditMode
        self.showAlternateSpeech = showAlternateSpeech
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    private var hasSpokenText: Bool {
        guard showAlternateSpeech, let spoken = phrase.spokenText?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !spoken.isEmpty
    }
    
    public var body: some View {
        Button(action: onTap) {
            if phrase.isEmergency {
                emergencyCardContent
            } else {
                regularCardContent
            }
        }
        .buttonStyle(CardButtonStyle())
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
            // Emergency Badge
            HStack(spacing: 4) {
                Text("🚨")
                    .font(.system(size: 13))
                Text("Emergency")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(SottoTheme.emergencyBadgeText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(SottoTheme.emergencyBadgeBg)
            .cornerRadius(6)
            
            // Emergency Phrase Text
            Text(phrase.text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(SottoTheme.emergencyText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 12)
            
            if hasSpokenText, let spoken = phrase.spokenText {
                HStack(spacing: 4) {
                    Text("🗣️")
                        .font(.system(size: 12))
                    Text(spoken)
                        .font(.system(size: 13))
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
        .background(isEditMode ? SottoTheme.surfaceVariant : SottoTheme.emergencyBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SottoTheme.emergencyBorder, lineWidth: 1.5)
        )
    }
    
    @ViewBuilder
    private var regularCardContent: some View {
        VStack {
            Spacer()
            Text(phrase.text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SottoTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(hasSpokenText ? 3 : 4)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            if hasSpokenText, let spoken = phrase.spokenText {
                Spacer().frame(height: 4)
                HStack(spacing: 4) {
                    Text("🗣️")
                        .font(.system(size: 11))
                    Text(spoken)
                        .font(.system(size: 12))
                        .foregroundColor(SottoTheme.textSecondary.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 8)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
        .background(isEditMode ? SottoTheme.surfaceVariant : SottoTheme.surface)
        .cornerRadius(16)
    }
}

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
