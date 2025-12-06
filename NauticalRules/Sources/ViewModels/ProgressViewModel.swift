//
//  ProgressViewModel.swift
//  NauticalRules
//
//  ViewModel for the Progress/Statistics screen
//

import Foundation
import SwiftUI

@MainActor
class ProgressViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedTimeRange: TimeRange = .allTime
    @Published var showingResetConfirmation: Bool = false
    
    // MARK: - Services
    
    private let questionService = QuestionService.shared
    private let progressService = ProgressService.shared
    
    // MARK: - Computed Properties
    
    // Overall Stats
    var totalQuestions: Int {
        questionService.questionCount
    }
    
    var questionsAnswered: Int {
        progressService.questionsAnswered
    }
    
    var correctAnswers: Int {
        progressService.correctAnswers
    }
    
    var overallAccuracy: Double {
        progressService.overallAccuracy
    }
    
    var masteryLevel: MasteryLevel {
        progressService.masteryLevel
    }
    
    var streakDays: Int {
        progressService.streakDays
    }
    
    var totalQuizzesTaken: Int {
        progressService.totalQuizzesTaken
    }
    
    var formattedStudyTime: String {
        progressService.formattedStudyTime
    }
    
    var overallProgress: Double {
        progressService.calculateOverallProgress(totalQuestions: totalQuestions)
    }
    
    var bookmarkCount: Int {
        progressService.bookmarkCount
    }
    
    var incorrectCount: Int {
        progressService.incorrectCount
    }
    
    var averageScore: Double {
        progressService.averageScore
    }
    
    // Category Stats
    var categories: [QuestionCategory] {
        QuestionCategory.allCases
    }
    
    var categoryBreakdown: [(category: QuestionCategory, stats: CategoryStatsDisplay)] {
        categories.map { category in
            let totalInCategory = questionService.questionCount(for: category)
            let stats = progressService.getCategoryStats(for: category)
            
            return (
                category: category,
                stats: CategoryStatsDisplay(
                    total: totalInCategory,
                    answered: stats.answered,
                    correct: stats.correct,
                    accuracy: stats.accuracy,
                    completion: Double(stats.answered) / Double(max(totalInCategory, 1)) * 100
                )
            )
        }
    }
    
    // Quiz History
    var recentQuizzes: [QuizHistoryEntry] {
        progressService.recentQuizzes
    }
    
    var lastQuizDate: Date? {
        progressService.lastQuizDate
    }
    
    var formattedLastQuizDate: String {
        guard let date = lastQuizDate else { return "Never" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Methods
    
    func getCategoryStats(for category: QuestionCategory) -> CategoryStatsDisplay {
        let totalInCategory = questionService.questionCount(for: category)
        let stats = progressService.getCategoryStats(for: category)
        
        return CategoryStatsDisplay(
            total: totalInCategory,
            answered: stats.answered,
            correct: stats.correct,
            accuracy: stats.accuracy,
            completion: Double(stats.answered) / Double(max(totalInCategory, 1)) * 100
        )
    }
    
    func resetProgress() {
        progressService.resetProgress()
        showingResetConfirmation = false
    }
    
    // Performance insights
    var performanceInsights: [PerformanceInsight] {
        var insights: [PerformanceInsight] = []
        
        // Overall performance
        if overallAccuracy >= 90 {
            insights.append(PerformanceInsight(
                icon: "star.fill",
                title: "Excellent!",
                description: "Your accuracy is above 90%! You're ready for the exam.",
                type: .positive
            ))
        } else if overallAccuracy >= 70 {
            insights.append(PerformanceInsight(
                icon: "checkmark.circle.fill",
                title: "Good Progress",
                description: "You're on track. Keep practicing to reach 90%.",
                type: .neutral
            ))
        } else if questionsAnswered > 50 {
            insights.append(PerformanceInsight(
                icon: "exclamationmark.triangle.fill",
                title: "Needs Improvement",
                description: "Focus on reviewing incorrect answers to boost accuracy.",
                type: .warning
            ))
        }
        
        // Streak
        if streakDays >= 7 {
            insights.append(PerformanceInsight(
                icon: "flame.fill",
                title: "\(streakDays) Day Streak!",
                description: "Amazing consistency! Keep it up.",
                type: .positive
            ))
        }
        
        // Weak category
        if let weakCategory = progressService.getWeakestCategory() {
            let stats = getCategoryStats(for: weakCategory)
            if stats.accuracy < 70 && stats.answered >= 10 {
                insights.append(PerformanceInsight(
                    icon: "lightbulb.fill",
                    title: "Focus Area",
                    description: "\(weakCategory.shortName) needs more attention (\(Int(stats.accuracy))% accuracy).",
                    type: .warning
                ))
            }
        }
        
        // Incomplete questions
        let unansweredPercentage = 100 - overallProgress
        if unansweredPercentage > 50 {
            insights.append(PerformanceInsight(
                icon: "book.fill",
                title: "More to Explore",
                description: "You've only seen \(Int(overallProgress))% of questions. Keep studying!",
                type: .neutral
            ))
        }
        
        return insights
    }
}

// MARK: - Supporting Types

struct CategoryStatsDisplay {
    let total: Int
    let answered: Int
    let correct: Int
    let accuracy: Double
    let completion: Double
}

struct PerformanceInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let type: InsightType
}

enum InsightType {
    case positive
    case neutral
    case warning
    
    var color: Color {
        switch self {
        case .positive: return AppTheme.Colors.correct
        case .neutral: return AppTheme.Colors.oceanBlue
        case .warning: return AppTheme.Colors.warning
        }
    }
}

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case allTime = "All Time"
}
