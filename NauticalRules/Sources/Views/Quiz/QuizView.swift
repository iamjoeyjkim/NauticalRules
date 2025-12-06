//
//  QuizView.swift
//  NauticalRules
//
//  Main quiz screen with question cards and answer options
//

import SwiftUI

struct QuizView: View {
    
    // MARK: - Properties
    
    let mode: QuizMode
    let onDismiss: () -> Void
    
    // MARK: - ViewModel
    
    @StateObject private var viewModel = QuizViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var showingExitConfirmation = false
    @State private var shareItem: ShareItem?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    SwiftUI.ProgressView("Loading questions...")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                } else if viewModel.totalQuestions == 0 {
                    emptyStateView
                } else if viewModel.showingResults {
                    ResultsView(viewModel: viewModel) {
                        onDismiss()
                    } onRestart: {
                        viewModel.restartQuiz()
                    }
                } else {
                    quizContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.showingResults {
                        Button("Exit") {
                            showingExitConfirmation = true
                        }
                        .foregroundColor(AppTheme.Colors.incorrect)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(viewModel.showingResults ? "Test Review" : mode.displayName)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        if viewModel.showsTimer && !viewModel.showingResults {
                            Text(viewModel.formattedTime)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(viewModel.remainingTime < 300 ? AppTheme.Colors.incorrect : AppTheme.Colors.textSecondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.showingResults {
                        Button {
                            shareResults()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(AppTheme.Colors.oceanBlue)
                        }
                    } else {
                        Button {
                            viewModel.toggleBookmark()
                        } label: {
                            Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(viewModel.isBookmarked ? AppTheme.Colors.coral : AppTheme.Colors.textSecondary)
                        }
                    }
                }
            }
            .alert("Exit Quiz?", isPresented: $showingExitConfirmation) {
                Button("Continue Quiz", role: .cancel) {}
                Button("Exit", role: .destructive) {
                    viewModel.stopTimer()
                    onDismiss()
                }
            } message: {
                Text("Your progress in this quiz will be lost.")
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(activityItems: [item.url])
            }
        }
        .onAppear {
            viewModel.startQuiz(mode: mode)
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }
    
    // MARK: - Quiz Content
    
    private var quizContent: some View {
        VStack(spacing: 0) {
            // Progress Bar
            progressBar
            
            // Question Content
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Question Card
                    questionCard
                    
                    // Answer Options
                    answerOptions
                    
                    // Note: Explanations are not shown during tests
                    // They are available in Practice mode and when reviewing test history
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.xl)
            }
            
            // Bottom Navigation
            bottomNavigation
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.Colors.border)
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(AppTheme.Colors.oceanGradient)
                        .frame(width: geometry.size.width * viewModel.progress, height: 4)
                        .animation(AppTheme.Animation.smooth, value: viewModel.progress)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text("Question \(viewModel.currentIndex + 1) of \(viewModel.totalQuestions)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                if viewModel.showsImmediateFeedback && viewModel.correctCount + viewModel.incorrectCount > 0 {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.correct)
                            Text("\(viewModel.correctCount)")
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.incorrect)
                            Text("\(viewModel.incorrectCount)")
                        }
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .padding(.top, AppTheme.Spacing.sm)
    }
    
    // MARK: - Question Card
    
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if let question = viewModel.currentQuestion {
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
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .stroke(Color(hex: question.category.color), lineWidth: 1)
                        )
                    
                    Spacer()
                }
                
                // Question Text
                Text(question.cleanText)
                    .font(AppTheme.Typography.questionText)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Diagram (if available)
                if question.hasDiagram {
                    DiagramView(diagramName: question.diagramName)
                }
            }
        }
        .padding(AppTheme.Spacing.xl)
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
    
    private var answerOptions: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if let question = viewModel.currentQuestion {
                ForEach(Array(CorrectAnswer.allCases.enumerated()), id: \.element) { index, answer in
                    AnswerButton(
                        letter: answer.rawValue,
                        text: question.options[index],
                        state: viewModel.getAnswerState(for: answer),
                        isCorrectAnswer: viewModel.isAnswerLocked && answer == question.correctAnswer
                    ) {
                        withAnimation(AppTheme.Animation.quick) {
                            viewModel.selectAnswer(answer)
                        }
                    }
                    .disabled(viewModel.isAnswerLocked)
                }
            }
        }
    }
    
    // MARK: - Bottom Navigation
    
    private var bottomNavigation: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Previous Button
            Button {
                viewModel.moveToPrevious()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
            }
            .disabled(!viewModel.canGoBack)
            .opacity(viewModel.canGoBack ? 1 : 0.5)
            
            Spacer()
            
            // Next / Submit / Finish Button
            Button {
                if viewModel.showsImmediateFeedback {
                    // Immediate feedback mode (Practice): Submit then wait for Next
                    if !viewModel.isAnswerLocked && viewModel.selectedAnswer != nil {
                        viewModel.submitAnswer()
                    } else if viewModel.isAnswerLocked {
                        if viewModel.isLastQuestion {
                            viewModel.finishQuiz()
                        } else {
                            viewModel.moveToNext()
                        }
                    }
                } else {
                    // Non-immediate feedback mode (Test): Move on
                    if viewModel.isLastQuestion {
                        viewModel.finishQuiz()
                    } else {
                        viewModel.moveToNext()
                    }
                }
            } label: {
                HStack {
                    Text(nextButtonTitle)
                    if nextButtonTitle != "Submit" {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .disabled(viewModel.selectedAnswer == nil && viewModel.showsImmediateFeedback)
            .opacity((viewModel.selectedAnswer == nil && viewModel.showsImmediateFeedback) ? 0.5 : 1)
        }
        .font(AppTheme.Typography.bodyMedium)
        .foregroundColor(AppTheme.Colors.oceanBlue)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBackground)
    }
    
    private var nextButtonTitle: String {
        if !viewModel.isAnswerLocked && viewModel.showsImmediateFeedback {
            return "Submit"
        } else if viewModel.isLastQuestion {
            return "Finish"
        } else {
            return "Next"
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("No Questions Available")
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("There are no questions matching your criteria. Try a different mode or category.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Go Back") {
                onDismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(AppTheme.Spacing.xxxl)
    }
    
    // MARK: - Share Results
    
    private func shareResults() {
        guard let session = viewModel.session else { return }
        
        // Generate PDF
        if let pdfData = PDFGenerator.shared.generateTestResultsPDF(
            mode: mode.displayName,
            date: Date(),
            score: viewModel.score,
            correctCount: viewModel.correctCount,
            totalQuestions: viewModel.totalQuestions,
            timeTaken: session.elapsedTime,
            questions: session.questions,
            answers: session.answers
        ) {
            // Save to temp file
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
            let filename = "NauticalRules_\(dateFormatter.string(from: Date())).pdf"
            
            if let url = PDFGenerator.shared.savePDFToTemp(data: pdfData, filename: filename) {
                shareItem = ShareItem(url: url)
            }
        }
    }
}

// MARK: - Share Item

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    QuizView(mode: .quickQuiz(questionCount: 10)) {}
        .environmentObject(QuestionService.shared)
        .environmentObject(ProgressService.shared)
}
