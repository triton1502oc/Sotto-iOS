import SwiftUI

public struct FullscreenPhraseModal: View {
    public let phrase: Phrase
    public let onSpeak: (Phrase) -> Void
    public let onDismiss: () -> Void
    
    public init(
        phrase: Phrase,
        onSpeak: @escaping (Phrase) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.phrase = phrase
        self.onSpeak = onSpeak
        self.onDismiss = onDismiss
    }
    
    private var isEmergency: Bool {
        phrase.isEmergency
    }
    
    public var body: some View {
        ZStack {
            (isEmergency ? Color(hex: 0x1E1710) : SottoTheme.background)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top Bar with Optional Emergency Badge and Dismiss Button
                ZStack {
                    if isEmergency {
                        HStack(spacing: 6) {
                            Text("🚨")
                            Text("Emergency")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(SottoTheme.emergencyBadgeText)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(SottoTheme.emergencyBadgeBg)
                        .cornerRadius(8)
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isEmergency ? SottoTheme.emergencyBorder : SottoTheme.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Giant High-Contrast Phrase Text
                Spacer()
                Text(phrase.text)
                    .font(.system(size: (isEmergency && phrase.text.count > 60) ? 36 : 48, weight: .bold))
                    .foregroundColor(isEmergency ? SottoTheme.emergencyText : SottoTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 24)
                Spacer()
                
                // Big Speak Aloud Action Button
                Button(action: {
                    onSpeak(phrase)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 22, weight: .bold))
                        Text("Speak Aloud")
                            .font(.system(size: 22, weight: .bold))
                    }
                    .foregroundColor(isEmergency ? Color(hex: 0x1E1710) : SottoTheme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(isEmergency ? SottoTheme.emergencyBorder : SottoTheme.primary)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .overlay(
            Group {
                if isEmergency {
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(SottoTheme.emergencyBorder, lineWidth: 2)
                        .ignoresSafeArea()
                }
            }
        )
    }
}
