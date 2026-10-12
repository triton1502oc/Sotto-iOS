import SwiftUI

public struct ExportBackupModal: View {
    @Environment(\.sottoPalette) private var palette
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
                palette.surface
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 18) {
                    Text("Export library phrases, categories, question trees, or private logs as a backup file.")
                        .font(.system(size: 14))
                        .foregroundColor(palette.textSecondary)
                    
                    VStack(spacing: 10) {
                        // Option 1: Phrases & Categories
                        selectableOptionCard(
                            checked: exportPhrases,
                            onToggle: { exportPhrases.toggle() },
                            icon: .cards,
                            title: "Phrases & Categories",
                            subtitle: "\(phraseCount) phrases"
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
                            onShareQR(exportPhrases, exportTree, exportLog)
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
                        .disabled(!hasSelection)
                        .opacity(hasSelection ? 1.0 : 0.5)
                    }
                    
                    Spacer()
                    
                    // Export File Action Button
                    Button(action: {
                        onExport(exportPhrases, exportTree, exportLog)
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
    private func selectableOptionCard(
        checked: Bool,
        onToggle: @escaping () -> Void,
        icon: SottoIcon,
        title: String,
        subtitle: String,
        warning: String? = nil
    ) -> some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
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
                
                if let warn = warning {
                    HStack(spacing: 6) {
                        SottoIconView(.warning, size: 13, tint: SottoTheme.danger)
                        Text(warn)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SottoTheme.danger)
                    }
                    .padding(.leading, 48)
                }
            }
            .padding(12)
            .background(checked ? palette.accent.opacity(0.08) : palette.surfaceVariant.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(checked ? palette.accent : palette.outlineVariant.opacity(0.35), lineWidth: checked ? 1.5 : 1)
            )
            .contentShape(Rectangle())
        }
    }
}
