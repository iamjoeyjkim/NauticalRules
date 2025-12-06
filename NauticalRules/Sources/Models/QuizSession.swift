//
//  QuizSession.swift
//  NauticalRules
//
//  Model for tracking an active quiz session
//

import Foundation

// MARK: - Quiz Mode

enum QuizMode: Equatable, Hashable {
    case practice(category: QuestionCategory?)
    case exam(questionCount: Int, timeLimit: TimeInterval?)
    case quickQuiz(questionCount: Int)
    case review
    case study(category: QuestionCategory?)
    
    var displayName: String {
        switch self {
        case .practice(let category):
            if let cat = category {
                return "Practice: \(cat.shortName)"
            }
            return "Practice Mode"
        case .exam(let count, _):
            return "\(count)-Question Exam"
        case .quickQuiz(let count):
            return "\(count)-Question Quiz"
        case .review:
            return "Review Mistakes"
        case .study(let category):
            if let cat = category {
                return "Study: \(cat.shortName)"
            }
            return "Study Mode"
        }
    }
    
    var showsTimer: Bool {
        switch self {
        case .exam(_, let timeLimit):
            return timeLimit != nil
        default:
            return false
        }
    }
    
    var showsImmediateFeedback: Bool {
        switch self {
        case .practice, .study:
            return true
        case .exam, .review, .quickQuiz:
            return false
        }
    }
    
    var icon: String {
        switch self {
        case .practice: return "book.fill"
        case .exam: return "doc.text.fill"
        case .quickQuiz: return "bolt.fill"
        case .review: return "arrow.counterclockwise"
        case .study: return "eyeglasses"
        }
    }
}

// MARK: - Quiz Session

struct QuizSession: Identifiable {
    let id: UUID
    let mode: QuizMode
    let questions: [Question]
    var currentIndex: Int
    var answers: [Int: CorrectAnswer]  // Question ID -> User's Answer
    var startTime: Date
    var endTime: Date?
    var timeLimit: TimeInterval?
    
    init(
        id: UUID = UUID(),
        mode: QuizMode,
        questions: [Question],
        timeLimit: TimeInterval? = nil
    ) {
        self.id = id
        self.mode = mode
        self.questions = questions
        self.currentIndex = 0
        self.answers = [:]
        self.startTime = Date()
        self.endTime = nil
        self.timeLimit = timeLimit
    }
    
    // MARK: - Computed Properties
    
    var currentQuestion: Question? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var isComplete: Bool {
        return currentIndex >= questions.count || endTime != nil
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }
    
    var answeredCount: Int {
        return answers.count
    }
    
    var correctCount: Int {
        return answers.filter { questionId, answer in
            questions.first(where: { $0.id == questionId })?.isCorrect(answer) ?? false
        }.count
    }
    
    var incorrectCount: Int {
        return answeredCount - correctCount
    }
    
    var score: Double {
        guard answeredCount > 0 else { return 0 }
        return Double(correctCount) / Double(answeredCount) * 100
    }
    
    var elapsedTime: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var remainingTime: TimeInterval? {
        guard let limit = timeLimit else { return nil }
        let remaining = limit - elapsedTime
        return max(0, remaining)
    }
    
    var isTimeUp: Bool {
        guard let remaining = remainingTime else { return false }
        return remaining <= 0
    }
    
    // MARK: - Methods
    
    mutating func submitAnswer(_ answer: CorrectAnswer) {
        guard let question = currentQuestion else { return }
        answers[question.id] = answer
    }
    
    mutating func moveToNext() {
        if currentIndex < questions.count {
            currentIndex += 1
        }
        if currentIndex >= questions.count {
            endTime = Date()
        }
    }
    
    mutating func moveToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    mutating func jumpTo(index: Int) {
        guard index >= 0 && index < questions.count else { return }
        currentIndex = index
    }
    
    mutating func finish() {
        endTime = Date()
    }
    
    func hasAnswered(question: Question) -> Bool {
        return answers[question.id] != nil
    }
    
    func getAnswer(for question: Question) -> CorrectAnswer? {
        return answers[question.id]
    }
    
    func wasCorrect(question: Question) -> Bool? {
        guard let answer = answers[question.id] else { return nil }
        return question.isCorrect(answer)
    }
    
    // Get incorrectly answered questions
    var incorrectQuestions: [Question] {
        questions.filter { question in
            guard let answer = answers[question.id] else { return false }
            return !question.isCorrect(answer)
        }
    }
    
    // Get unanswered questions
    var unansweredQuestions: [Question] {
        questions.filter { question in
            answers[question.id] == nil
        }
    }
}

// MARK: - Session Result

struct QuizResult: Identifiable, Codable {
    let id: UUID
    let mode: String
    let date: Date
    let totalQuestions: Int
    let correctAnswers: Int
    let timeTaken: TimeInterval
    let categoryBreakdown: [String: CategoryResult]
    
    var score: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    var isPassing: Bool {
        return score >= 70 // Standard passing score
    }
}

struct CategoryResult: Codable {
    let total: Int
    let correct: Int
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
}
