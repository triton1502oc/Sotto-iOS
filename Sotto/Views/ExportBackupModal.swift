import SwiftUI

public struct ExportBackupModal: View {
    public let phraseCount: Int
    public let areaCount: Int
    public let logCount: Int
    public let onExport: (_ exportPhrases: Bool, _ exportTree: Bool, _ exportLog: Bool) -> Void
    public var onShareQR: ((_ exportPhrases: Bool, _ exportTree: Bool, _ exportLog: Bool) -> Void)? = nil
    public let onDismiss: () -> Void
    
    @State private var exportPhrases: Bool = true
    @State private var exportTree: Bool = true
    @State private var exportLog: Bool = false
    
    public init(
        phraseCount: Int,
        areaCount: Int,
        logCount: Int,
        onExport: @escaping (Bool, Bool, Bool) -> Void,
        onShareQR: ((Bool, Bool, Bool) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.phraseCount = phraseCount
        self.areaCount = areaCount
        self.logCount = logCount
        self.onExport = onExport
        self.onShareQR = onShareQR
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
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            onExport(exportPhrases, exportTree, exportLog)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export .sotto File (AirDrop / Files)")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(hasSelection ? SottoTheme.onPrimary : SottoTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(hasSelection ? SottoTheme.primary : SottoTheme.surfaceVariant)
                            .cornerRadius(12)
                        }
                        .disabled(!hasSelection)
                        
                        if let onShareQR = onShareQR {
                            Button(action: {
                                onShareQR(exportPhrases, exportTree, exportLog)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "qrcode")
                                    Text("Share Phrases via QR Code")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(SottoTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(exportPhrases ? SottoTheme.surfaceVariant : SottoTheme.surfaceVariant.opacity(0.5))
                                .cornerRadius(12)
                            }
                            .disabled(!exportPhrases)
                            
                            Text("💡 QR codes are optimized for vocabulary phrase decks. Full backups with question trees and logs are shared via .sotto File.")
                                .font(.system(size: 12))
                                .foregroundColor(SottoTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                    }
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
