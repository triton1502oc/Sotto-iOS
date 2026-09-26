import Foundation

public enum PhraseCategory: String, Codable, CaseIterable, Identifiable {
    case all = "ALL"
    case emergency = "Emergency"
    case needs = "Needs"
    case social = "Social"
    case care = "Care"
    case general = "General"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .all: return "All"
        case .emergency: return "Emergency"
        case .needs: return "Needs"
        case .social: return "Social"
        case .care: return "Care"
        case .general: return "General"
        }
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
        if let catString = try container.decodeIfPresent(String.self, forKey: .category) {
            self.category = PhraseCategory(rawValue: catString) ?? (emergency ? .emergency : .general)
        } else {
            self.category = emergency ? .emergency : .general
        }
    }
}
