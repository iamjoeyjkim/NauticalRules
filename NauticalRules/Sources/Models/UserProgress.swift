//
//  UserProgress.swift
//  NauticalRules
//
//  Model for tracking user's learning progress
//

import Foundation

// MARK: - User Progress

struct UserProgress: Codable {
    var questionsAnswered: Int
    var correctAnswers: Int
    var categoryStats: [String: CategoryStats]
    var bookmarkedQuestions: [Int]  // Ordered array: most recently added at the end
    var incorrectQuestions: Set<Int>
    var lastSessionDate: Date?
    var streakDays: Int
    var totalQuizzesTaken: Int
    var totalStudyTime: TimeInterval
    var quizHistory: [QuizHistoryEntry]
    
    // MARK: - Initialization
    
    init() {
        self.questionsAnswered = 0
        self.correctAnswers = 0
        self.categoryStats = [:]
        self.bookmarkedQuestions = []
        self.incorrectQuestions = []
        self.lastSessionDate = nil
        self.streakDays = 0
        self.totalQuizzesTaken = 0
        self.totalStudyTime = 0
        self.quizHistory = []
    }
    
    // MARK: - Computed Properties
    
    var overallAccuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }
    
    var masteryLevel: MasteryLevel {
        switch overallAccuracy {
        case 0..<25: return .beginner
        case 25..<50: return .novice
        case 50..<70: return .intermediate
        case 70..<85: return .advanced
        case 85..<95: return .expert
        default: return .master
        }
    }
    
    var hasStreak: Bool {
        return streakDays > 0
    }
    
    // MARK: - Methods
    
    mutating func recordAnswer(questionId: Int, category: QuestionCategory, isCorrect: Bool) {
        questionsAnswered += 1
        if isCorrect {
            correctAnswers += 1
            incorrectQuestions.remove(questionId)
        } else {
            incorrectQuestions.insert(questionId)
        }
        
        // Update category stats
        let key = category.rawValue
        var stats = categoryStats[key] ?? CategoryStats()
        stats.answered += 1
        if isCorrect {
            stats.correct += 1
        }
        categoryStats[key] = stats
    }
    
    mutating func toggleBookmark(questionId: Int) {
        if let index = bookmarkedQuestions.firstIndex(of: questionId) {
            bookmarkedQuestions.remove(at: index)
        } else {
            bookmarkedQuestions.append(questionId)  // Add to end (most recent)
        }
    }
    
    mutating func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastSession = lastSessionDate {
            let lastDay = calendar.startOfDay(for: lastSession)
            let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDifference == 1 {
                // Consecutive day
                streakDays += 1
            } else if daysDifference > 1 {
                // Streak broken
                streakDays = 1
            }
            // Same day - no change
        } else {
            // First session
            streakDays = 1
        }
        
        lastSessionDate = Date()
    }
    
    mutating func recordQuizCompletion(mode: String, score: Double, timeTaken: TimeInterval, totalQuestions: Int, correctCount: Int, questionIds: [Int], answers: [Int: CorrectAnswer]) {
        totalQuizzesTaken += 1
        totalStudyTime += timeTaken
        
        // Convert CorrectAnswer to String for storage
        var answerStrings: [Int: String] = [:]
        for (questionId, answer) in answers {
            answerStrings[questionId] = answer.rawValue
        }
        
        let entry = QuizHistoryEntry(
            date: Date(),
            mode: mode,
            score: score,
            timeTaken: timeTaken,
            totalQuestions: totalQuestions,
            correctCount: correctCount,
            questionIds: questionIds,
            answers: answerStrings
        )
        quizHistory.append(entry)
        
        // Keep only last 20 entries (to manage storage)
        if quizHistory.count > 20 {
            quizHistory.removeFirst(quizHistory.count - 20)
        }
    }
    
    func getCategoryProgress(for category: QuestionCategory) -> CategoryStats {
        return categoryStats[category.rawValue] ?? CategoryStats()
    }
    
    // Calculate progress for a category based on total questions
    func getCategoryPercentage(for category: QuestionCategory, totalInCategory: Int) -> Double {
        let stats = getCategoryProgress(for: category)
        guard totalInCategory > 0 else { return 0 }
        return Double(stats.correct) / Double(totalInCategory) * 100
    }
}

// MARK: - Category Stats

struct CategoryStats: Codable {
    var answered: Int = 0
    var correct: Int = 0
    
    var accuracy: Double {
        guard answered > 0 else { return 0 }
        return Double(correct) / Double(answered) * 100
    }
}

// MARK: - Quiz History Entry

struct QuizHistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let mode: String
    let score: Double
    let timeTaken: TimeInterval
    let totalQuestions: Int
    let correctCount: Int
    let questionIds: [Int]
    let answers: [Int: String]  // Question ID -> Answer (A, B, C, D)
    
    init(date: Date, mode: String, score: Double, timeTaken: TimeInterval, totalQuestions: Int, correctCount: Int, questionIds: [Int], answers: [Int: String]) {
        self.id = UUID()
        self.date = date
        self.mode = mode
        self.score = score
        self.timeTaken = timeTaken
        self.totalQuestions = totalQuestions
        self.correctCount = correctCount
        self.questionIds = questionIds
        self.answers = answers
    }
    
    // Convert stored answers to CorrectAnswer type
    func getAnswers() -> [Int: CorrectAnswer] {
        var result: [Int: CorrectAnswer] = [:]
        for (questionId, answerString) in answers {
            if let answer = CorrectAnswer(rawValue: answerString) {
                result[questionId] = answer
            }
        }
        return result
    }
}

// MARK: - Mastery Level

enum MasteryLevel: String, CaseIterable {
    case beginner = "Beginner"
    case novice = "Novice"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    case master = "Master"
    
    var icon: String {
        switch self {
        case .beginner: return "star"
        case .novice: return "star.leadinghalf.filled"
        case .intermediate: return "star.fill"
        case .advanced: return "star.circle"
        case .expert: return "star.circle.fill"
        case .master: return "crown.fill"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "a0aec0"    // Gray
        case .novice: return "48bb78"      // Green
        case .intermediate: return "4299e1" // Blue
        case .advanced: return "805ad5"    // Purple
        case .expert: return "ed8936"      // Orange
        case .master: return "f6ad55"      // Gold
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "Just getting started"
        case .novice: return "Learning the basics"
        case .intermediate: return "Making good progress"
        case .advanced: return "Strong understanding"
        case .expert: return "Near mastery"
        case .master: return "Complete mastery"
        }
    }
}
