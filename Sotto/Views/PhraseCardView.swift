import SwiftUI

public struct PhraseCardView: View {
    public let phrase: Phrase
    public let isEditMode: Bool
    public let onTap: () -> Void
    public let onLongPress: () -> Void
    
    public init(
        phrase: Phrase,
        isEditMode: Bool,
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) {
        self.phrase = phrase
        self.isEditMode = isEditMode
        self.onTap = onTap
        self.onLongPress = onLongPress
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
        VStack(spacing: 10) {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
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
                .padding(12)
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
