import SwiftUI

// MARK: - Main Top Bar

struct MainTopBarView: View {
    @ObservedObject var viewModel: MainViewModel
    let currentPalette: SottoPalette
    
    private var isIndonesian: Bool {
        LocaleHelper.getEffectiveLanguage(appLanguage: viewModel.voiceSettings.appLanguage) == LocaleHelper.langIndonesian
    }
    
    var body: some View {
        HStack {
            Text("Sotto")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(currentPalette.textPrimary)
            
            Spacer()
            
            if !viewModel.ttsReady {
                Text("Initializing")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(SottoTheme.warning)
                    .cornerRadius(6)
                    .padding(.trailing, 6)
            }
            
            if viewModel.voiceSettings.showLanguageSwitcher {
                let isPrimary = viewModel.activeSpeechTarget == "primary"
                let primaryCode = LocaleHelper.getLocaleForLanguage(
                    LocaleHelper.getEffectiveLanguage(appLanguage: viewModel.voiceSettings.appLanguage)
                ).language.languageCode?.identifier.uppercased() ?? "EN"
                let secondaryCode = viewModel.voiceSettings.secondaryLanguage.uppercased()
                
                HStack(spacing: 2) {
                    Button(action: { viewModel.activeSpeechTarget = "primary" }) {
                        Text(primaryCode)
                            .font(.system(size: 12, weight: isPrimary ? .bold : .regular))
                            .foregroundColor(isPrimary ? currentPalette.background : currentPalette.textSecondary)
                            .padding(.horizontal, 8)
                            .frame(minWidth: 36, minHeight: 44)
                            .background(isPrimary ? currentPalette.accent : Color.clear)
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Speak in primary language, \(primaryCode)")
                    .accessibilityAddTraits(isPrimary ? [.isSelected] : [])
                    .demoTarget("langSwitch_primary")
                    
                    Button(action: { viewModel.activeSpeechTarget = "secondary" }) {
                        Text(secondaryCode)
                            .font(.system(size: 12, weight: !isPrimary ? .bold : .regular))
                            .foregroundColor(!isPrimary ? currentPalette.background : currentPalette.textSecondary)
                            .padding(.horizontal, 8)
                            .frame(minWidth: 36, minHeight: 44)
                            .background(!isPrimary ? currentPalette.accent : Color.clear)
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Speak in secondary language, \(secondaryCode)")
                    .accessibilityAddTraits(!isPrimary ? [.isSelected] : [])
                    .demoTarget("langSwitch_secondary")
                }
                .padding(2)
                .background(currentPalette.surfaceVariant)
                .cornerRadius(14)
                .padding(.trailing, 4)
            }
            
            // Partner Mode (Hero entry pill matching Android commit 5c877ff / #69)
            Button(action: {
                UserDefaults.standard.set("freeform", forKey: "partner_mode_last_tab")
                viewModel.showTwoWayDialog = true
            }) {
                HStack(spacing: 6) {
                    SottoIconView(.partnerMode, size: 18, tint: currentPalette.accent)
                    Text(isIndonesian ? "Mitra" : "Partner")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(currentPalette.accent)
                }
                .padding(.horizontal, 10)
                .frame(height: 44)
                .background(currentPalette.surfaceVariant)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(currentPalette.outlineVariant, lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .hoverEffect(.highlight)
            .accessibilityLabel(isIndonesian ? "Buka Mode Mitra untuk berkomunikasi langsung" : "Open Partner mode for communication partner")
            .accessibilityAddTraits(.isButton)
            .demoTarget("topBar_listenModeButton")
            
            // Settings Gear Icon (Always accessible)
            Button(action: {
                viewModel.showVoiceSettingsDialog = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(currentPalette.surfaceVariant)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(currentPalette.outlineVariant, lineWidth: 1)
                        )
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(currentPalette.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Settings")
            .demoTarget("topBar_voiceButton")
            
            // Edit / Done Button (12pt container with animated switch)
            Button(action: {
                let entering = !viewModel.isEditMode
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isEditMode = entering
                }
                UsabilityTracker.shared.startIntent("edit_mode_toggle")
                UsabilityTracker.shared.endIntent(
                    "edit_mode_toggle",
                    outcome: entering ? "enter" : "exit",
                    voiceSettings: viewModel.voiceSettings
                )
            }) {
                HStack(spacing: 6) {
                    SottoIconView(
                        viewModel.isEditMode ? .check : .edit,
                        size: 14,
                        tint: viewModel.isEditMode ? SottoTheme.confirm : currentPalette.textPrimary
                    )
                    Text(LocaleHelper.getActionEdit(isEditMode: viewModel.isEditMode, appLanguage: viewModel.voiceSettings.appLanguage))
                        .font(.system(size: 14, weight: viewModel.isEditMode ? .bold : .medium))
                        .foregroundColor(viewModel.isEditMode ? SottoTheme.confirm : currentPalette.textPrimary)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(viewModel.isEditMode ? SottoTheme.confirm.opacity(0.15) : currentPalette.surfaceVariant)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.isEditMode ? SottoTheme.confirm : currentPalette.outlineVariant, lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .accessibilityLabel(viewModel.isEditMode ? "Done editing" : "Edit list")
            .demoTarget("topBar_editButton")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(currentPalette.background)
    }
}

// MARK: - Category Filter Bar

struct CategoryFilterBarView: View {
    @ObservedObject var viewModel: MainViewModel
    let currentPalette: SottoPalette
    let onAddCategoryTap: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "ALL" Category Chip
                let isAllSelected = viewModel.selectedCategory == .all
                Button(action: {
                    viewModel.selectedCategory = .all
                }) {
                    Text(LocaleHelper.getCategoryDisplayName("ALL", appLanguage: viewModel.voiceSettings.appLanguage))
                        .font(.system(size: 14, weight: isAllSelected ? .bold : .regular))
                        .foregroundColor(isAllSelected ? currentPalette.textPrimary : currentPalette.textSecondary)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(isAllSelected ? currentPalette.surfaceVariant : currentPalette.surface)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isAllSelected ? currentPalette.accent.opacity(0.8) : currentPalette.outlineVariant, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(LocaleHelper.getCategoryDisplayName("ALL", appLanguage: viewModel.voiceSettings.appLanguage))
                .accessibilityAddTraits(isAllSelected ? [.isSelected] : [])
                .demoTarget("chip_all")
                
                // Dynamic Categories from Repository (Safety chip hidden on main bar to reduce visual clutter)
                let mainBarCategories = viewModel.categories.filter { PhraseCategory($0) != .emergency }
                ForEach(mainBarCategories, id: \.self) { catName in
                    let catObj = PhraseCategory(catName)
                    let isSelected = viewModel.selectedCategory == catObj
                    let isEmergency = catObj == .emergency
                    
                    Button(action: {
                        viewModel.selectedCategory = catObj
                    }) {
                        HStack(spacing: 6) {
                            if isEmergency {
                                SottoIconView(.shield, size: 12, tint: SottoTheme.safetyBadgeText)
                            }
                            Text(LocaleHelper.getCategoryDisplayName(catName, appLanguage: viewModel.voiceSettings.appLanguage))
                                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                        }
                        .foregroundColor(
                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedText :
                            (isSelected ? currentPalette.textPrimary : currentPalette.textSecondary)
                        )
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(
                            isEmergency && isSelected ? SottoTheme.emergencyChipSelectedBg :
                            (isSelected ? currentPalette.surfaceVariant : currentPalette.surface)
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    isEmergency && isSelected ? SottoTheme.emergencyBorder :
                                    (isSelected ? currentPalette.accent.opacity(0.8) : currentPalette.outlineVariant),
                                    lineWidth: 1
                                )
                        )
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel(LocaleHelper.getCategoryDisplayName(catName, appLanguage: viewModel.voiceSettings.appLanguage))
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    .demoTarget("chip_\(catName)")
                }
                
                // In Edit Mode Only: Manage Categories & Add Category Chips (#59: Zero-distraction category bar in normal mode)
                if viewModel.isEditMode {
                    Button(action: {
                        UsabilityTracker.shared.startIntent("manage_categories_open")
                        UsabilityTracker.shared.endIntent(
                            "manage_categories_open",
                            outcome: "opened",
                            voiceSettings: viewModel.voiceSettings
                        )
                        viewModel.showManageCategoriesDialog = true
                    }) {
                        SottoIconView(.tune, size: 16, tint: currentPalette.accent)
                            .frame(width: 44, height: 44)
                            .background(currentPalette.surface)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(currentPalette.outlineVariant, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Manage categories")
                    
                    Button(action: onAddCategoryTap) {
                        HStack(spacing: 4) {
                            SottoIconView(.add, size: 13, tint: currentPalette.accent)
                            Text("Add")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(currentPalette.accent)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(currentPalette.surface)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(currentPalette.outlineVariant, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Add category")
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Persistent Emergency Banner

struct PersistentEmergencyBannerView: View {
    @ObservedObject var viewModel: MainViewModel
    let phrase: Phrase
    
    var body: some View {
        Button(action: {
            if viewModel.isEditMode {
                viewModel.phraseToEdit = phrase
            } else {
                viewModel.speak(phrase: phrase)
            }
        }) {
            HStack(spacing: 10) {
                Text("🛡️")
                    .font(.system(size: 16))
                
                Text(phrase.text)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SottoTheme.safetyText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(SottoTheme.safetyBadgeText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(SottoTheme.safetyBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(SottoTheme.safetyBorder.opacity(0.8), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SottoCardButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                if !viewModel.isEditMode {
                    #if canImport(UIKit)
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.impactOccurred()
                    #endif
                    viewModel.activeFullscreenPhrase = phrase
                }
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quick Emergency Phrase: \(phrase.text)")
        .accessibilityHint(viewModel.isEditMode ? "Double tap to edit emergency card." : "Double tap to speak aloud. Double tap and hold to show fullscreen.")
        .accessibilityAction(named: "Speak Aloud") {
            viewModel.speak(phrase: phrase)
        }
        .accessibilityAction(named: "Show Fullscreen") {
            viewModel.activeFullscreenPhrase = phrase
        }
        .demoTarget("persistentEmergencyBanner")
    }
}

// MARK: - Reorderable Phrase Card Component

struct ReorderablePhraseCard: View {
    @ObservedObject var viewModel: MainViewModel
    let phrase: Phrase
    let isEmergency: Bool
    let currentPalette: SottoPalette
    var demoTargetId: String? = nil
    
    @State private var isTargeted: Bool = false
    
    var body: some View {
        let card = PhraseCardView(
            phrase: phrase,
            isEditMode: viewModel.isEditMode,
            showAlternateSpeech: viewModel.voiceSettings.showLanguageSwitcher,
            appLanguage: viewModel.voiceSettings.appLanguage,
            cardLayout: viewModel.voiceSettings.cardLayout,
            onTap: {
                if viewModel.isEditMode {
                    viewModel.phraseToEdit = phrase
                } else {
                    viewModel.speak(phrase: phrase)
                }
            },
            onLongPress: {
                viewModel.activeFullscreenPhrase = phrase
            }
        )
        .equatable()
        .scaleEffect(isTargeted ? 1.03 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isTargeted ? currentPalette.accent : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.18), value: isTargeted)
        .modifier(ReorderableCardModifier(
            phrase: phrase,
            viewModel: viewModel,
            isTargeted: $isTargeted
        ))
        
        if let target = demoTargetId {
            card.demoTarget(target)
        } else {
            card
        }
    }
}

private struct ReorderableCardModifier: ViewModifier {
    let phrase: Phrase
    @ObservedObject var viewModel: MainViewModel
    @Binding var isTargeted: Bool
    
    func body(content: Content) -> some View {
        if viewModel.isEditMode {
            content
                .draggable(phrase.id.uuidString)
                .dropDestination(for: String.self) { items, _ in
                    isTargeted = false
                    guard let draggedIdString = items.first,
                          let draggedId = UUID(uuidString: draggedIdString),
                          let fromPhrase = viewModel.phrases.first(where: { $0.id == draggedId }),
                          fromPhrase.id != phrase.id else {
                        return false
                    }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.movePhrase(fromPhrase: fromPhrase, toPhrase: phrase)
                    }
                    #if canImport(UIKit)
                    let feedback = UIImpactFeedbackGenerator(style: .medium)
                    feedback.impactOccurred()
                    #endif
                    return true
                } isTargeted: { targeted in
                    isTargeted = targeted
                }
        } else {
            content
        }
    }
}

// MARK: - Activity View for File Sharing

struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
