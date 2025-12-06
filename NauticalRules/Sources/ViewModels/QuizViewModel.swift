//
//  QuizViewModel.swift
//  NauticalRules
//
//  ViewModel for the Quiz screen
//

import Foundation
import SwiftUI

@MainActor
class QuizViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var session: QuizSession?
    @Published var selectedAnswer: CorrectAnswer?
    @Published var showingExplanation: Bool = false
    @Published var isAnswerLocked: Bool = false
    @Published var showingResults: Bool = false
    @Published var isLoading: Bool = false
    @Published var timerValue: TimeInterval = 0
    
    // MARK: - Services
    
    private let questionService = QuestionService.shared
    private let progressService = ProgressService.shared
    
    // Timer
    private var timer: Timer?
    
    // MARK: - Computed Properties
    
    var currentQuestion: Question? {
        session?.currentQuestion
    }
    
    var currentIndex: Int {
        session?.currentIndex ?? 0
    }
    
    var totalQuestions: Int {
        session?.questions.count ?? 0
    }
    
    var progress: Double {
        session?.progress ?? 0
    }
    
    var isLastQuestion: Bool {
        guard let session = session else { return true }
        return session.currentIndex >= session.questions.count - 1
    }
    
    var canGoBack: Bool {
        return currentIndex > 0
    }
    
    var isComplete: Bool {
        session?.isComplete ?? false
    }
    
    var score: Double {
        session?.score ?? 0
    }
    
    var correctCount: Int {
        session?.correctCount ?? 0
    }
    
    var incorrectCount: Int {
        session?.incorrectCount ?? 0
    }
    
    var showsImmediateFeedback: Bool {
        session?.mode.showsImmediateFeedback ?? true
    }
    
    var showsTimer: Bool {
        session?.mode.showsTimer ?? false
    }
    
    var remainingTime: TimeInterval {
        session?.remainingTime ?? 0
    }
    
    var formattedTime: String {
        let time = showsTimer ? remainingTime : timerValue
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var isBookmarked: Bool {
        guard let question = currentQuestion else { return false }
        return progressService.isBookmarked(questionId: question.id)
    }
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Quiz Setup
    
    func startQuiz(mode: QuizMode) {
        isLoading = true
        selectedAnswer = nil
        showingExplanation = false
        isAnswerLocked = false
        showingResults = false
        timerValue = 0
        
        var questions: [Question] = []
        var timeLimit: TimeInterval? = nil
        
        switch mode {
        case .practice:
            questions = questionService.generateQuiz(mode: mode, questionCount: nil)
            
        case .exam(let count, let limit):
            questions = questionService.generateQuiz(mode: mode, questionCount: count)
            timeLimit = limit
            
        case .quickQuiz(let count):
            questions = questionService.generateQuiz(mode: mode, questionCount: count)
            
        case .review:
            let incorrectIds = progressService.incorrectIds
            questions = questionService.generateReviewQuiz(incorrectIds: incorrectIds)
            
        case .study:
            questions = questionService.generateQuiz(mode: mode, questionCount: nil)
        }
        
        // Create session
        session = QuizSession(mode: mode, questions: questions, timeLimit: timeLimit)
        
        // Start timer if needed
        if showsTimer {
            startTimer()
        }
        
        isLoading = false
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerTick()
            }
        }
    }
    
    private func timerTick() {
        timerValue += 1
        
        // Check for time up in exam mode
        if session?.isTimeUp == true {
            finishQuiz()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Answer Handling
    
    func selectAnswer(_ answer: CorrectAnswer) {
        guard !isAnswerLocked else { return }
        
        selectedAnswer = answer
        
        // Always save the answer to the session immediately
        if currentQuestion != nil {
            session?.submitAnswer(answer)
        }
        
        // In immediate feedback modes, lock the answer and show feedback
        if showsImmediateFeedback {
            isAnswerLocked = true
            
            // Record for progress tracking (only in immediate feedback mode)
            if let question = currentQuestion {
                let isCorrect = question.isCorrect(answer)
                progressService.recordAnswer(
                    questionId: question.id,
                    category: question.category,
                    isCorrect: isCorrect
                )
            }
            
            // Show explanation
            withAnimation(AppTheme.Animation.smooth) {
                showingExplanation = true
            }
        }
    }
    
    func submitAnswer() {
        guard let answer = selectedAnswer, let question = currentQuestion else { return }
        
        isAnswerLocked = true
        session?.submitAnswer(answer)
        
        // Record the answer for progress (only if not already done in selectAnswer)
        if !showsImmediateFeedback {
            // In quiz mode, we defer recording until quiz completion
        } else {
            let isCorrect = question.isCorrect(answer)
            progressService.recordAnswer(
                questionId: question.id,
                category: question.category,
                isCorrect: isCorrect
            )
        }
        
        // Show explanation in immediate feedback modes
        if showsImmediateFeedback {
            withAnimation(AppTheme.Animation.smooth) {
                showingExplanation = true
            }
        }
    }
    
    /// Records the answer without showing visual feedback (for test mode)
    func recordAnswerSilently() {
        guard let answer = selectedAnswer, currentQuestion != nil else { return }
        
        // Submit to session without locking UI
        session?.submitAnswer(answer)
    }
    
    // MARK: - Navigation
    
    func moveToNext() {
        guard session != nil else { return }
        
        session?.moveToNext()
        
        // Load any existing answer for the new question
        if let question = currentQuestion {
            selectedAnswer = session?.getAnswer(for: question)
        } else {
            selectedAnswer = nil
        }
        
        // In quiz mode, don't lock - allow changing answers
        // In immediate feedback mode, lock if already answered
        isAnswerLocked = showsImmediateFeedback && selectedAnswer != nil
        showingExplanation = false
        
        // Check if quiz is complete
        if session?.isComplete == true {
            finishQuiz()
        }
    }
    
    func moveToPrevious() {
        guard session != nil else { return }
        
        session?.moveToPrevious()
        
        // Restore previous answer if any
        if let question = currentQuestion {
            selectedAnswer = session?.getAnswer(for: question)
        }
        // Only lock answer in immediate feedback mode
        isAnswerLocked = showsImmediateFeedback && selectedAnswer != nil
        showingExplanation = false
    }
    
    func jumpTo(index: Int) {
        guard session != nil else { return }
        
        session?.jumpTo(index: index)
        
        if let question = currentQuestion {
            selectedAnswer = session?.getAnswer(for: question)
        }
        // Only lock answer in immediate feedback mode
        isAnswerLocked = showsImmediateFeedback && selectedAnswer != nil
        showingExplanation = false
    }
    
    // MARK: - Quiz Completion
    
    func finishQuiz() {
        stopTimer()
        session?.finish()
        
        // Record completion
        if let session = session {
            progressService.recordQuizCompletion(session: session)
        }
        
        showingResults = true
    }
    
    func endQuizEarly() {
        finishQuiz()
    }
    
    // MARK: - Bookmarking
    
    func toggleBookmark() {
        guard let question = currentQuestion else { return }
        progressService.toggleBookmark(questionId: question.id)
        objectWillChange.send()
    }
    
    // MARK: - Helpers
    
    func getAnswerState(for answer: CorrectAnswer) -> AnswerState {
        // In quiz/exam mode without immediate feedback, only show if answer is selected
        // Don't show correct/incorrect until results are shown
        if !showsImmediateFeedback && !showingResults {
            if selectedAnswer == answer {
                return .selected
            }
            return .normal
        }
        
        guard isAnswerLocked, let question = currentQuestion else {
            if selectedAnswer == answer {
                return .selected
            }
            return .normal
        }
        
        if answer == question.correctAnswer {
            return .correct
        }
        
        if selectedAnswer == answer {
            return .incorrect
        }
        
        return .normal
    }
    
    func resetQuiz() {
        session = nil
        selectedAnswer = nil
        showingExplanation = false
        isAnswerLocked = false
        showingResults = false
        timerValue = 0
        stopTimer()
    }
    
    func restartQuiz() {
        guard let currentMode = session?.mode else { return }
        resetQuiz()
        startQuiz(mode: currentMode)
    }
    
    // Get results for category breakdown
    func getCategoryResults() -> [QuestionCategory: (correct: Int, total: Int)] {
        guard let session = session else { return [:] }
        
        var results: [QuestionCategory: (correct: Int, total: Int)] = [:]
        
        for category in QuestionCategory.allCases {
            let categoryQuestions = session.questions.filter { $0.category == category }
            let correct = categoryQuestions.filter { q in
                guard let answer = session.getAnswer(for: q) else { return false }
                return q.isCorrect(answer)
            }.count
            
            if !categoryQuestions.isEmpty {
                results[category] = (correct: correct, total: categoryQuestions.count)
            }
        }
        
        return results
    }
}

// MARK: - Answer State

enum AnswerState {
    case normal
    case selected
    case correct
    case incorrect
    
    var backgroundColor: Color {
        switch self {
        case .normal:
            return AppTheme.Colors.cardBackground
        case .selected:
            return AppTheme.Colors.oceanBlue.opacity(0.1)
        case .correct:
            return AppTheme.Colors.correct.opacity(0.15)
        case .incorrect:
            return AppTheme.Colors.incorrect.opacity(0.15)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .normal:
            return AppTheme.Colors.border
        case .selected:
            return AppTheme.Colors.oceanBlue
        case .correct:
            return AppTheme.Colors.correct
        case .incorrect:
            return AppTheme.Colors.incorrect
        }
    }
    
    var textColor: Color {
        switch self {
        case .normal, .selected:
            return AppTheme.Colors.textPrimary
        case .correct:
            return AppTheme.Colors.correct
        case .incorrect:
            return AppTheme.Colors.incorrect
        }
    }
}
