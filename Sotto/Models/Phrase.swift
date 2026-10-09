import Foundation

public struct PhraseCategory: RawRepresentable, Codable, Hashable, Identifiable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
    public var id: String { rawValue }
    public var description: String { rawValue }
    
    public static let all: PhraseCategory = "ALL"
    public static let emergency: PhraseCategory = "Emergency"
    public static let safety: PhraseCategory = "Emergency"
    public static let needs: PhraseCategory = "Needs"
    public static let social: PhraseCategory = "Social"
    public static let care: PhraseCategory = "Care"
    public static let general: PhraseCategory = "General"
    
    public static let defaultCategories: [PhraseCategory] = [
        .emergency, .needs, .social, .care, .general
    ]
    
    public static let defaultCategoryNames: [String] = [
        "Emergency", "Needs", "Social", "Care", "General"
    ]
    
    public var displayName: String {
        switch rawValue.uppercased() {
        case "ALL": return "All"
        case "EMERGENCY", "SAFETY": return "Safety"
        case "NEEDS": return "Needs"
        case "SOCIAL": return "Social"
        case "CARE": return "Care"
        case "GENERAL": return "General"
        default: return rawValue
        }
    }
    
    public static func isSystemCategory(_ category: String) -> Bool {
        let lower = category.lowercased()
        return lower == "all" || lower == "emergency" || lower == "safety" || lower == "general"
    }
    
    public static func isUndeletableCategory(_ category: String) -> Bool {
        let lower = category.lowercased()
        return lower == "all" || lower == "emergency" || lower == "safety" || lower == "general"
    }
    
    public static func isUnrenamableCategory(_ category: String) -> Bool {
        let lower = category.lowercased()
        return lower == "all" || lower == "emergency" || lower == "safety"
    }
    
    /// Categories available for assignment to a phrase (excludes "All")
    public static var selectableCategories: [PhraseCategory] {
        [.general, .needs, .social, .care, .emergency]
    }
    
    /// Filter categories displayed in the top chip bar
    public static var filterCategories: [PhraseCategory] {
        [.all, .emergency, .needs, .social, .care, .general]
    }
}

public struct Phrase: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var text: String
    public var spokenText: String?
    public var spokenLanguage: String?
    public var language: String
    public var isEmergency: Bool
    public var category: PhraseCategory
    
    public init(
        id: UUID = UUID(),
        text: String,
        spokenText: String? = nil,
        spokenLanguage: String? = nil,
        language: String = "auto",
        isEmergency: Bool = false,
        category: PhraseCategory = .general
    ) {
        self.id = id
        self.text = text
        self.spokenText = spokenText
        self.spokenLanguage = spokenLanguage
        self.language = language
        self.isEmergency = isEmergency
        self.category = isEmergency ? .emergency : category
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, spokenText, spokenLanguage, language, isEmergency, category
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.text = try container.decode(String.self, forKey: .text)
        self.spokenText = try container.decodeIfPresent(String.self, forKey: .spokenText)
        self.spokenLanguage = try container.decodeIfPresent(String.self, forKey: .spokenLanguage)
        self.language = try container.decodeIfPresent(String.self, forKey: .language) ?? "auto"
        let emergency = try container.decodeIfPresent(Bool.self, forKey: .isEmergency) ?? false
        self.isEmergency = emergency
        if let catString = try container.decodeIfPresent(String.self, forKey: .category), !catString.isEmpty {
            self.category = PhraseCategory(rawValue: catString)
        } else {
            self.category = emergency ? .emergency : .general
        }
    }
}

public extension Phrase {
    static let categoryGeneral = PhraseCategory.general.rawValue
    static let categoryEmergency = PhraseCategory.emergency.rawValue
    static let categorySafety = PhraseCategory.emergency.rawValue
    static let categoryNeeds = PhraseCategory.needs.rawValue
    static let categorySocial = PhraseCategory.social.rawValue
    static let categoryCare = PhraseCategory.care.rawValue
    
    static func isSystemCategory(_ category: String) -> Bool {
        PhraseCategory.isSystemCategory(category)
    }
    
    static func isUndeletableCategory(_ category: String) -> Bool {
        PhraseCategory.isUndeletableCategory(category)
    }
    
    static func isUnrenamableCategory(_ category: String) -> Bool {
        PhraseCategory.isUnrenamableCategory(category)
    }
}
