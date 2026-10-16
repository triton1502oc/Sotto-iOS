import SwiftUI

public struct ImportBackupModal: View {
    @Environment(\.sottoPalette) private var palette
    public let backupData: BackupData
    public let onMerge: (BackupData) -> Void
    public let onReplace: (BackupData) -> Void
    public let onDismiss: () -> Void
    
    @State private var selectedMode: ImportMode = .merge
    @State private var showReplaceConfirm: Bool = false
    
    @State private var importPhrases: Bool
    @State private var importTree: Bool
    @State private var importLog: Bool = false
    
    public enum ImportMode {
        case merge
        case replace
    }
    
    public init(
        backupData: BackupData,
        onMerge: @escaping (BackupData) -> Void,
        onReplace: @escaping (BackupData) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.backupData = backupData
        self.onMerge = onMerge
        self.onReplace = onReplace
        self.onDismiss = onDismiss
        _importPhrases = State(initialValue: !backupData.phrases.isEmpty)
        _importTree = State(initialValue: backupData.whyTree != nil)
        _importLog = State(initialValue: false)
    }
    
    public init(
        backupData: BackupData,
        onMerge: @escaping () -> Void,
        onReplace: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.init(
            backupData: backupData,
            onMerge: { _ in onMerge() },
            onReplace: { _ in onReplace() },
            onDismiss: onDismiss
        )
    }
    
    private var hasSelection: Bool {
        importPhrases || importTree || importLog
    }
    
    private var filteredBackup: BackupData {
        BackupData(
            version: backupData.version,
            exportedAt: backupData.exportedAt,
            categories: importPhrases ? backupData.categories : [],
            phrases: importPhrases ? backupData.phrases : [],
            whyTree: importTree ? backupData.whyTree : nil,
            whyLog: importLog ? backupData.whyLog : nil
        )
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                palette.surface
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 18) {
                    if backupData.phrases.isEmpty && backupData.whyTree != nil {
                        // Tree-only file (e.g. therapist shared tree)
                        treeOnlyContent
                    } else {
                        // Standard or full backup file
                        standardBackupContent
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Import Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
            .alert("Replace Entire Library?", isPresented: $showReplaceConfirm) {
                Button("Replace Library", role: .destructive) {
                    onReplace(filteredBackup)
                    onDismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will replace all non-emergency phrases with the imported backup file. Emergency phrases are always preserved.")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Tree Only Content
    
    private var treeOnlyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This file contains a Question Tree shared by a caregiver or therapist.")
                .font(.system(size: 15))
                .foregroundColor(palette.textPrimary)
            
            if let areas = backupData.whyTree?.areas {
                HStack(spacing: 8) {
                    SottoIconView(.branch, size: 16, tint: palette.accent)
                    Text("Includes \(areas.count) question areas")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(palette.accent)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.accent.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: {
                onMerge(filteredBackup)
                onDismiss()
            }) {
                HStack(spacing: 8) {
                    SottoIconView(.restore, size: 18, tint: .white)
                    Text("Import Question Tree")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(palette.accent)
                .cornerRadius(12)
            }
            .padding(.top, 12)
        }
    }
    
    // MARK: - Standard Backup Content
    
    private var standardBackupContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Components to Import")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                
                if !backupData.phrases.isEmpty {
                    componentCheckboxRow(
                        title: "Phrases & Categories",
                        subtitle: "\(backupData.phrases.count) phrases across \(backupData.categories.count) categories",
                        icon: .cards,
                        isSelected: importPhrases,
                        onToggle: { importPhrases.toggle() }
                    )
                }
                
                if let tree = backupData.whyTree {
                    componentCheckboxRow(
                        title: "Why Finder Question Tree",
                        subtitle: "\(tree.areas.count) branching question areas",
                        icon: .branch,
                        isSelected: importTree,
                        onToggle: { importTree.toggle() }
                    )
                }
                
                if let logs = backupData.whyLog, !logs.isEmpty {
                    componentCheckboxRow(
                        title: "Private Why Log",
                        subtitle: "\(logs.count) check-in sessions (Private caregiver history)",
                        icon: .shield,
                        isSelected: importLog,
                        onToggle: { importLog.toggle() }
                    )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surfaceVariant.opacity(0.5))
            .cornerRadius(12)
            
            Text("Choose how you would like to import selected items:")
                .font(.system(size: 14))
                .foregroundColor(palette.textSecondary)
                .padding(.top, 4)
            
            // Mode Option 1: Merge
            importModeCard(
                mode: .merge,
                title: "Merge with Existing Library",
                description: "Adds new items and deduplicates without removing existing content",
                isDestructive: false
            )
            
            // Mode Option 2: Replace
            importModeCard(
                mode: .replace,
                title: "Replace Entire Library",
                description: "Replaces current items with selected backup components (Emergency preserved)",
                isDestructive: true
            )
            
            // Proceed Action CTA Button
            Button(action: {
                if selectedMode == .replace {
                    showReplaceConfirm = true
                } else {
                    onMerge(filteredBackup)
                    onDismiss()
                }
            }) {
                HStack(spacing: 8) {
                    SottoIconView(.restore, size: 18, tint: .white)
                    Text(selectedMode == .replace ? "Proceed with Replace" : "Merge Library")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(selectedMode == .replace ? SottoTheme.danger : palette.accent)
                .cornerRadius(14)
                .opacity(hasSelection ? 1.0 : 0.5)
            }
            .disabled(!hasSelection)
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private func componentCheckboxRow(
        title: String,
        subtitle: String,
        icon: SottoIcon,
        isSelected: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onToggle()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? palette.accent : palette.textSecondary.opacity(0.5))
                
                SottoIconView(icon, size: 18, tint: isSelected ? palette.accent : palette.textSecondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(palette.textSecondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(title), \(isSelected ? "Checked" : "Unchecked")")
        .accessibilityHint("Double tap to toggle component inclusion")
    }
    
    @ViewBuilder
    private func importModeCard(
        mode: ImportMode,
        title: String,
        description: String,
        isDestructive: Bool
    ) -> some View {
        let isSelected = selectedMode == mode
        Button(action: {
            selectedMode = mode
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isSelected && isDestructive ? SottoTheme.danger : palette.textPrimary)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(palette.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(
                        isSelected
                            ? (isDestructive ? SottoTheme.danger : palette.accent)
                            : palette.textSecondary.opacity(0.4)
                    )
            }
            .padding(12)
            .background(
                isSelected
                    ? (isDestructive ? SottoTheme.danger.opacity(0.12) : palette.accent.opacity(0.08))
                    : palette.surfaceVariant.opacity(0.5)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected
                            ? (isDestructive ? SottoTheme.danger : palette.accent)
                            : palette.outlineVariant.opacity(0.35),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .contentShape(Rectangle())
        }
    }
}
