//
//  PracticeSessionView.swift
//  NauticalRules
//
//  Single question practice view with rotating questions
//

import SwiftUI

struct PracticeSessionView: View {
    
    // MARK: - Properties
    
    let category: QuestionCategory?
    let onDismiss: () -> Void
    
    @EnvironmentObject var questionService: QuestionService
    @EnvironmentObject var progressService: ProgressService
    
    // MARK: - State
    
    @State private var currentIndex: Int = 0
    @State private var selectedAnswer: CorrectAnswer?
    @State private var isAnswerLocked: Bool = false
    @State private var showingExitConfirmation = false
    
    // MARK: - Computed Properties
    
    private var questions: [Question] {
        if let category = category {
            return questionService.questions(for: category)
        } else {
            return questionService.allQuestions
        }
    }
    
    private var currentQuestion: Question? {
        guard !questions.isEmpty else { return nil }
        let index = currentIndex % questions.count
        return questions[index]
    }
    
    private var categoryName: String {
        category?.shortName ?? "All Categories"
    }
    
    private var canGoBack: Bool {
        currentIndex > 0
    }
    
    private var isBookmarked: Bool {
        guard let question = currentQuestion else { return false }
        return progressService.isBookmarked(questionId: question.id)
    }
    
    private var nextButtonTitle: String {
        return "Next"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let question = currentQuestion {
                        // Question Content
                        ScrollView {
                            VStack(spacing: AppTheme.Spacing.xl) {
                                // Question Card
                                questionCard(question)
                                
                                // Answer Options
                                answerOptions(question)
                                
                                // Explanation (shown after answering)
                                if isAnswerLocked && !question.explanation.isEmpty {
                                    ExplanationCard(explanation: question.explanation)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, AppTheme.Spacing.xl)
                        }
                        
                        // Bottom Navigation
                        bottomNavigation
                    } else {
                        emptyState
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        showingExitConfirmation = true
                    }
                    .foregroundColor(AppTheme.Colors.incorrect)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(categoryName)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        toggleBookmark()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? AppTheme.Colors.coral : AppTheme.Colors.textSecondary)
                    }
                }
            }
            .alert("Exit Practice?", isPresented: $showingExitConfirmation) {
                Button("Continue", role: .cancel) {}
                Button("Exit", role: .destructive) {
                    savePracticePosition()
                    onDismiss()
                }
            } message: {
                Text("Your position will be saved.")
            }
            .onAppear {
                loadPracticePosition()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No Questions Available")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(AppTheme.Spacing.xxl)
    }
    
    // MARK: - Question Card
    
    private func questionCard(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Jurisdiction Badge
            HStack {
                Text(question.jurisdiction.displayName)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Color(hex: question.jurisdiction.color))
                    )
                
                Text(question.category.shortName)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(Color(hex: question.category.color))
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color(hex: question.category.color).opacity(0.15))
                    )
            }
            
            // Question Text
            Text(question.cleanText)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            // Diagram if available
            if question.hasDiagram {
                DiagramView(diagramName: question.diagramName)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(
                    color: AppTheme.Shadows.md.color,
                    radius: AppTheme.Shadows.md.radius,
                    x: AppTheme.Shadows.md.x,
                    y: AppTheme.Shadows.md.y
                )
        )
    }
    
    // MARK: - Answer Options
    
    private func answerOptions(_ question: Question) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(CorrectAnswer.allCases, id: \.self) { option in
                let isSelected = selectedAnswer == option
                let isCorrect = question.correctAnswer == option
                let state = answerState(isSelected: isSelected, isCorrect: isCorrect)
                
                AnswerButton(
                    letter: option.rawValue,
                    text: question.options[option.index],
                    state: state,
                    isCorrectAnswer: isAnswerLocked && isCorrect
                ) {
                    if !isAnswerLocked {
                        withAnimation(AppTheme.Animation.quick) {
                            selectedAnswer = option
                            // Immediately show feedback
                            isAnswerLocked = true
                        }
                    }
                }
            }
        }
    }
    
    private func answerState(isSelected: Bool, isCorrect: Bool) -> AnswerState {
        guard isAnswerLocked else {
            return isSelected ? .selected : .normal
        }
        if isCorrect {
            return .correct
        } else if isSelected {
            return .incorrect
        }
        return .normal
    }
    
    // MARK: - Bottom Navigation
    
    private var bottomNavigation: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Previous Button
            Button {
                moveToPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoBack)
            .foregroundColor(canGoBack ? AppTheme.Colors.primaryNavy : AppTheme.Colors.textTertiary)
            
            Spacer()
            
            // Next Button (only active after answering)
            Button {
                if isAnswerLocked {
                    moveToNext()
                }
            } label: {
                HStack {
                    Text(nextButtonTitle)
                    Image(systemName: "chevron.right")
                }
                .font(AppTheme.Typography.headline)
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(
                    Capsule()
                        .fill(isAnswerLocked ? AppTheme.Colors.primaryGradient : LinearGradient(colors: [AppTheme.Colors.textTertiary], startPoint: .leading, endPoint: .trailing))
                )
            }
            .disabled(!isAnswerLocked)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
    }
    
    // MARK: - Actions
    
    private func submitAnswer() {
        withAnimation(AppTheme.Animation.smooth) {
            isAnswerLocked = true
        }
    }
    
    private func moveToNext() {
        withAnimation {
            currentIndex += 1
            selectedAnswer = nil
            isAnswerLocked = false
            savePracticePosition()
        }
    }
    
    private func moveToPrevious() {
        guard currentIndex > 0 else { return }
        withAnimation {
            currentIndex -= 1
            selectedAnswer = nil
            isAnswerLocked = false
        }
    }
    
    private func toggleBookmark() {
        guard let question = currentQuestion else { return }
        progressService.toggleBookmark(questionId: question.id)
    }
    
    // MARK: - Position Persistence
    
    private var positionKey: String {
        "practicePosition_\(category?.rawValue ?? "all")"
    }
    
    private func loadPracticePosition() {
        currentIndex = UserDefaults.standard.integer(forKey: positionKey)
    }
    
    private func savePracticePosition() {
        UserDefaults.standard.set(currentIndex, forKey: positionKey)
    }
}

// MARK: - Preview

#Preview {
    PracticeSessionView(category: nil, onDismiss: {})
        .environmentObject(QuestionService.shared)
        .environmentObject(ProgressService.shared)
}
