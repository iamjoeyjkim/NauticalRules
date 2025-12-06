//
//  ContentView.swift
//  NauticalRules
//
//  Main content view with tab navigation
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - State
    
    @State private var selectedTab: Tab = .home
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "book.fill")
                }
                .tag(Tab.practice)
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(Tab.progress)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(AppTheme.Colors.primaryNavy)
        .preferredColorScheme(.light)
    }
}

// MARK: - Tab Enum

enum Tab: Hashable {
    case home
    case practice
    case progress
    case settings
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(QuestionService.shared)
        .environmentObject(ProgressService.shared)
}
