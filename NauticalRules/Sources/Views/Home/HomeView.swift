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
                Spacer()
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
        }
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
