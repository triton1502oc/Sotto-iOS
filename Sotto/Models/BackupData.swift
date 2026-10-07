import Foundation

public struct BackupData: Codable, Equatable {
    public var version: Int
    public var exportedAt: Int64
    public var categories: [String]
    public var phrases: [Phrase]
    public var whyTree: WhyTree?
    public var whyLog: [WhyLogEntry]?
    
    public init(
        version: Int = 2,
        exportedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        categories: [String] = [],
        phrases: [Phrase] = [],
        whyTree: WhyTree? = nil,
        whyLog: [WhyLogEntry]? = nil
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.categories = categories
        self.phrases = phrases
        self.whyTree = whyTree
        self.whyLog = whyLog
    }
}

public struct ImportResult: Equatable {
    public var phraseCount: Int
    public var categoryCount: Int
    public var treeImported: Bool
    public var logCount: Int
    
    public init(phraseCount: Int, categoryCount: Int, treeImported: Bool = false, logCount: Int = 0) {
        self.phraseCount = phraseCount
        self.categoryCount = categoryCount
        self.treeImported = treeImported
        self.logCount = logCount
    }
}
