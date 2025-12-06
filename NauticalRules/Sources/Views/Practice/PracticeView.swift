//
//  PracticeView.swift
//  NauticalRules
//
//  Practice page with category selection
//

import SwiftUI

struct PracticeView: View {
    
    // MARK: - State
    
    @State private var showingPractice = false
    @State private var selectedCategory: QuestionCategory?
    
    @EnvironmentObject var questionService: QuestionService
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // All Categories Row
                    PracticeCategoryRow(
                        title: "All Categories",
                        icon: "square.grid.2x2.fill",
                        color: AppTheme.Colors.primaryNavy
                    ) {
                        selectedCategory = nil
                        showingPractice = true
                    }
                    
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.sm)
                    
                    // Individual Categories
                    ForEach(QuestionCategory.allCases) { category in
                        PracticeCategoryRow(
                            title: category.shortName,
                            icon: category.icon,
                            color: Color(hex: category.color)
                        ) {
                            selectedCategory = category
                            showingPractice = true
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.xl)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingPractice) {
                PracticeSessionView(category: selectedCategory) {
                    showingPractice = false
                }
                .environmentObject(questionService)
            }
        }
    }
}

// MARK: - Practice Category Row

struct PracticeCategoryRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
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
                
                // Title only
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
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
