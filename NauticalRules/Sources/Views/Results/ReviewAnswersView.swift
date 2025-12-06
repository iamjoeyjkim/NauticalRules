//
//  ReviewAnswersView.swift
//  NauticalRules
//
//  View for reviewing quiz answers after completion
//

import SwiftUI

struct ReviewAnswersView: View {
    
    // MARK: - Properties
    
    let questions: [Question]
    let answers: [Int: CorrectAnswer]  // Question ID -> User's answer
    let showOnlyIncorrect: Bool
    let onDismiss: () -> Void
    
    // MARK: - Environment
    
    @EnvironmentObject var progressService: ProgressService
    
    // MARK: - State
    
    @State private var currentIndex: Int = 0
    
    // MARK: - Computed Properties
    
    private var filteredQuestions: [Question] {
        if showOnlyIncorrect {
            return questions.filter { question in
                guard let userAnswer = answers[question.id] else { return false }
                return !question.isCorrect(userAnswer)
            }
        }
        return questions
    }
    
    private var currentQuestion: Question? {
        guard currentIndex >= 0 && currentIndex < filteredQuestions.count else { return nil }
        return filteredQuestions[currentIndex]
    }
    
    private var isCurrentQuestionBookmarked: Bool {
        guard let question = currentQuestion else { return false }
        return progressService.isBookmarked(questionId: question.id)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if filteredQuestions.isEmpty {
                    emptyState
                } else if let question = currentQuestion {
                    // Question Content
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Progress indicator
                            Text("Question \(currentIndex + 1) of \(filteredQuestions.count)")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            
                            // Question Card
                            questionCard(question)
                            
                            // Diagram if available
                            if question.hasDiagram {
                                DiagramView(diagramName: question.diagramName)
                            }
                            
                            // Answer Options
                            answersSection(question)
                            
                            // Explanation
                            if !question.explanation.isEmpty {
                                explanationCard(question.explanation)
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                    }
                    
                    // Navigation Buttons
                    navigationButtons
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(showOnlyIncorrect ? "Review Mistakes" : "Review Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentQuestion != nil {
                        Button {
                            if let question = currentQuestion {
                                progressService.toggleBookmark(questionId: question.id)
                            }
                        } label: {
                            Image(systemName: isCurrentQuestionBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isCurrentQuestionBookmarked ? AppTheme.Colors.coral : AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.correct)
            
            Text("No Mistakes!")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("You answered all questions correctly.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Button("Done") {
                onDismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, AppTheme.Spacing.lg)
        }
        .padding(AppTheme.Spacing.xxl)
    }
    
    // MARK: - Question Card
    
    private func questionCard(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Category Badge
            HStack {
                Text(question.category.shortName)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(Color(hex: question.category.color))
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color(hex: question.category.color).opacity(0.15))
                    )
                
                Spacer()
                
                // Correct/Incorrect indicator
                if let userAnswer = answers[question.id] {
                    let isCorrect = question.isCorrect(userAnswer)
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? AppTheme.Colors.correct : AppTheme.Colors.incorrect)
                }
            }
            
            Text(question.text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(AppTheme.Spacing.lg)
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
    
    // MARK: - Answers Section
    
    private func answersSection(_ question: Question) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(CorrectAnswer.allCases, id: \.self) { option in
                answerRow(question: question, option: option)
            }
        }
    }
    
    private func answerRow(question: Question, option: CorrectAnswer) -> some View {
        let optionText = question.options[option.index]
        let isCorrectAnswer = question.correctAnswer == option
        let userAnswer = answers[question.id]
        let wasSelected = userAnswer == option
        
        return HStack(spacing: AppTheme.Spacing.md) {
            // Option Letter
            ZStack {
                Circle()
                    .fill(backgroundColor(isCorrect: isCorrectAnswer, wasSelected: wasSelected))
                    .frame(width: 32, height: 32)
                
                Text(option.rawValue)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(textColor(isCorrect: isCorrectAnswer, wasSelected: wasSelected))
            }
            
            // Option Text
            Text(optionText)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            // Status Icons
            if isCorrectAnswer {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.correct)
            } else if wasSelected {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.incorrect)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(rowBackground(isCorrect: isCorrectAnswer, wasSelected: wasSelected))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(borderColor(isCorrect: isCorrectAnswer, wasSelected: wasSelected), lineWidth: wasSelected || isCorrectAnswer ? 2 : 1)
                )
        )
    }
    
    // MARK: - Explanation Card
    
    private func explanationCard(_ explanation: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(AppTheme.Colors.warning)
                Text("Explanation")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            Text(explanation)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.warning.opacity(0.1))
        )
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Button {
                withAnimation {
                    currentIndex = max(0, currentIndex - 1)
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
            }
            .disabled(currentIndex == 0)
            .opacity(currentIndex == 0 ? 0.5 : 1)
            
            Spacer()
            
            Button {
                withAnimation {
                    currentIndex = min(filteredQuestions.count - 1, currentIndex + 1)
                }
            } label: {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
            }
            .disabled(currentIndex >= filteredQuestions.count - 1)
            .opacity(currentIndex >= filteredQuestions.count - 1 ? 0.5 : 1)
        }
        .font(AppTheme.Typography.bodyMedium)
        .foregroundColor(AppTheme.Colors.oceanBlue)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBackground)
    }
    
    // MARK: - Helper Functions
    
    private func backgroundColor(isCorrect: Bool, wasSelected: Bool) -> Color {
        if isCorrect {
            return AppTheme.Colors.correct
        } else if wasSelected {
            return AppTheme.Colors.incorrect
        }
        return AppTheme.Colors.border
    }
    
    private func textColor(isCorrect: Bool, wasSelected: Bool) -> Color {
        if isCorrect || wasSelected {
            return .white
        }
        return AppTheme.Colors.textSecondary
    }
    
    private func rowBackground(isCorrect: Bool, wasSelected: Bool) -> Color {
        if isCorrect {
            return AppTheme.Colors.correct.opacity(0.1)
        } else if wasSelected {
            return AppTheme.Colors.incorrect.opacity(0.1)
        }
        return AppTheme.Colors.cardBackground
    }
    
    private func borderColor(isCorrect: Bool, wasSelected: Bool) -> Color {
        if isCorrect {
            return AppTheme.Colors.correct
        } else if wasSelected {
            return AppTheme.Colors.incorrect
        }
        return AppTheme.Colors.border
    }
}

// MARK: - Preview

#Preview {
    ReviewAnswersView(
        questions: [],
        answers: [:],
        showOnlyIncorrect: true,
        onDismiss: {}
    )
    .environmentObject(ProgressService.shared)
}
