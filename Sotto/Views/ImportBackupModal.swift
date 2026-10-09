import SwiftUI

public struct ImportBackupModal: View {
    public let backupData: BackupData
    public let onMerge: () -> Void
    public let onReplace: () -> Void
    public let onDismiss: () -> Void
    
    @State private var showReplaceConfirm: Bool = false
    
    public init(
        backupData: BackupData,
        onMerge: @escaping () -> Void,
        onReplace: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.backupData = backupData
        self.onMerge = onMerge
        self.onReplace = onReplace
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
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
                    onReplace()
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
                .foregroundColor(SottoTheme.textPrimary)
            
            if let areas = backupData.whyTree?.areas {
                Text("• Includes \(areas.count) question areas")
                    .font(.system(size: 14))
                    .foregroundColor(SottoTheme.primary)
            }
            
            Button(action: {
                onMerge()
                onDismiss()
            }) {
                Text("Import Question Tree")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(SottoTheme.primary)
                    .cornerRadius(12)
            }
            .padding(.top, 12)
        }
    }
    
    // MARK: - Standard Backup Content
    
    private var standardBackupContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Backup Content Summary")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(SottoTheme.textPrimary)
                
                Text("\(backupData.phrases.count) phrases across \(backupData.categories.count) categories")
                    .font(.system(size: 14))
                    .foregroundColor(SottoTheme.textSecondary)
                
                if let tree = backupData.whyTree {
                    Text("• Why Finder Question Tree (\(tree.areas.count) areas)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(SottoTheme.primary)
                }
                
                if let logs = backupData.whyLog, !logs.isEmpty {
                    Text("• Private Why Log (\(logs.count) sessions)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(SottoTheme.warning)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SottoTheme.surfaceVariant.opacity(0.5))
            .cornerRadius(12)
            
            Text("Choose how you would like to import this backup:")
                .font(.system(size: 14))
                .foregroundColor(SottoTheme.textSecondary)
                .padding(.top, 4)
            
            // Merge Button
            Button(action: {
                onMerge()
                onDismiss()
            }) {
                VStack(spacing: 2) {
                    Text("Merge with Existing Library")
                        .font(.system(size: 15, weight: .bold))
                    Text("Adds new phrases and categories without deleting existing items")
                        .font(.system(size: 12))
                        .opacity(0.8)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(SottoTheme.primary)
                .cornerRadius(12)
            }
            
            // Replace Button
            Button(action: {
                showReplaceConfirm = true
            }) {
                VStack(spacing: 2) {
                    Text("Replace Entire Library")
                        .font(.system(size: 15, weight: .bold))
                    Text("Replaces library with backup file (preserves Emergency)")
                        .font(.system(size: 12))
                        .opacity(0.8)
                }
                .foregroundColor(SottoTheme.destructiveRed)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(SottoTheme.destructiveRed.opacity(0.12))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SottoTheme.destructiveRed.opacity(0.4), lineWidth: 1)
                )
            }
        }
    }
}
