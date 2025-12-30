//
//  ProgressView.swift
//  NauticalRules
//
//  Progress page with test history and bookmarks
//

import SwiftUI

struct ProgressView: View {
    
    // MARK: - State
    
    @EnvironmentObject var progressService: ProgressService
    @EnvironmentObject var questionService: QuestionService
    
    @State private var selectedTab = 0
    @State private var selectedHistoryEntry: QuizHistoryEntry?
    @State private var selectedBookmark: Question?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Progress Summary
                    progressSummaryCard
                    
                    // Tab Selector
                    Picker("View", selection: $selectedTab) {
                        Text("Test History").tag(0)
                        Text("Rule Stats").tag(1)
                        Text("Bookmarks").tag(2)
                    }
                    .pickerStyle(.segmented)
                    
                    // Content
                    if selectedTab == 0 {
                        testHistorySection
                    } else if selectedTab == 1 {
                        ruleStatsSection
                    } else {
                        bookmarksSection
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.xl)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $selectedHistoryEntry) { entry in
                HistoryResultsView(historyEntry: entry) {
                    selectedHistoryEntry = nil
                }
                .environmentObject(questionService)
            }
            .sheet(item: $selectedBookmark) { question in
                BookmarkedQuestionDetailView(question: question)
                    .environmentObject(progressService)
            }
        }
    }
    
    // MARK: - Progress Summary Card
    
    private var progressSummaryCard: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Mastery Level Header
            HStack(spacing: AppTheme.Spacing.lg) {
                // Level Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: progressService.masteryLevel.color).opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: progressService.masteryLevel.icon)
                        .font(.title)
                        .foregroundColor(Color(hex: progressService.masteryLevel.color))
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(progressService.masteryLevel.rawValue)
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(progressService.masteryLevel.description)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Stats Row
            HStack(spacing: AppTheme.Spacing.xl) {
                ProgressStatItem(
                    value: "\(progressService.totalQuizzesTaken)",
                    label: "Tests Taken"
                )
                
                ProgressStatItem(
                    value: String(format: "%.0f%%", progressService.overallAccuracy),
                    label: "Accuracy"
                )
                
                ProgressStatItem(
                    value: "\(progressService.streakDays)",
                    label: "Day Streak"
                )
            }
        }
        .padding(AppTheme.Spacing.xl)
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
    
    // MARK: - Test History Section
    
    private var testHistorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if progressService.recentQuizzes.isEmpty {
                emptyStateView(
                    icon: "doc.text",
                    title: "No Tests Yet",
                    message: "Complete a test to see your history here"
                )
            } else {
                ForEach(progressService.recentQuizzes) { quiz in
                    Button {
                        selectedHistoryEntry = quiz
                    } label: {
                        TestHistoryRow(entry: quiz)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Rule Stats Section
    
    private var ruleStatsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Get all chapter categories from questions and sort numerically
            let allRules = questionService.allChapterCategories.sorted { extractRuleNumber($0) < extractRuleNumber($1) }
            
            if allRules.isEmpty {
                emptyStateView(
                    icon: "chart.bar",
                    title: "No Rules Available",
                    message: "Question data is loading..."
                )
            } else {
                ForEach(allRules, id: \.self) { rule in
                    let stats = progressService.getChapterCategoryStats(for: rule)
                    let totalQuestions = questionService.questionCount(for: rule)
                    RuleStatRow(rule: rule, stats: stats, totalQuestions: totalQuestions)
                }
            }
        }
    }
    
    /// Extract rule number for sorting (e.g., "Rule 34" -> 34)
    private func extractRuleNumber(_ rule: String) -> Int {
        let digits = rule.filter { $0.isNumber }
        return Int(digits) ?? 999
    }
    
    // MARK: - Bookmarks Section
    
    private var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if progressService.bookmarkCount == 0 {
                emptyStateView(
                    icon: "bookmark",
                    title: "No Bookmarks",
                    message: "Bookmark questions during practice to review them here"
                )
            } else {
                // Get bookmarks in reverse chronological order (most recent first)
                let orderedIds = progressService.bookmarkedIds.reversed()
                let bookmarkedQuestions = questionService.getQuestionsInOrder(ids: Array(orderedIds))
                ForEach(bookmarkedQuestions) { question in
                    Button {
                        selectedBookmark = question
                    } label: {
                        BookmarkedQuestionRow(question: question)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(message)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xxxl)
    }
}

// MARK: - Supporting Views

struct ProgressStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RuleStatRow: View {
    let rule: String
    let stats: CategoryStats
    let totalQuestions: Int
    
    private var hasAttempted: Bool {
        stats.answered > 0
    }
    
    private var accuracyColor: Color {
        guard hasAttempted else { return AppTheme.Colors.textTertiary }
        switch stats.accuracy {
        case 80...:
            return AppTheme.Colors.correct
        case 60..<80:
            return AppTheme.Colors.warning
        default:
            return AppTheme.Colors.incorrect
        }
    }
    
    private var statusIcon: String {
        guard hasAttempted else { return "circle" }
        switch stats.accuracy {
        case 80...:
            return "checkmark.circle.fill"
        case 60..<80:
            return "exclamationmark.circle.fill"
        default:
            return "xmark.circle.fill"
        }
    }
    
    private var completionProgress: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(stats.answered) / Double(totalQuestions)
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Status icon
            Image(systemName: statusIcon)
                .foregroundColor(accuracyColor)
                .font(.title3)
            
            // Rule name and completion
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(rule)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("\(stats.answered)/\(totalQuestions) completed")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            // Accuracy
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xxs) {
                if hasAttempted {
                    Text(String(format: "%.0f%%", stats.accuracy))
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(accuracyColor)
                    
                    Text("\(stats.correct) correct")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                } else {
                    Text("—")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    
                    Text("Not started")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            
            // Progress bar (showing completion %)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.border)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(hasAttempted ? accuracyColor : AppTheme.Colors.textTertiary)
                        .frame(width: geometry.size.width * completionProgress, height: 8)
                }
            }
            .frame(width: 50, height: 8)
        }
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

struct TestHistoryRow: View {
    let entry: QuizHistoryEntry
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Score Circle
            ZStack {
                Circle()
                    .fill(entry.score >= 70 ? AppTheme.Colors.correct.opacity(0.15) : AppTheme.Colors.incorrect.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Text("\(Int(entry.score))%")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(entry.score >= 70 ? AppTheme.Colors.correct : AppTheme.Colors.incorrect)
            }
            
            // Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(entry.mode)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(formattedDate)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            
            Spacer()
            
            // Duration
            Text(formattedTime)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
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
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
    
    private var formattedTime: String {
        let minutes = Int(entry.timeTaken) / 60
        let seconds = Int(entry.timeTaken) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct BookmarkedQuestionRow: View {
    let question: Question
    @EnvironmentObject var progressService: ProgressService
    
    private var isBookmarked: Bool {
        progressService.isBookmarked(questionId: question.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Question text
            Text(question.text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
            
            // Category + Bookmark button
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
                
                Button {
                    progressService.toggleBookmark(questionId: question.id)
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isBookmarked ? AppTheme.Colors.coral : AppTheme.Colors.textSecondary)
                }
            }
        }
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

// MARK: - Preview

#Preview {
    ProgressView()
        .environmentObject(QuestionService.shared)
        .environmentObject(ProgressService.shared)
}

// MARK: - Bookmarked Question Detail View

struct BookmarkedQuestionDetailView: View {
    let question: Question
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var progressService: ProgressService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Question Card
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        // Category, Jurisdiction & Chapter badges
                        HStack(spacing: AppTheme.Spacing.sm) {
                            // Category badge
                            Text(question.category.shortName)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(Color(hex: question.category.color))
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, AppTheme.Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: question.category.color).opacity(0.15))
                                )
                            
                            // Jurisdiction badge
                            Text(question.jurisdiction.shortName)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(Color(hex: question.jurisdiction.color))
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, AppTheme.Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: question.jurisdiction.color).opacity(0.15))
                                )
                            
                            // Chapter category badge (if available)
                            if !question.chapterCategory.isEmpty {
                                Text(question.chapterCategory)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.oceanBlue)
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xxs)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.Colors.oceanBlue.opacity(0.15))
                                    )
                            }
                            
                            Spacer()
                        }
                        
                        // Question text
                        Text(question.cleanText)
                            .font(AppTheme.Typography.questionText)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Diagram if available
                        if question.hasDiagram {
                            DiagramView(diagramName: question.diagramName)
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
                    
                    // Answer options
                    VStack(spacing: AppTheme.Spacing.sm) {
                        answerOptionRow(letter: "A", option: question.optionA)
                        answerOptionRow(letter: "B", option: question.optionB)
                        answerOptionRow(letter: "C", option: question.optionC)
                        answerOptionRow(letter: "D", option: question.optionD)
                    }
                    
                    // Explanation section
                    if !question.explanation.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(AppTheme.Colors.warning)
                                Text("Explanation")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                            
                            Text(question.explanation)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(AppTheme.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .fill(AppTheme.Colors.warning.opacity(0.1))
                        )
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Bookmarked Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let wasBookmarked = progressService.isBookmarked(questionId: question.id)
                        progressService.toggleBookmark(questionId: question.id)
                        // If we just removed the bookmark, dismiss the sheet
                        if wasBookmarked {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: progressService.isBookmarked(questionId: question.id) ? "bookmark.fill" : "bookmark")
                            .foregroundColor(progressService.isBookmarked(questionId: question.id) ? AppTheme.Colors.coral : AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func answerOptionRow(letter: String, option: String) -> some View {
        let isCorrect = question.correctAnswer.rawValue == letter
        HStack(spacing: AppTheme.Spacing.md) {
            // Letter circle
            ZStack {
                Circle()
                    .fill(isCorrect ? AppTheme.Colors.correct : AppTheme.Colors.cardBackground)
                    .frame(width: 32, height: 32)
                
                Text(letter)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(isCorrect ? .white : AppTheme.Colors.textSecondary)
            }
            
            Text(option)
                .font(AppTheme.Typography.body)
                .foregroundColor(isCorrect ? AppTheme.Colors.correct : AppTheme.Colors.textPrimary)
            
            Spacer()
            
            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.correct)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(isCorrect ? AppTheme.Colors.correct.opacity(0.1) : AppTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(isCorrect ? AppTheme.Colors.correct : Color.clear, lineWidth: 2)
                )
        )
    }
}

#Preview("Bookmarked Question Detail") {
    BookmarkedQuestionDetailView(
        question: Question(
            id: 1,
            text: "BOTH INTERNATIONAL & INLAND What is the minimum length of a power-driven vessel that must show a forward masthead light and an after masthead light?",
            optionA: "50 meters",
            optionB: "100 meters",
            optionC: "150 meters",
            optionD: "200 meters",
            correctAnswer: .a,
            diagramName: nil,
            category: .partC,
            explanation: "A power-driven vessel of 50 meters or more in length must exhibit a second masthead light (after) in addition to the forward masthead light.",
            chapterCategory: "Rule 23"
        )
    )
    .environmentObject(ProgressService.shared)
}
