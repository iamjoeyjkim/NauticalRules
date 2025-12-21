//
//  PracticeView.swift
//  NauticalRules
//
//  Practice page with category and rule selection
//

import SwiftUI

// Helper struct for presenting practice session
struct PracticeSelection: Identifiable {
    let id = UUID()
    let category: QuestionCategory?
    let chapterCategory: String?
}

struct PracticeView: View {
    
    // MARK: - State
    
    @State private var selectedTab = 0  // 0 = By Category, 1 = By Rule
    @State private var practiceSelection: PracticeSelection?
    
    @EnvironmentObject var questionService: QuestionService
    @EnvironmentObject var progressService: ProgressService
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Practice Mode", selection: $selectedTab) {
                    Text("By Category").tag(0)
                    Text("By Rule").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
                
                // Content
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        if selectedTab == 0 {
                            byCategorySection
                        } else {
                            byRuleSection
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.xl)
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $practiceSelection) { selection in
                PracticeSessionView(
                    category: selection.category,
                    chapterCategory: selection.chapterCategory
                ) {
                    practiceSelection = nil
                }
                .environmentObject(questionService)
                .environmentObject(progressService)
            }
        }
    }
    
    // MARK: - By Category Section
    
    private var byCategorySection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // All Categories Row
            PracticeCategoryRow(
                title: "All Categories",
                subtitle: "\(questionService.questionCount) questions",
                icon: "square.grid.2x2.fill",
                color: AppTheme.Colors.primaryNavy
            ) {
                practiceSelection = PracticeSelection(category: nil, chapterCategory: nil)
            }
            
            Divider()
                .padding(.vertical, AppTheme.Spacing.sm)
            
            // Individual Categories
            ForEach(QuestionCategory.allCases) { category in
                PracticeCategoryRow(
                    title: category.shortName,
                    subtitle: "\(questionService.questionCount(for: category)) questions",
                    icon: category.icon,
                    color: Color(hex: category.color)
                ) {
                    practiceSelection = PracticeSelection(category: category, chapterCategory: nil)
                }
            }
        }
    }
    
    // MARK: - By Rule Section
    
    private var byRuleSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // All Rules Row
            PracticeCategoryRow(
                title: "All Rules",
                subtitle: "\(questionService.questionCount) questions",
                icon: "books.vertical.fill",
                color: AppTheme.Colors.primaryNavy
            ) {
                practiceSelection = PracticeSelection(category: nil, chapterCategory: nil)
            }
            
            Divider()
                .padding(.vertical, AppTheme.Spacing.sm)
            
            // Individual Rules sorted numerically
            let allRules = questionService.allChapterCategories.sorted { extractRuleNumber($0) < extractRuleNumber($1) }
            
            ForEach(allRules, id: \.self) { rule in
                let count = questionService.questionCount(for: rule)
                PracticeCategoryRow(
                    title: rule,
                    subtitle: "\(count) questions",
                    icon: "book.fill",
                    color: AppTheme.Colors.oceanBlue
                ) {
                    practiceSelection = PracticeSelection(category: nil, chapterCategory: rule)
                }
            }
        }
    }
    
    /// Extract rule number for sorting (e.g., "Rule 34" -> 34)
    private func extractRuleNumber(_ rule: String) -> Int {
        let digits = rule.filter { $0.isNumber }
        return Int(digits) ?? 999
    }
}

// MARK: - Practice Category Row

struct PracticeCategoryRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    // Convenience init for backward compatibility
    init(title: String, subtitle: String = "", icon: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.cardBackground)
                    .shadow(
                        color: AppTheme.Shadows.sm.color,
                        radius: AppTheme.Shadows.sm.radius,
                        x: AppTheme.Shadows.sm.x,
                        y: AppTheme.Shadows.sm.y
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    PracticeView()
        .environmentObject(QuestionService.shared)
        .environmentObject(ProgressService.shared)
}

