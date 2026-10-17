import SwiftUI

public struct ExportBackupModal: View {
    @Environment(\.sottoPalette) private var palette
    public let phraseCount: Int
    public let areaCount: Int
    public let logCount: Int
    public let phrases: [Phrase]
    public let categories: [String]
    public let appLanguage: String
    public let onExport: (_ exportPhrases: Bool, _ exportTree: Bool, _ exportLog: Bool, _ selectedCategories: Set<String>?) -> Void
    public var onShareQR: ((_ exportPhrases: Bool, _ exportTree: Bool, _ exportLog: Bool, _ selectedCategories: Set<String>?) -> Void)? = nil
    public let onDismiss: () -> Void
    
    @State private var exportPhrases: Bool = true
    @State private var exportTree: Bool = true
    @State private var exportLog: Bool = false
    @State private var selectedCategories: Set<String>
    
    public init(
        phraseCount: Int,
        areaCount: Int,
        logCount: Int,
        phrases: [Phrase] = [],
        categories: [String] = [],
        appLanguage: String = "system",
        onExport: @escaping (Bool, Bool, Bool, Set<String>?) -> Void,
        onShareQR: ((Bool, Bool, Bool, Set<String>?) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.phraseCount = phraseCount
        self.areaCount = areaCount
        self.logCount = logCount
        self.phrases = phrases
        self.categories = categories
        self.appLanguage = appLanguage
        self.onExport = onExport
        self.onShareQR = onShareQR
        self.onDismiss = onDismiss
        _selectedCategories = State(initialValue: Set(categories))
    }
    
    private var categoryCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for cat in categories {
            counts[cat] = phrases.filter { $0.category.rawValue == cat }.count
        }
        return counts
    }
    
    private var effectivePhraseCount: Int {
        if !categories.isEmpty {
            return phrases.filter { selectedCategories.contains($0.category.rawValue) }.count
        }
        return phraseCount
    }
    
    private var hasPhrasesSelected: Bool {
        exportPhrases && (categories.isEmpty || !selectedCategories.isEmpty)
    }
    
    private var hasSelection: Bool {
        hasPhrasesSelected || exportTree || exportLog
    }
    
    private var effectiveSelectedCategories: Set<String>? {
        categories.isEmpty ? nil : selectedCategories
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                palette.surface
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Export library phrases, categories, question trees, or private logs as a backup file.")
                            .font(.system(size: 14))
                            .foregroundColor(palette.textSecondary)
                        
                        VStack(spacing: 10) {
                            // Option 1: Phrases & Categories (with selective category chips)
                            selectableOptionCard(
                                checked: exportPhrases,
                                onToggle: { exportPhrases.toggle() },
                                icon: .cards,
                                title: "Phrases & Categories",
                                subtitle: "\(effectivePhraseCount) phrases",
                                extraContent: {
                                    if exportPhrases && !categories.isEmpty {
                                        categorySelectionContent
                                    }
                                }
                            )
                            
                            // Option 2: Question Tree
                            selectableOptionCard(
                                checked: exportTree,
                                onToggle: { exportTree.toggle() },
                                icon: .branch,
                                title: "Why Finder Question Tree",
                                subtitle: "\(areaCount) narrowing areas"
                            )
                            
                            // Option 3: Private Why Log (with warning)
                            selectableOptionCard(
                                checked: exportLog,
                                onToggle: { exportLog.toggle() },
                                icon: .shield,
                                title: "Private Why Log",
                                subtitle: "\(logCount) saved session records",
                                warning: exportLog ? "Includes sensitive offline logs with health/care notes." : nil
                            )
                        }
                        
                        if let onShareQR = onShareQR {
                            Button(action: {
                                onShareQR(hasPhrasesSelected, exportTree, exportLog, effectiveSelectedCategories)
                            }) {
                                HStack(spacing: 8) {
                                    SottoIconView(.qrCodeScanner, size: 18, tint: palette.accent)
                                    Text("Share via QR Code Deck")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(palette.accent)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 48)
                                .background(palette.surfaceVariant.opacity(0.5))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(palette.accent.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .disabled(!hasPhrasesSelected || effectivePhraseCount == 0)
                            .opacity((hasPhrasesSelected && effectivePhraseCount > 0) ? 1.0 : 0.5)
                        }
                        
                        Spacer(minLength: 16)
                        
                        // Export File Action Button
                        Button(action: {
                            onExport(hasPhrasesSelected, exportTree, exportLog, effectiveSelectedCategories)
                        }) {
                            HStack(spacing: 8) {
                                SottoIconView(.backup, size: 18, tint: .white)
                                Text("Export Backup File")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(hasSelection ? palette.accent : palette.textSecondary.opacity(0.3))
                            .cornerRadius(14)
                        }
                        .disabled(!hasSelection)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Export Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    @ViewBuilder
    private var categorySelectionContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .background(palette.outlineVariant.opacity(0.35))
                .padding(.vertical, 4)
            
            HStack {
                Text(LocaleHelper.getExportSelectCategoriesLabel(appLanguage: appLanguage))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.textSecondary)
                
                Spacer()
                
                let allSelected = selectedCategories.count == categories.count
                Button(action: {
                    if allSelected {
                        selectedCategories.removeAll()
                    } else {
                        selectedCategories = Set(categories)
                    }
                }) {
                    Text(allSelected ? LocaleHelper.getActionDeselectAll(appLanguage: appLanguage) : LocaleHelper.getActionSelectAll(appLanguage: appLanguage))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(palette.accent.opacity(0.12))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(categories, id: \.self) { catName in
                    let isSelected = selectedCategories.contains(catName)
                    let count = categoryCounts[catName] ?? 0
                    Button(action: {
                        if isSelected {
                            selectedCategories.remove(catName)
                        } else {
                            selectedCategories.insert(catName)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isSelected ? palette.accent : palette.textSecondary.opacity(0.6))
                            Text("\(LocaleHelper.getCategoryDisplayName(catName, appLanguage: appLanguage)) (\(count))")
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? palette.textPrimary : palette.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isSelected ? palette.accent.opacity(0.12) : palette.surfaceVariant.opacity(0.4))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? palette.accent.opacity(0.6) : palette.outlineVariant.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel("\(LocaleHelper.getCategoryDisplayName(catName, appLanguage: appLanguage)), \(count) phrases")
                }
            }
        }
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private func selectableOptionCard<ExtraContent: View>(
        checked: Bool,
        onToggle: @escaping () -> Void,
        icon: SottoIcon,
        title: String,
        subtitle: String,
        warning: String? = nil,
        @ViewBuilder extraContent: () -> ExtraContent = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(checked ? palette.accent.opacity(0.15) : palette.surfaceVariant)
                            .frame(width: 36, height: 36)
                        SottoIconView(icon, size: 18, tint: checked ? palette.accent : palette.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(palette.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(checked ? palette.accent : palette.textSecondary.opacity(0.5))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if let warn = warning {
                HStack(spacing: 6) {
                    SottoIconView(.warning, size: 13, tint: SottoTheme.danger)
                    Text(warn)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SottoTheme.danger)
                }
                .padding(.top, 8)
                .padding(.leading, 48)
            }
            
            if checked {
                extraContent()
            }
        }
        .padding(12)
        .background(checked ? palette.accent.opacity(0.08) : palette.surfaceVariant.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(checked ? palette.accent : palette.outlineVariant.opacity(0.35), lineWidth: checked ? 1.5 : 1)
        )
    }
}
