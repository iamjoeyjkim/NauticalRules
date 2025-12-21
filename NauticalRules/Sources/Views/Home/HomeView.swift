//
//  HomeView.swift
//  NauticalRules
//
//  Home screen with test option
//

import SwiftUI

struct HomeView: View {
    
    // MARK: - State
    
    @StateObject private var viewModel = HomeViewModel()
    @AppStorage("defaultQuizSize") private var quizSize = 25
    @State private var focusPracticeSelection: PracticeSelection?
    
    @EnvironmentObject var progressService: ProgressService
    @EnvironmentObject var questionService: QuestionService
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                
                // Centered Content
                VStack(spacing: AppTheme.Spacing.xxxl) {
                    // App Icon/Branding
                    Image(systemName: "helm")
                        .font(.system(size: 64))
                        .foregroundColor(AppTheme.Colors.primaryNavy)
                    
                    // Question Count Picker
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("Select Number of Questions")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Picker("Questions", selection: $quizSize) {
                            Text("10").tag(10)
                            Text("25").tag(25)
                            Text("50").tag(50)
                            Text("100").tag(100)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                    
                    // Take a Test Button
                    Button {
                        viewModel.startQuickQuiz(questionCount: quizSize)
                    } label: {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            
                            Text("Take a Test")
                                .font(AppTheme.Typography.title3)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                                .fill(AppTheme.Colors.primaryNavy)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, AppTheme.Spacing.xl)
                }
                
                Spacer()
                
                // Focus Area Card (if available)
                if let weakArea = progressService.getWeakestChapterCategory() {
                    focusAreaCard(rule: weakArea.rule, accuracy: weakArea.accuracy, answered: weakArea.answered)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Nautical Rules")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $viewModel.showingQuiz) {
                if let mode = viewModel.activeQuizMode {
                    QuizView(mode: mode) {
                        viewModel.dismissQuiz()
                    }
                }
            }
            .fullScreenCover(item: $focusPracticeSelection) { selection in
                PracticeSessionView(
                    category: nil,
                    chapterCategory: selection.chapterCategory
                ) {
                    focusPracticeSelection = nil
                }
                .environmentObject(questionService)
                .environmentObject(progressService)
            }
        }
    }
    
    // MARK: - Focus Area Card
    
    private func focusAreaCard(rule: String, accuracy: Double, answered: Int) -> some View {
        Button {
            focusPracticeSelection = PracticeSelection(category: nil, chapterCategory: rule)
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(AppTheme.Colors.warning)
                    
                    Text("Focus Area")
                        .font(AppTheme.Typography.captionBold)
                        .foregroundColor(AppTheme.Colors.warning)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        Text(rule)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("\(answered) questions answered")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", accuracy))
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.incorrect)
                }
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

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(QuestionService.shared)
        .environmentObject(ProgressService.shared)
}
