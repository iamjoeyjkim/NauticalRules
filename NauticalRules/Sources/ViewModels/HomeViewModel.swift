//
//  HomeViewModel.swift
//  NauticalRules
//
//  ViewModel for the Home screen
//

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading: Bool = true
    @Published var selectedCategory: QuestionCategory?
    @Published var showingQuizSetup: Bool = false
    @Published var showingQuiz: Bool = false
    @Published var activeQuizMode: QuizMode?
    
    // MARK: - Services
    
    private let questionService = QuestionService.shared
    private let progressService = ProgressService.shared
    
    // MARK: - Computed Properties
    
    var isDataLoaded: Bool {
        questionService.isLoaded
    }
    
    var totalQuestions: Int {
        questionService.questionCount
    }
    
    var questionsAnswered: Int {
        progressService.questionsAnswered
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
    
    var hasActiveStreak: Bool {
        progressService.hasActiveStreak
    }
    
    var bookmarkCount: Int {
        progressService.bookmarkCount
    }
    
    var incorrectCount: Int {
        progressService.incorrectCount
    }
    
    var formattedStudyTime: String {
        progressService.formattedStudyTime
    }
    
    var totalQuizzesTaken: Int {
        progressService.totalQuizzesTaken
    }
    
    var overallProgress: Double {
        progressService.calculateOverallProgress(totalQuestions: totalQuestions)
    }
    
    var categories: [QuestionCategory] {
        QuestionCategory.allCases
    }
    
    var studyRecommendations: [StudyRecommendation] {
        progressService.getStudyRecommendations()
    }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Data Loading
    
    func loadData() {
        isLoading = true
        
        // Load questions if not already loaded
        if !questionService.isLoaded {
            questionService.loadQuestions()
        }
        
        // Check and update streak
        progressService.checkAndUpdateStreak()
        
        isLoading = false
    }
    
    // MARK: - Category Stats
    
    func getQuestionCount(for category: QuestionCategory) -> Int {
        questionService.questionCount(for: category)
    }
    
    func getCategoryAccuracy(for category: QuestionCategory) -> Double {
        progressService.getCategoryAccuracy(for: category)
    }
    
    func getCategoryCompletion(for category: QuestionCategory) -> Double {
        let total = getQuestionCount(for: category)
        return progressService.getCategoryCompletion(for: category, totalQuestions: total)
    }
    
    func getCategoryStats(for category: QuestionCategory) -> CategoryStats {
        progressService.getCategoryStats(for: category)
    }
    
    // MARK: - Quiz Actions
    
    func startQuickQuiz(questionCount: Int = 10) {
        activeQuizMode = .quickQuiz(questionCount: questionCount)
        showingQuiz = true
    }
    
    func startPractice(category: QuestionCategory?) {
        activeQuizMode = .practice(category: category)
        showingQuiz = true
    }
    
    func startExam(questionCount: Int = 50, timeLimit: TimeInterval? = 3600) {
        activeQuizMode = .exam(questionCount: questionCount, timeLimit: timeLimit)
        showingQuiz = true
    }
    
    func startReview() {
        activeQuizMode = .review
        showingQuiz = true
    }
    
    func startStudy(category: QuestionCategory?) {
        activeQuizMode = .study(category: category)
        showingQuiz = true
    }
    
    func startCategoryQuiz(_ category: QuestionCategory) {
        selectedCategory = category
        activeQuizMode = .practice(category: category)
        showingQuiz = true
    }
    
    // MARK: - Recommendation Actions
    
    func executeRecommendation(_ recommendation: StudyRecommendation) {
        switch recommendation.action {
        case .practiceCategory(let category):
            startPractice(category: category)
        case .reviewMistakes:
            startReview()
        case .studyBookmarked:
            // Start quiz with bookmarked questions
            activeQuizMode = .practice(category: nil)
            showingQuiz = true
        case .examSimulation:
            startExam()
        }
    }
    
    // MARK: - Helpers
    
    func dismissQuiz() {
        showingQuiz = false
        activeQuizMode = nil
        selectedCategory = nil
    }
}
