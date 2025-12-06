//
//  NauticalRulesApp.swift
//  NauticalRules
//
//  Main entry point for the Nautical Rules Quiz App
//

import SwiftUI

@main
struct NauticalRulesApp: App {
    
    // MARK: - Services
    
    @StateObject private var questionService = QuestionService.shared
    @StateObject private var progressService = ProgressService.shared
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(questionService)
                .environmentObject(progressService)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    // MARK: - Setup
    
    private func setupApp() {
        // Load questions
        questionService.loadQuestions()
        
        // Configure appearance
        configureNavigationBarAppearance()
        configureTabBarAppearance()
    }
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.Colors.primaryNavy)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 19, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.Colors.cardBackground)
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
