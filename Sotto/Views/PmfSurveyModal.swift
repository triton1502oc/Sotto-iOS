import SwiftUI

public struct PmfSurveyModal: View {
    public let initialRole: String
    public let onSubmit: (_ pmfScore: String, _ primaryBenefit: String, _ role: String) -> Void
    public let onDismiss: () -> Void
    
    @State private var selectedQ1: String? = nil
    @State private var selectedQ2: String = "why_finder"
    @State private var selectedQ3: String
    
    public init(
        initialRole: String = VoiceSettings.roleUnset,
        onSubmit: @escaping (String, String, String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.initialRole = initialRole
        self.onSubmit = onSubmit
        self.onDismiss = onDismiss
        _selectedQ3 = State(initialValue: initialRole != VoiceSettings.roleUnset ? initialRole : VoiceSettings.roleCaregiver)
    }
    
    private let q1Options: [(key: String, label: String)] = [
        ("very_disappointed", "Very disappointed"),
        ("somewhat_disappointed", "Somewhat disappointed"),
        ("not_disappointed", "Not disappointed"),
        ("na", "N/A - I no longer use it")
    ]
    
    private let q2Options: [(key: String, label: String)] = [
        ("why_finder", "Why Finder (narrowing causes)"),
        ("caregiver_mode", "Caregiver Mode (receptive listener)"),
        ("phrase_cards", "Phrase Cards"),
        ("emergency_card", "Emergency Alert Card"),
        ("quick_speak", "Quick Speak bar")
    ]
    
    private let q3Options: [(key: String, label: String)] = [
        (VoiceSettings.roleCaregiver, "Caregiver / Family member"),
        (VoiceSettings.roleSelf, "Self (AAC user)"),
        (VoiceSettings.roleProfessional, "Speech Therapist / Professional")
    ]
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🌱 Quick Feedback")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(SottoTheme.textPrimary)
                            Text("Help shape the future of Sotto. Takes 30 seconds.")
                                .font(.system(size: 14))
                                .foregroundColor(SottoTheme.textSecondary)
                        }
                        
                        // Question 1
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. How would you feel if you could no longer use Sotto?")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            ForEach(q1Options, id: \.key) { item in
                                optionCard(
                                    label: item.label,
                                    isSelected: selectedQ1 == item.key,
                                    onSelect: { selectedQ1 = item.key }
                                )
                            }
                        }
                        
                        // Question 2
                        VStack(alignment: .leading, spacing: 8) {
                            Text("2. What is the most valuable part of Sotto for you?")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            ForEach(q2Options, id: \.key) { item in
                                optionCard(
                                    label: item.label,
                                    isSelected: selectedQ2 == item.key,
                                    onSelect: { selectedQ2 = item.key }
                                )
                            }
                        }
                        
                        // Question 3
                        VStack(alignment: .leading, spacing: 8) {
                            Text("3. Who are you using Sotto as?")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(SottoTheme.textPrimary)
                            
                            ForEach(q3Options, id: \.key) { item in
                                optionCard(
                                    label: item.label,
                                    isSelected: selectedQ3 == item.key,
                                    onSelect: { selectedQ3 = item.key }
                                )
                            }
                        }
                        
                        // Submit Button
                        Button(action: {
                            guard let q1 = selectedQ1 else { return }
                            onSubmit(q1, selectedQ2, selectedQ3)
                            onDismiss()
                        }) {
                            Text("Submit Feedback")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(selectedQ1 != nil ? .white : SottoTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(selectedQ1 != nil ? SottoTheme.primary : SottoTheme.surfaceVariant)
                                .cornerRadius(12)
                        }
                        .disabled(selectedQ1 == nil)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func optionCard(label: String, isSelected: Bool, onSelect: @escaping () -> Void) -> some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? SottoTheme.primary : SottoTheme.textSecondary)
                    .font(.system(size: 16))
                
                Text(label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(SottoTheme.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? SottoTheme.primary.opacity(0.15)
                    : SottoTheme.surfaceVariant.opacity(0.3)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? SottoTheme.primary : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
    }
}
