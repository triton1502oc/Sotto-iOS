import Foundation

public enum WhyQuestionType: String, Codable, Equatable {
    case yesNo = "YES_NO"
    case bodyMap = "BODY_MAP"
    case scale = "SCALE"
    
    public static let plain = WhyQuestionType.yesNo
    public static let bodyPart = WhyQuestionType.bodyMap
    public static let intensity = WhyQuestionType.scale
}

public struct WhyQuestion: Identifiable, Codable, Equatable {
    public var id: String
    public var text: String
    public var type: WhyQuestionType
    
    public init(id: String, text: String, type: WhyQuestionType = .yesNo) {
        self.id = id
        self.text = text
        self.type = type
    }
}

public struct WhyArea: Identifiable, Codable, Equatable {
    public var id: String
    public var question: String
    public var questions: [WhyQuestion]
    
    public init(id: String, question: String, questions: [WhyQuestion]) {
        self.id = id
        self.question = question
        self.questions = questions
    }
}

public struct WhyTree: Codable, Equatable {
    public var areas: [WhyArea]
    
    public init(areas: [WhyArea] = []) {
        self.areas = areas
    }
}

public enum WhyOutcome: String, Codable, Equatable {
    case found = "FOUND"
    case notFound = "NOT_FOUND"
    case stopped = "STOPPED"
}

public struct WhyStep: Codable, Equatable {
    public var questionText: String
    public var answer: String // "yes" | "no" | "not_sure"
    
    public init(questionText: String, answer: String) {
        self.questionText = questionText
        self.answer = answer
    }
}

public struct WhyLogEntry: Identifiable, Codable, Equatable {
    public var id: String
    public var startedAt: Int64
    public var endedAt: Int64
    public var outcome: WhyOutcome
    public var areaId: String?
    public var causeText: String?
    public var bodyPart: String?
    public var intensity: Int? // 1 to 5
    public var note: String?
    public var privateNote: String? {
        get { note }
        set { note = newValue }
    }
    public var steps: [WhyStep]
    
    public init(
        id: String,
        startedAt: Int64,
        endedAt: Int64,
        outcome: WhyOutcome,
        areaId: String? = nil,
        causeText: String? = nil,
        bodyPart: String? = nil,
        intensity: Int? = nil,
        note: String? = nil,
        privateNote: String? = nil,
        steps: [WhyStep] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.outcome = outcome
        self.areaId = areaId
        self.causeText = causeText
        self.bodyPart = bodyPart
        self.intensity = intensity
        self.note = privateNote ?? note
        self.steps = steps
    }
}

public enum BodyRegions {
    public static let head = "head"
    public static let eyes = "eyes"
    public static let ears = "ears"
    public static let teeth = "teeth"
    public static let throat = "throat"
    public static let chest = "chest"
    public static let stomach = "stomach"
    public static let back = "back"
    public static let armsHands = "arms_hands"
    public static let legsFeet = "legs_feet"
    public static let skin = "skin"
    
    public static let all: [String] = [
        head, eyes, ears, teeth, throat, chest, stomach, back, armsHands, legsFeet, skin
    ]
}
