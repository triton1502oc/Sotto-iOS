import SwiftUI

public struct WhyLogModal: View {
    @Environment(\.sottoPalette) private var palette
    public let repository: WhyFinderRepositoryProtocol
    public let onDismiss: () -> Void
    
    @State private var logs: [WhyLogEntry]
    @State private var showClearConfirm: Bool = false
    @State private var entryToDelete: WhyLogEntry? = nil
    
    public init(
        repository: WhyFinderRepositoryProtocol = UserDefaultsWhyFinderRepository.shared,
        onDismiss: @escaping () -> Void
    ) {
        self.repository = repository
        self.onDismiss = onDismiss
        var initialLogs = repository.getLogs()
        if initialLogs.isEmpty && (ProcessInfo.processInfo.arguments.contains("--whylog") || ProcessInfo.processInfo.arguments.contains("--screenshot-whylog")) {
            let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
            initialLogs = [
                WhyLogEntry(
                    id: UUID().uuidString,
                    startedAt: nowMs - 3600_000 * 2,
                    endedAt: nowMs - 3600_000 * 2 + 180_000,
                    outcome: .found,
                    areaId: "sensory",
                    causeText: "Room is too loud or bright",
                    bodyPart: nil,
                    intensity: 3,
                    note: "Moved to quiet sensory corner."
                ),
                WhyLogEntry(
                    id: UUID().uuidString,
                    startedAt: nowMs - 86400_000 * 2,
                    endedAt: nowMs - 86400_000 * 2 + 120_000,
                    outcome: .found,
                    areaId: "physical",
                    causeText: "Headache or sensory migraine",
                    bodyPart: "head",
                    intensity: 4,
                    note: "Offered dim lighting and ice pack."
                )
            ]
        }
        _logs = State(initialValue: initialLogs)
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                palette.surface
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    if logs.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // 30-Day Patterns Card
                                let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
                                let recentLogs = logs.filter { Date(timeIntervalSince1970: Double($0.startedAt) / 1000.0) >= thirtyDaysAgo }
                                if !recentLogs.isEmpty {
                                    patternsCard(recentLogs)
                                }
                                
                                // Entries List
                                ForEach(logs) { entry in
                                    entryCard(entry)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Private Why Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !logs.isEmpty {
                        Button(action: {
                            showClearConfirm = true
                        }) {
                            Text("Clear All")
                                .font(.system(size: 14))
                                .foregroundColor(SottoTheme.danger)
                                .frame(minHeight: 44)
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(SottoTheme.confirm)
                            .frame(minHeight: 44)
                    }
                }
            }
            .alert("Clear All Logs?", isPresented: $showClearConfirm) {
                Button("Clear All", role: .destructive) {
                    repository.clearLogs()
                    logs = []
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all stored Why Finder session records.")
            }
            .alert("Delete Log Entry?", isPresented: Binding(
                get: { entryToDelete != nil },
                set: { if !$0 { entryToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        _ = repository.deleteLog(id: entry.id)
                        logs = repository.getLogs()
                    }
                    entryToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    entryToDelete = nil
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle()
                    .fill(palette.accent.opacity(0.12))
                    .frame(width: 64, height: 64)
                SottoIconView(.docTextMagnifyingglass, size: 32, tint: palette.accent)
            }
            Text("No sessions recorded yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(palette.textSecondary)
            Text("Completed Why Finder sessions will appear here privately.")
                .font(.system(size: 13))
                .foregroundColor(palette.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    // MARK: - 30-Day Patterns Card
    
    private func patternsCard(_ recentLogs: [WhyLogEntry]) -> some View {
        let totalCount = recentLogs.count
        let foundCount = recentLogs.filter { $0.outcome == .found }.count
        
        // Top cause
        let foundWithCause = recentLogs.filter { $0.outcome == .found && !($0.causeText?.isEmpty ?? true) }
        let causeCounts = Dictionary(grouping: foundWithCause) { entry -> String in
            let cause = entry.causeText ?? ""
            if let part = entry.bodyPart, !part.isEmpty {
                return "\(cause) (\(LocaleHelper.getBodyRegionLabel(part)))"
            }
            return cause
        }.mapValues { $0.count }
        let topCause = causeCounts.max(by: { $0.value < $1.value })
        
        // Top area
        let areaCounts = Dictionary(grouping: recentLogs.compactMap { $0.areaId }) { $0 }.mapValues { $0.count }
        let topArea = areaCounts.max(by: { $0.value < $1.value })
        
        // Time summary
        var timeBuckets: [String: Int] = [:]
        for entry in recentLogs {
            let date = Date(timeIntervalSince1970: Double(entry.startedAt) / 1000.0)
            let hour = Calendar.current.component(.hour, from: date)
            let bucket: String
            switch hour {
            case 5...11: bucket = "Morning"
            case 12...16: bucket = "Afternoon"
            case 17...21: bucket = "Evening"
            default: bucket = "Night"
            }
            timeBuckets[bucket, default: 0] += 1
        }
        let timeSummary = timeBuckets.sorted { $0.value > $1.value }
            .map { "\($0.key) (\($0.value))" }
            .joined(separator: ", ")
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                SottoIconView(.analytics, size: 16, tint: palette.accent)
                Text("30-Day Patterns")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                Spacer()
                Text("\(foundCount) / \(totalCount) resolved")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(palette.accent)
            }
            
            if let cause = topCause {
                Text("Top cause: \(cause.key) • \(cause.value) times")
                    .font(.system(size: 13))
                    .foregroundColor(palette.textSecondary)
            }
            
            if let area = topArea {
                Text("Frequent category: \(LocaleHelper.getAreaDisplayName(area.key))")
                    .font(.system(size: 13))
                    .foregroundColor(palette.textSecondary)
            }
            
            if !timeSummary.isEmpty {
                Text("Most frequent times: \(timeSummary)")
                    .font(.system(size: 13))
                    .foregroundColor(palette.textSecondary)
            }
        }
        .padding(14)
        .background(palette.accent.opacity(0.12))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(palette.accent.opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Entry Card
    
    private func entryCard(_ entry: WhyLogEntry) -> some View {
        let date = Date(timeIntervalSince1970: Double(entry.startedAt) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateStr = formatter.string(from: date)
        
        let outcomeColor: Color
        let outcomeIcon: SottoIcon
        let outcomeText: String
        switch entry.outcome {
        case .found:
            outcomeColor = SottoTheme.successGreen
            outcomeIcon = .target
            outcomeText = "Resolved"
        case .stopped:
            outcomeColor = SottoTheme.warning
            outcomeIcon = .pause
            outcomeText = "Stopped"
        case .notFound:
            outcomeColor = SottoTheme.textSecondary
            outcomeIcon = .search
            outcomeText = "Unresolved"
        }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    SottoIconView(outcomeIcon, size: 13, tint: outcomeColor)
                    Text(outcomeText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(outcomeColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(outcomeColor.opacity(0.15))
                .cornerRadius(8)
                
                Spacer()
                
                Text(dateStr)
                    .font(.system(size: 12))
                    .foregroundColor(palette.textSecondary.opacity(0.7))
                
                Button(action: {
                    entryToDelete = entry
                }) {
                    SottoIconView(.delete, size: 15, tint: SottoTheme.danger.opacity(0.75))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Delete log entry")
            }
            
            if let cause = entry.causeText, !cause.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cause)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                    
                    if let part = entry.bodyPart, !part.isEmpty {
                        let partLabel = LocaleHelper.getBodyRegionLabel(part)
                        let intensityStr = entry.intensity != nil ? " • Intensity: \(entry.intensity!)/5" : ""
                        Text("\(partLabel)\(intensityStr)")
                            .font(.system(size: 13))
                            .foregroundColor(palette.accent)
                    }
                }
            }
            
            HStack(spacing: 8) {
                if let areaId = entry.areaId {
                    Text(LocaleHelper.getAreaDisplayName(areaId))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(palette.surfaceVariant)
                        .cornerRadius(6)
                }
                
                Text("\(entry.steps.count) steps")
                    .font(.system(size: 12))
                    .foregroundColor(palette.textSecondary.opacity(0.7))
            }
            
            if let note = entry.privateNote, !note.isEmpty {
                HStack(spacing: 6) {
                    SottoIconView(.noteAlt, size: 13, tint: palette.textSecondary)
                    Text(note)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(palette.textSecondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(palette.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(palette.outlineVariant, lineWidth: 1)
        )
    }
}
