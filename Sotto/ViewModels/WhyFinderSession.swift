import Foundation
import SwiftUI

public enum WhyFinderState: Equatable {
    case askingArea(areaIndex: Int, area: WhyArea)
    case askingQuestion(areaIndex: Int, questionIndex: Int, question: WhyQuestion)
    case selectingBodyPart(areaIndex: Int, questionIndex: Int, question: WhyQuestion)
    case selectingIntensity(areaIndex: Int, questionIndex: Int, question: WhyQuestion, bodyPart: String)
    case confirmingCause(areaIndex: Int, questionIndex: Int, causeText: String, bodyPart: String?, intensity: Int?)
    case finished(
        outcome: WhyOutcome,
        areaId: String?,
        causeText: String?,
        bodyPart: String?,
        intensity: Int?,
        steps: [WhyStep],
        startedAt: Int64,
        endedAt: Int64
    )
}


public final class WhyFinderSession: ObservableObject {
    public let tree: WhyTree
    public private(set) var startedAt: Int64
    public private(set) var sessionId: String
    
    @Published public private(set) var currentState: WhyFinderState
    
    private var recordedSteps: [WhyStep] = []
    private var historyStack: [WhyFinderState] = []
    
    public var steps: [WhyStep] {
        recordedSteps
    }
    
    public init(tree: WhyTree, startedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.tree = tree
        self.startedAt = startedAt
        self.sessionId = UUID().uuidString
        if let firstArea = tree.areas.first {
            self.currentState = .askingArea(areaIndex: 0, area: firstArea)
        } else {
            self.currentState = .finished(
                outcome: .notFound,
                areaId: nil,
                causeText: nil,
                bodyPart: nil,
                intensity: nil,
                steps: [],
                startedAt: startedAt,
                endedAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
        }
    }
    
    public func canStepBack() -> Bool {
        !historyStack.isEmpty
    }
    
    public func answerYes() {
        switch currentState {
        case .askingArea(let areaIndex, let area):
            historyStack.append(currentState)
            recordedSteps.append(WhyStep(questionText: area.question, answer: "yes"))
            if let firstQuestion = area.questions.first {
                currentState = .askingQuestion(areaIndex: areaIndex, questionIndex: 0, question: firstQuestion)
            } else {
                moveToNextArea(currentAreaIndex: areaIndex)
            }
            
        case .askingQuestion(let areaIndex, let questionIndex, let question):
            historyStack.append(currentState)
            recordedSteps.append(WhyStep(questionText: question.text, answer: "yes"))
            switch question.type {
            case .bodyMap:
                currentState = .selectingBodyPart(areaIndex: areaIndex, questionIndex: questionIndex, question: question)
            case .scale:
                currentState = .selectingIntensity(areaIndex: areaIndex, questionIndex: questionIndex, question: question, bodyPart: "")
            case .yesNo:
                currentState = .confirmingCause(areaIndex: areaIndex, questionIndex: questionIndex, causeText: question.text, bodyPart: nil, intensity: nil)
            }
            
        case .confirmingCause(let areaIndex, _, let causeText, let bodyPart, let intensity):
            historyStack.append(currentState)
            recordedSteps.append(WhyStep(questionText: causeText, answer: "yes"))
            let areaId = (areaIndex < tree.areas.count) ? tree.areas[areaIndex].id : nil
            currentState = .finished(
                outcome: .found,
                areaId: areaId,
                causeText: causeText,
                bodyPart: bodyPart,
                intensity: intensity,
                steps: recordedSteps,
                startedAt: startedAt,
                endedAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
            
        case .selectingBodyPart, .selectingIntensity, .finished:
            break
        }
    }
    
    public func answerNo() {
        handleNegativeAnswer(answerKey: "no")
    }
    
    public func answerNotSure() {
        handleNegativeAnswer(answerKey: "not_sure")
    }
    
    private func handleNegativeAnswer(answerKey: String) {
        switch currentState {
        case .askingArea(let areaIndex, let area):
            historyStack.append(currentState)
            recordedSteps.append(WhyStep(questionText: area.question, answer: answerKey))
            moveToNextArea(currentAreaIndex: areaIndex)
            
        case .askingQuestion(let areaIndex, let questionIndex, let question):
            historyStack.append(currentState)
            recordedSteps.append(WhyStep(questionText: question.text, answer: answerKey))
            guard areaIndex < tree.areas.count else { return }
            let area = tree.areas[areaIndex]
            let nextQ = questionIndex + 1
            if nextQ < area.questions.count {
                currentState = .askingQuestion(areaIndex: areaIndex, questionIndex: nextQ, question: area.questions[nextQ])
            } else {
                moveToNextArea(currentAreaIndex: areaIndex)
            }
            
        case .confirmingCause(let areaIndex, let questionIndex, let causeText, _, _):
            historyStack.append(currentState)
            recordedSteps.append(WhyStep(questionText: causeText, answer: answerKey))
            guard areaIndex < tree.areas.count else { return }
            let area = tree.areas[areaIndex]
            let nextQ = questionIndex + 1
            if nextQ < area.questions.count {
                currentState = .askingQuestion(areaIndex: areaIndex, questionIndex: nextQ, question: area.questions[nextQ])
            } else {
                moveToNextArea(currentAreaIndex: areaIndex)
            }
            
        case .selectingBodyPart(let areaIndex, let questionIndex, let question),
             .selectingIntensity(let areaIndex, let questionIndex, let question, _):
            historyStack.append(currentState)
            currentState = .confirmingCause(
                areaIndex: areaIndex,
                questionIndex: questionIndex,
                causeText: question.text,
                bodyPart: nil,
                intensity: nil
            )
            
        case .finished:
            break
        }
    }
    
    private func moveToNextArea(currentAreaIndex: Int) {
        let nextArea = currentAreaIndex + 1
        if nextArea < tree.areas.count {
            currentState = .askingArea(areaIndex: nextArea, area: tree.areas[nextArea])
        } else {
            currentState = .finished(
                outcome: .notFound,
                areaId: nil,
                causeText: nil,
                bodyPart: nil,
                intensity: nil,
                steps: recordedSteps,
                startedAt: startedAt,
                endedAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
        }
    }
    
    public func selectBodyPart(_ bodyPart: String) {
        guard case .selectingBodyPart(let areaIndex, let questionIndex, let question) = currentState else { return }
        historyStack.append(currentState)
        recordedSteps.append(WhyStep(questionText: "Body part: \(bodyPart)", answer: "selected"))
        currentState = .selectingIntensity(
            areaIndex: areaIndex,
            questionIndex: questionIndex,
            question: question,
            bodyPart: bodyPart
        )
    }
    
    public func selectIntensity(_ level: Int) {
        guard case .selectingIntensity(let areaIndex, let questionIndex, let question, let bodyPart) = currentState else { return }
        let clamped = max(1, min(5, level))
        historyStack.append(currentState)
        recordedSteps.append(WhyStep(questionText: "Intensity: \(clamped)/5", answer: "selected"))
        currentState = .confirmingCause(
            areaIndex: areaIndex,
            questionIndex: questionIndex,
            causeText: question.text,
            bodyPart: bodyPart,
            intensity: clamped
        )
    }
    
    public func stop() {
        if case .finished = currentState { return }
        let state = currentState
        historyStack.append(state)
        recordedSteps.append(WhyStep(questionText: "User tapped stop", answer: "stop"))
        
        let areaId: String?
        switch state {
        case .askingArea(_, let area):
            areaId = area.id
        case .askingQuestion(let areaIndex, _, _),
             .selectingBodyPart(let areaIndex, _, _),
             .selectingIntensity(let areaIndex, _, _, _),
             .confirmingCause(let areaIndex, _, _, _, _):
            areaId = (areaIndex < tree.areas.count) ? tree.areas[areaIndex].id : nil
        case .finished:
            areaId = nil
        }
        
        currentState = .finished(
            outcome: .stopped,
            areaId: areaId,
            causeText: nil,
            bodyPart: nil,
            intensity: nil,
            steps: recordedSteps,
            startedAt: startedAt,
            endedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }
    
    @discardableResult
    public func stepBack() -> Bool {
        guard !historyStack.isEmpty else { return false }
        let prevState = historyStack.removeLast()
        if !recordedSteps.isEmpty {
            recordedSteps.removeLast()
        }
        currentState = prevState
        return true
    }
    
    public func jumpToArea(areaIndex: Int) {
        guard areaIndex < tree.areas.count else { return }
        historyStack.append(currentState)
        currentState = .askingArea(areaIndex: areaIndex, area: tree.areas[areaIndex])
    }
    
    public func jumpToQuestion(areaIndex: Int, questionIndex: Int) {
        guard areaIndex < tree.areas.count else { return }
        let area = tree.areas[areaIndex]
        guard questionIndex < area.questions.count else { return }
        historyStack.append(currentState)
        currentState = .askingQuestion(areaIndex: areaIndex, questionIndex: questionIndex, question: area.questions[questionIndex])
    }
    
    public func restart() {
        self.sessionId = UUID().uuidString
        self.startedAt = Int64(Date().timeIntervalSince1970 * 1000)
        recordedSteps.removeAll()
        historyStack.removeAll()
        if let first = tree.areas.first {
            currentState = .askingArea(areaIndex: 0, area: first)
        } else {
            currentState = .finished(
                outcome: .notFound,
                areaId: nil,
                causeText: nil,
                bodyPart: nil,
                intensity: nil,
                steps: [],
                startedAt: startedAt,
                endedAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
        }
    }
    
    public func toLogEntry(note: String? = nil, privateNote: String? = nil) -> WhyLogEntry? {
        guard case .finished(let outcome, let areaId, let causeText, let bodyPart, let intensity, let steps, let start, let end) = currentState else {
            return nil
        }
        let chosenNote = privateNote ?? note
        let cleanNote = chosenNote?.trimmingCharacters(in: .whitespacesAndNewlines)
        return WhyLogEntry(
            id: sessionId,
            startedAt: start,
            endedAt: end,
            outcome: outcome,
            areaId: areaId,
            causeText: causeText,
            bodyPart: bodyPart,
            intensity: intensity,
            note: (cleanNote?.isEmpty ?? true) ? nil : cleanNote,
            steps: steps
        )
    }
}
