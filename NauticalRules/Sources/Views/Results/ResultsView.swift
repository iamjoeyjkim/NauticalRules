//
//  ResultsView.swift
//  NauticalRules
//
//  Quiz results screen showing score and breakdown
//

import SwiftUI

struct ResultsView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: QuizViewModel
    let onDismiss: () -> Void
    let onRestart: () -> Void
    
    // MARK: - Environment
    
    @EnvironmentObject var progressService: ProgressService
    
    // MARK: - State
    
    @State private var animateScore: Bool = false
    @State private var showDetails: Bool = false
    @State private var showingReview: Bool = false
    @State private var showingReviewIncorrectOnly: Bool = true
    
    // MARK: - Body
    
    var body: some View {
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
        .onAppear {
            withAnimation(AppTheme.Animation.smooth.delay(0.3)) {
                animateScore = true
            }
            withAnimation(AppTheme.Animation.smooth.delay(0.6)) {
                showDetails = true
            }
        }
        .fullScreenCover(isPresented: $showingReview) {
            if let session = viewModel.session {
                ReviewAnswersView(
                    questions: session.questions,
                    answers: session.answers,
                    showOnlyIncorrect: showingReviewIncorrectOnly,
                    onDismiss: { showingReview = false }
                )
                .environmentObject(progressService)
            }
        }
    }
    
    // MARK: - Score Card
    
    private var scoreCard: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Score Percentage
            Text("\(Int(viewModel.score))%")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
                .scaleEffect(animateScore ? 1 : 0.8)
                .opacity(animateScore ? 1 : 0)
            
            // Correct Count
            Text("\(viewModel.correctCount) of \(viewModel.totalQuestions) correct")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textSecondary)
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
    
    // Score color based on percentage
    private var scoreColor: Color {
        switch viewModel.score {
        case 80...100:
            return AppTheme.Colors.correct  // Green
        case 60..<80:
            return AppTheme.Colors.warning  // Orange
        default:
            return AppTheme.Colors.incorrect  // Red
        }
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
                value: "\(viewModel.correctCount)",
                label: "Correct",
                color: AppTheme.Colors.correct
            )
            
            StatCard(
                icon: "xmark.circle.fill",
                value: "\(viewModel.incorrectCount)",
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
        .opacity(showDetails ? 1 : 0)
        .offset(y: showDetails ? 0 : 20)
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Category Breakdown")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(viewModel.getCategoryResults()), id: \.key) { category, result in
                    CategoryResultRow(
                        category: category,
                        correct: result.correct,
                        total: result.total
                    )
                }
            }
        }
        .opacity(showDetails ? 1 : 0)
        .offset(y: showDetails ? 0 : 20)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Review Mistakes (if any)
            if viewModel.incorrectCount > 0 {
                Button {
                    showingReviewIncorrectOnly = true
                    showingReview = true
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
                showingReviewIncorrectOnly = false
                showingReview = true
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
        .opacity(showDetails ? 1 : 0)
    }
    
    // MARK: - Helper Properties
    
    private var isPassing: Bool {
        viewModel.score >= 70
    }
    
    private var resultTitle: String {
        switch viewModel.score {
        case 90...100:
            return "Excellent! 🎉"
        case 80..<90:
            return "Great Job! 👏"
        case 70..<80:
            return "Passed! ✓"
        case 50..<70:
            return "Keep Practicing"
        default:
            return "Keep Learning"
        }
    }
    
    private var formattedTime: String {
        guard let session = viewModel.session else { return "--:--" }
        let minutes = Int(session.elapsedTime) / 60
        let seconds = Int(session.elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.cardBackground)
                .shadow(
                    color: AppTheme.Shadows.sm.color,
                    radius: AppTheme.Shadows.sm.radius,
                    x: AppTheme.Shadows.sm.x,
                    y: AppTheme.Shadows.sm.y
                )
        )
    }
}

// MARK: - Category Result Row

struct CategoryResultRow: View {
    let category: QuestionCategory
    let correct: Int
    let total: Int
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color(hex: category.color).opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: category.color))
            }
            
            // Category Name
            Text(category.shortName)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            // Score
            Text("\(correct)/\(total)")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Percentage
            Text("\(Int(percentage))%")
                .font(AppTheme.Typography.headline)
                .foregroundColor(percentage >= 70 ? AppTheme.Colors.correct : AppTheme.Colors.textSecondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(AppTheme.Colors.cardBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    let vm = QuizViewModel()
    return ResultsView(viewModel: vm, onDismiss: {}, onRestart: {})
        .environmentObject(ProgressService.shared)
}
