import Foundation

public enum BackupError: LocalizedError {
    case emptyContent
    case unrecognizedFormat
    case noValidDataFound
    case jsonParsingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Backup content is empty"
        case .unrecognizedFormat:
            return "Unrecognized backup format"
        case .noValidDataFound:
            return "No valid phrases, question tree, or logs found in backup"
        case .jsonParsingFailed(let msg):
            return "Failed to parse backup JSON: \(msg)"
        }
    }
}

public enum PhraseBackupHelper {
    public static let currentVersion = 2
    
    /// Serializes phrases, categories, and optional Why Finder tree and logs into JSON formatted string.
    public static func exportToJson(
        phrases: [Phrase]? = nil,
        categories: [String]? = nil,
        whyTree: WhyTree? = nil,
        whyLog: [WhyLogEntry]? = nil
    ) -> String {
        var root: [String: Any] = [
            "version": currentVersion,
            "exportedAt": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        
        if let categories = categories {
            var cleanCategories: [String] = []
            for cat in categories {
                let trimmed = cat.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && trimmed.uppercased() != "ALL" && !cleanCategories.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                    cleanCategories.append(trimmed)
                }
            }
            root["categories"] = cleanCategories
        }
        
        if let phrases = phrases {
            var phrasesArray: [[String: Any]] = []
            for phrase in phrases {
                var obj: [String: Any] = [
                    "text": phrase.text,
                    "language": phrase.language,
                    "isEmergency": phrase.isEmergency,
                    "category": phrase.category.rawValue
                ]
                if let spoken = phrase.spokenText?.trimmingCharacters(in: .whitespacesAndNewlines), !spoken.isEmpty && spoken != LocaleHelper.langAuto {
                    obj["spokenText"] = spoken
                }
                if let spokenLang = phrase.spokenLanguage?.trimmingCharacters(in: .whitespacesAndNewlines), !spokenLang.isEmpty && spokenLang != LocaleHelper.langAuto {
                    obj["spokenLanguage"] = spokenLang
                }
                phrasesArray.append(obj)
            }
            root["phrases"] = phrasesArray
        }
        
        if let whyTree = whyTree,
           let treeData = try? JSONEncoder().encode(whyTree),
           let treeObj = try? JSONSerialization.jsonObject(with: treeData) {
            root["whyTree"] = treeObj
        }
        
        if let whyLog = whyLog,
           let logData = try? JSONEncoder().encode(whyLog),
           let logObj = try? JSONSerialization.jsonObject(with: logData) {
            root["whyLog"] = logObj
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]),
              let jsonStr = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return jsonStr
    }
    
    public static func exportToJson(phrases: [Phrase], categories: [String]) -> String {
        return exportToJson(phrases: phrases, categories: categories, whyTree: nil, whyLog: nil)
    }
    
    public static func parseJson(_ jsonString: String) -> BackupData? {
        try? parseBackupJson(jsonString)
    }
    
    /// Parses a JSON string containing either a structured backup object or a raw array of phrases.
    public static func parseBackupJson(_ jsonString: String) throws -> BackupData {
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw BackupError.emptyContent
        }
        
        guard let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            throw BackupError.unrecognizedFormat
        }
        
        var categoriesList: [String] = []
        var phrasesList: [Phrase] = []
        var version = currentVersion
        var exportedAt = Int64(Date().timeIntervalSince1970 * 1000)
        var whyTree: WhyTree? = nil
        var whyLog: [WhyLogEntry]? = nil
        
        if let dict = json as? [String: Any] {
            version = dict["version"] as? Int ?? currentVersion
            if let exp = dict["exportedAt"] as? NSNumber {
                exportedAt = exp.int64Value
            }
            
            if let cats = dict["categories"] as? [String] {
                for cat in cats {
                    let cTrim = cat.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cTrim.isEmpty && cTrim.uppercased() != "ALL" && !categoriesList.contains(where: { $0.caseInsensitiveCompare(cTrim) == .orderedSame }) {
                        categoriesList.append(cTrim)
                    }
                }
            }
            
            if let phrasesArr = dict["phrases"] as? [Any] {
                parsePhrasesArray(phrasesArr, into: &phrasesList)
            }
            
            if let treeObj = dict["whyTree"],
               let treeData = try? JSONSerialization.data(withJSONObject: treeObj),
               let decodedTree = try? JSONDecoder().decode(WhyTree.self, from: treeData) {
                whyTree = decodedTree
            }
            
            if let logObj = dict["whyLog"],
               let logData = try? JSONSerialization.data(withJSONObject: logObj),
               let decodedLog = try? JSONDecoder().decode([WhyLogEntry].self, from: logData) {
                whyLog = decodedLog
            }
        } else if let arr = json as? [Any] {
            parsePhrasesArray(arr, into: &phrasesList)
        } else {
            throw BackupError.unrecognizedFormat
        }
        
        if phrasesList.isEmpty && whyTree == nil && (whyLog?.isEmpty ?? true) {
            throw BackupError.noValidDataFound
        }
        
        // Ensure categories represented in phrases are in categoriesList
        for phrase in phrasesList {
            let cat = phrase.category.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cat.isEmpty && cat.uppercased() != "ALL" && !categoriesList.contains(where: { $0.caseInsensitiveCompare(cat) == .orderedSame }) {
                categoriesList.append(cat)
            }
        }
        
        ensureSystemCategories(&categoriesList)
        
        return BackupData(
            version: version,
            exportedAt: exportedAt,
            categories: categoriesList,
            phrases: phrasesList,
            whyTree: whyTree,
            whyLog: whyLog
        )
    }
    
    private static func parsePhrasesArray(_ array: [Any], into targetList: inout [Phrase]) {
        for item in array {
            if let dict = item as? [String: Any] {
                let text = (dict["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                
                let spoken = (dict["spokenText"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let validSpoken = (spoken != nil && !spoken!.isEmpty && spoken != LocaleHelper.langAuto) ? spoken : nil
                
                let spokenLang = (dict["spokenLanguage"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let validSpokenLang = (spokenLang != nil && !spokenLang!.isEmpty && spokenLang != LocaleHelper.langAuto) ? spokenLang : nil
                
                let lang = (dict["language"] as? String ?? LocaleHelper.langAuto).isEmpty ? LocaleHelper.langAuto : (dict["language"] as? String ?? LocaleHelper.langAuto)
                let isEmergency = dict["isEmergency"] as? Bool ?? false
                let rawCategory = (dict["category"] as? String ?? (isEmergency ? "Emergency" : "General")).trimmingCharacters(in: .whitespacesAndNewlines)
                let finalCategory: String
                if isEmergency {
                    finalCategory = "Emergency"
                } else if rawCategory.caseInsensitiveCompare("Emergency") == .orderedSame || rawCategory.isEmpty {
                    finalCategory = "General"
                } else {
                    finalCategory = rawCategory
                }
                
                targetList.append(Phrase(
                    text: text,
                    spokenText: validSpoken,
                    spokenLanguage: validSpokenLang,
                    language: lang,
                    isEmergency: isEmergency,
                    category: PhraseCategory(rawValue: finalCategory)
                ))
            } else if let str = item as? String {
                let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    targetList.append(Phrase(text: trimmed, category: .general))
                }
            }
        }
    }
    
    private static func ensureSystemCategories(_ list: inout [String]) {
        if !list.contains(where: { $0.caseInsensitiveCompare("Emergency") == .orderedSame }) {
            list.insert("Emergency", at: 0)
        }
        if !list.contains(where: { $0.caseInsensitiveCompare("General") == .orderedSame }) {
            list.append("General")
        }
    }
    
    /// Merges imported data with current data.
    /// Deduplicates phrases by (text + category) and preserves existing ordering.
    public static func mergeData(
        currentPhrases: [Phrase],
        currentCategories: [String],
        backup: BackupData
    ) -> ([Phrase], [String]) {
        var mergedCategories = currentCategories
        ensureSystemCategories(&mergedCategories)
        
        for cat in backup.categories {
            let trimmed = cat.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed.uppercased() != "ALL" && !mergedCategories.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                if let generalIndex = mergedCategories.firstIndex(where: { $0.caseInsensitiveCompare("General") == .orderedSame }) {
                    mergedCategories.insert(trimmed, at: generalIndex)
                } else {
                    mergedCategories.append(trimmed)
                }
            }
        }
        
        var mergedPhrases = currentPhrases
        for newPhrase in backup.phrases {
            let exists = mergedPhrases.contains { existing in
                existing.text.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(newPhrase.text.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame &&
                existing.category.rawValue.caseInsensitiveCompare(newPhrase.category.rawValue) == .orderedSame
            }
            if !exists {
                mergedPhrases.append(newPhrase)
                let cat = newPhrase.category.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cat.isEmpty && cat.uppercased() != "ALL" && !mergedCategories.contains(where: { $0.caseInsensitiveCompare(cat) == .orderedSame }) {
                    if let generalIndex = mergedCategories.firstIndex(where: { $0.caseInsensitiveCompare("General") == .orderedSame }) {
                        mergedCategories.insert(cat, at: generalIndex)
                    } else {
                        mergedCategories.append(cat)
                    }
                }
            }
        }
        
        return (mergedPhrases, mergedCategories)
    }
    
    /// Replaces current data with backup data.
    /// Preserves protected system categories and ensures an emergency phrase is present.
    public static func replaceData(
        currentPhrases: [Phrase],
        backup: BackupData
    ) -> ([Phrase], [String]) {
        var newCategories = backup.categories
        ensureSystemCategories(&newCategories)
        
        var newPhrases = backup.phrases
        if !newPhrases.contains(where: { $0.isEmergency }) {
            let existingEmergency = currentPhrases.filter { $0.isEmergency }
            if !existingEmergency.isEmpty {
                newPhrases.insert(contentsOf: existingEmergency, at: 0)
            }
        }
        
        for phrase in newPhrases {
            let cat = phrase.category.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cat.isEmpty && cat.uppercased() != "ALL" && !newCategories.contains(where: { $0.caseInsensitiveCompare(cat) == .orderedSame }) {
                if let generalIndex = newCategories.firstIndex(where: { $0.caseInsensitiveCompare("General") == .orderedSame }) {
                    newCategories.insert(cat, at: generalIndex)
                } else {
                    newCategories.append(cat)
                }
            }
        }
        
        return (newPhrases, newCategories)
    }
    
    /// Merges imported logs with current logs, deduplicating by ID and sorting descending by timestamp.
    public static func mergeLogs(currentLogs: [WhyLogEntry], backupLogs: [WhyLogEntry]) -> [WhyLogEntry] {
        let existingIds = Set(currentLogs.map { $0.id })
        let newEntries = backupLogs.filter { !existingIds.contains($0.id) }
        let combined = currentLogs + newEntries
        return Array(combined.sorted(by: { $0.startedAt > $1.startedAt }).prefix(UserDefaultsWhyFinderRepository.maxLogEntries))
    }
}
