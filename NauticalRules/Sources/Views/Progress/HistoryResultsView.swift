//
//  HistoryResultsView.swift
//  NauticalRules
//
//  View for reviewing a past quiz from history
//

import SwiftUI

struct HistoryResultsView: View {
    
    // MARK: - Properties
    
    let historyEntry: QuizHistoryEntry
    let onDismiss: () -> Void
    
    @EnvironmentObject var questionService: QuestionService
    @EnvironmentObject var progressService: ProgressService
    
    // MARK: - State
    
    @State private var reviewMode: ReviewMode?
    @State private var shareItem: ShareItem?
    
    // MARK: - Review Mode Enum
    
    private enum ReviewMode: Identifiable {
        case mistakes
        case all
        
        var id: String {
            switch self {
            case .mistakes: return "mistakes"
            case .all: return "all"
            }
        }
        
        var showOnlyIncorrect: Bool {
            self == .mistakes
        }
    }
    
    // MARK: - Computed Properties
    
    private var questions: [Question] {
        questionService.getQuestionsInOrder(ids: historyEntry.questionIds)
    }
    
    private var answers: [Int: CorrectAnswer] {
        historyEntry.getAnswers()
    }
    
    private var incorrectCount: Int {
        historyEntry.totalQuestions - historyEntry.correctCount
    }
    
    private var scoreColor: Color {
        switch historyEntry.score {
        case 80...100:
            return AppTheme.Colors.correct
        case 60..<80:
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.incorrect
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: historyEntry.date)
    }
    
    private var formattedTime: String {
        let minutes = Int(historyEntry.timeTaken) / 60
        let seconds = Int(historyEntry.timeTaken) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Score Card
                    scoreCard
                    
                    // Stats Grid
                    statsGrid
                    
                    // Category Breakdown
                    categoryBreakdown
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.xxl)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Test Review")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $reviewMode) { mode in
                ReviewAnswersView(
                    questions: questions,
                    answers: answers,
                    showOnlyIncorrect: mode.showOnlyIncorrect,
                    onDismiss: { reviewMode = nil }
                )
                .environmentObject(progressService)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        shareResults()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppTheme.Colors.oceanBlue)
                    }
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(activityItems: [item.url])
            }
        }
    }
    
    // MARK: - Score Card
    
    private var scoreCard: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Date
            Text(formattedDate)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Score Percentage
            Text("\(Int(historyEntry.score))%")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
            
            // Correct Count
            Text("\(historyEntry.correctCount) of \(historyEntry.totalQuestions) correct")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Mode Badge
            Text(historyEntry.mode)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.oceanBlue)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xxs)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.oceanBlue.opacity(0.15))
                )
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(
                    color: AppTheme.Shadows.lg.color,
                    radius: AppTheme.Shadows.lg.radius,
                    x: AppTheme.Shadows.lg.x,
                    y: AppTheme.Shadows.lg.y
                )
        )
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppTheme.Spacing.md) {
            StatCard(
                icon: "checkmark.circle.fill",
                value: "\(historyEntry.correctCount)",
                label: "Correct",
                color: AppTheme.Colors.correct
            )
            
            StatCard(
                icon: "xmark.circle.fill",
                value: "\(incorrectCount)",
                label: "Incorrect",
                color: AppTheme.Colors.incorrect
            )
            
            StatCard(
                icon: "clock.fill",
                value: formattedTime,
                label: "Time",
                color: AppTheme.Colors.oceanBlue
            )
        }
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Category Breakdown")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(getCategoryResults()), id: \.key) { category, result in
                    CategoryResultRow(
                        category: category,
                        correct: result.correct,
                        total: result.total
                    )
                }
            }
        }
    }
    
    private func getCategoryResults() -> [(key: QuestionCategory, value: (correct: Int, total: Int))] {
        var results: [QuestionCategory: (correct: Int, total: Int)] = [:]
        
        for question in questions {
            let category = question.category
            let userAnswer = answers[question.id]
            let isCorrect = userAnswer == question.correctAnswer
            
            let current = results[category] ?? (correct: 0, total: 0)
            results[category] = (
                correct: current.correct + (isCorrect ? 1 : 0),
                total: current.total + 1
            )
        }
        
        return results.sorted { $0.key.rawValue < $1.key.rawValue }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Review Mistakes (if any)
            if incorrectCount > 0 {
                Button {
                    reviewMode = .mistakes
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Review Mistakes")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            // Review All Answers
            Button {
                reviewMode = .all
            } label: {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Review All Answers")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            
            // Done
            Button {
                onDismiss()
            } label: {
                Text("Done")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top, AppTheme.Spacing.lg)
    }
    
    // MARK: - Share Results
    
    private func shareResults() {
        // Generate PDF
        if let pdfData = PDFGenerator.shared.generateTestResultsPDF(
            mode: historyEntry.mode,
            date: historyEntry.date,
            score: historyEntry.score,
            correctCount: historyEntry.correctCount,
            totalQuestions: historyEntry.totalQuestions,
            timeTaken: historyEntry.timeTaken,
            questions: questions,
            answers: answers
        ) {
            // Save to temp file
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
            let filename = "NauticalRules_\(dateFormatter.string(from: historyEntry.date)).pdf"
            
            if let url = PDFGenerator.shared.savePDFToTemp(data: pdfData, filename: filename) {
                shareItem = ShareItem(url: url)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let entry = QuizHistoryEntry(
        date: Date(),
        mode: "Quick Test",
        score: 80,
        timeTaken: 300,
        totalQuestions: 10,
        correctCount: 8,
        questionIds: [],
        answers: [:]
    )
    return HistoryResultsView(historyEntry: entry, onDismiss: {})
        .environmentObject(QuestionService.shared)
        .environmentObject(ProgressService.shared)
}

