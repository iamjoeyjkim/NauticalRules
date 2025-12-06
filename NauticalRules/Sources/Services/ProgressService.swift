//
//  ProgressService.swift
//  NauticalRules
//
//  Service for managing user progress and persistence
//

import Foundation
import SwiftUI

// MARK: - Progress Service

@MainActor
class ProgressService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var progress: UserProgress
    
    // MARK: - Private Properties
    
    private let userDefaultsKey = "NauticalRulesUserProgress"
    
    // MARK: - Singleton
    
    static let shared = ProgressService()
    
    private init() {
        self.progress = UserProgress()
        loadProgress()
    }
    
    // MARK: - Persistence
    
    func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("No saved progress found, using defaults")
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(UserProgress.self, from: data)
            self.progress = decoded
            print("Loaded progress: \(progress.questionsAnswered) questions answered")
        } catch {
            print("Error decoding progress: \(error)")
        }
    }
    
    func saveProgress() {
        do {
            let encoded = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("Progress saved")
        } catch {
            print("Error encoding progress: \(error)")
        }
    }
    
    func resetProgress() {
        // Preserve bookmarks before resetting
        let savedBookmarks = progress.bookmarkedQuestions
        
        // Reset to fresh progress
        progress = UserProgress()
        
        // Restore bookmarks
        progress.bookmarkedQuestions = savedBookmarks
        
        saveProgress()
    }
    
    // MARK: - Answer Recording
    
    func recordAnswer(questionId: Int, category: QuestionCategory, isCorrect: Bool) {
        progress.recordAnswer(questionId: questionId, category: category, isCorrect: isCorrect)
        saveProgress()
    }
    
    func recordQuizCompletion(session: QuizSession) {
        progress.recordQuizCompletion(
            mode: session.mode.displayName,
            score: session.score,
            timeTaken: session.elapsedTime,
            totalQuestions: session.questions.count,
            correctCount: session.correctCount,
            questionIds: session.questions.map { $0.id },
            answers: session.answers
        )
        progress.updateStreak()
        saveProgress()
    }
    
    // MARK: - Bookmarks
    
    func toggleBookmark(questionId: Int) {
        progress.toggleBookmark(questionId: questionId)
        saveProgress()
    }
    
    func isBookmarked(questionId: Int) -> Bool {
        progress.bookmarkedQuestions.contains(questionId)
    }
    
    var bookmarkedIds: Set<Int> {
        progress.bookmarkedQuestions
    }
    
    var bookmarkCount: Int {
        progress.bookmarkedQuestions.count
    }
    
    // MARK: - Incorrect Questions
    
    var incorrectIds: Set<Int> {
        progress.incorrectQuestions
    }
    
    var incorrectCount: Int {
        progress.incorrectQuestions.count
    }
    
    // MARK: - Statistics
    
    var overallAccuracy: Double {
        progress.overallAccuracy
    }
    
    var masteryLevel: MasteryLevel {
        progress.masteryLevel
    }
    
    var streakDays: Int {
        progress.streakDays
    }
    
    var totalQuizzesTaken: Int {
        progress.totalQuizzesTaken
    }
    
    var totalStudyTime: TimeInterval {
        progress.totalStudyTime
    }
    
    var questionsAnswered: Int {
        progress.questionsAnswered
    }
    
    var correctAnswers: Int {
        progress.correctAnswers
    }
    
    func getCategoryStats(for category: QuestionCategory) -> CategoryStats {
        progress.getCategoryProgress(for: category)
    }
    
    func getCategoryAccuracy(for category: QuestionCategory) -> Double {
        progress.getCategoryProgress(for: category).accuracy
    }
    
    // Calculate completion percentage based on total questions
    func getCategoryCompletion(for category: QuestionCategory, totalQuestions: Int) -> Double {
        let stats = progress.getCategoryProgress(for: category)
        guard totalQuestions > 0 else { return 0 }
        return Double(stats.answered) / Double(totalQuestions) * 100
    }
    
    // MARK: - Quiz History
    
    var recentQuizzes: [QuizHistoryEntry] {
        Array(progress.quizHistory.suffix(10).reversed())
    }
    
    var lastQuizDate: Date? {
        progress.quizHistory.last?.date
    }
    
    var averageScore: Double {
        guard !progress.quizHistory.isEmpty else { return 0 }
        let total = progress.quizHistory.reduce(0) { $0 + $1.score }
        return total / Double(progress.quizHistory.count)
    }
    
    // MARK: - Streak Management
    
    func checkAndUpdateStreak() {
        progress.updateStreak()
        saveProgress()
    }
    
    var hasActiveStreak: Bool {
        guard let lastSession = progress.lastSessionDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastSession)
        let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        return daysDifference <= 1
    }
    
    // MARK: - Formatted Stats
    
    var formattedStudyTime: String {
        let hours = Int(totalStudyTime) / 3600
        let minutes = (Int(totalStudyTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedAccuracy: String {
        String(format: "%.1f%%", overallAccuracy)
    }
}

// MARK: - Progress Service Extensions

extension ProgressService {
    
    /// Get questions that need review (answered incorrectly)
    func getQuestionsNeedingReview() -> Set<Int> {
        progress.incorrectQuestions
    }
    
    /// Check if a question was answered
    func wasQuestionAnswered(questionId: Int) -> Bool {
        // We can infer this from category stats, but for now return true if in incorrect set
        // A more complete implementation would track all answered question IDs
        progress.incorrectQuestions.contains(questionId)
    }
    
    /// Calculate overall progress percentage
    func calculateOverallProgress(totalQuestions: Int) -> Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(progress.questionsAnswered) / Double(totalQuestions) * 100
    }
    
    /// Get category with lowest accuracy for targeted practice
    func getWeakestCategory() -> QuestionCategory? {
        var lowestCategory: QuestionCategory?
        var lowestAccuracy: Double = 101
        
        for category in QuestionCategory.allCases {
            let stats = getCategoryStats(for: category)
            if stats.answered >= 5 && stats.accuracy < lowestAccuracy {
                lowestAccuracy = stats.accuracy
                lowestCategory = category
            }
        }
        
        return lowestCategory
    }
    
    /// Get study recommendations based on progress
    func getStudyRecommendations() -> [StudyRecommendation] {
        var recommendations: [StudyRecommendation] = []
        
        // Check for weak categories
        if let weakCategory = getWeakestCategory() {
            recommendations.append(
                StudyRecommendation(
                    title: "Focus on \(weakCategory.shortName)",
                    description: "Your accuracy is lowest in this category",
                    action: .practiceCategory(weakCategory),
                    priority: .high
                )
            )
        }
        
        // Check for incorrect questions
        if incorrectCount > 0 {
            recommendations.append(
                StudyRecommendation(
                    title: "Review Mistakes",
                    description: "You have \(incorrectCount) questions to review",
                    action: .reviewMistakes,
                    priority: incorrectCount > 20 ? .high : .medium
                )
            )
        }
        
        // Check for bookmarked questions
        if bookmarkCount > 0 {
            recommendations.append(
                StudyRecommendation(
                    title: "Study Bookmarked",
                    description: "\(bookmarkCount) bookmarked questions",
                    action: .studyBookmarked,
                    priority: .low
                )
            )
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}

// MARK: - Study Recommendation

struct StudyRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let action: RecommendationAction
    let priority: RecommendationPriority
}

enum RecommendationAction {
    case practiceCategory(QuestionCategory)
    case reviewMistakes
    case studyBookmarked
    case examSimulation
}

enum RecommendationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
}
