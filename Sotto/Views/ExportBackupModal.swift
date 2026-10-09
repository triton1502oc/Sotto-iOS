import SwiftUI

public struct ExportBackupModal: View {
    public let phraseCount: Int
    public let areaCount: Int
    public let logCount: Int
    public let onExport: (_ exportPhrases: Bool, _ exportTree: Bool, _ exportLog: Bool) -> Void
    public let onDismiss: () -> Void
    
    @State private var exportPhrases: Bool = true
    @State private var exportTree: Bool = true
    @State private var exportLog: Bool = false
    
    public init(
        phraseCount: Int,
        areaCount: Int,
        logCount: Int,
        onExport: @escaping (Bool, Bool, Bool) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.phraseCount = phraseCount
        self.areaCount = areaCount
        self.logCount = logCount
        self.onExport = onExport
        self.onDismiss = onDismiss
    }
    
    private var hasSelection: Bool {
        exportPhrases || exportTree || exportLog
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                SottoTheme.surface
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Export library phrases, categories, question trees, or private logs as a backup file.")
                        .font(.system(size: 14))
                        .foregroundColor(SottoTheme.textSecondary)
                    
                    VStack(spacing: 12) {
                        // Option 1: Phrases & Categories
                        Toggle(isOn: $exportPhrases) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Phrases & Categories")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(SottoTheme.textPrimary)
                                Text("\(phraseCount) phrases")
                                    .font(.system(size: 13))
                                    .foregroundColor(SottoTheme.textSecondary)
                            }
                        }
                        .tint(SottoTheme.primary)
                        .padding(12)
                        .background(SottoTheme.surfaceVariant.opacity(0.4))
                        .cornerRadius(12)
                        
                        // Option 2: Question Tree
                        Toggle(isOn: $exportTree) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Why Finder Question Tree")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(SottoTheme.textPrimary)
                                Text("\(areaCount) narrowing areas")
                                    .font(.system(size: 13))
                                    .foregroundColor(SottoTheme.textSecondary)
                            }
                        }
                        .tint(SottoTheme.primary)
                        .padding(12)
                        .background(SottoTheme.surfaceVariant.opacity(0.4))
                        .cornerRadius(12)
                        
                        // Option 3: Private Why Log
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: $exportLog) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Private Why Log")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(SottoTheme.textPrimary)
                                    Text("\(logCount) saved session records")
                                        .font(.system(size: 13))
                                        .foregroundColor(SottoTheme.textSecondary)
                                }
                            }
                            .tint(SottoTheme.primary)
                            
                            if exportLog {
                                Text("⚠️ Caution: Includes sensitive offline logs with health/care notes.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(SottoTheme.destructiveRed)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(12)
                        .background(
                            exportLog
                                ? SottoTheme.destructiveRed.opacity(0.12)
                                : SottoTheme.surfaceVariant.opacity(0.4)
                        )
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onExport(exportPhrases, exportTree, exportLog)
                    }) {
                        Text("Export Backup")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(hasSelection ? .white : SottoTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(hasSelection ? SottoTheme.primary : SottoTheme.surfaceVariant)
                            .cornerRadius(12)
                    }
                    .disabled(!hasSelection)
                }
                .padding(20)
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
}
