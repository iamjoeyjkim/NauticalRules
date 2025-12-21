//
//  SettingsView.swift
//  NauticalRules
//
//  App settings - simplified version
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    
    // MARK: - Constants
    
    private let appStoreURL = URL(string: "https://apps.apple.com/us/app/nautical-rules/id6756220989")!
    private let appStoreReviewURL = URL(string: "https://apps.apple.com/app/id6756220989?action=write-review")!
    
    // MARK: - State
    
    @State private var showingResetConfirmation = false
    @State private var showingAbout = false
    @State private var showingLegal = false
    @State private var showingShareSheet = false
    
    @EnvironmentObject var progressService: ProgressService
    @Environment(\.requestReview) private var requestReview
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Data Section
                dataSection
                
                // Feedback Section
                feedbackSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset Progress?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    progressService.resetProgress()
                }
            } message: {
                Text("This will delete your quiz history and statistics. Your bookmarks will be kept. This action cannot be undone.")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingLegal) {
                LegalView()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [
                    "Check out Nautical Rules - the best app to study USCG Navigation Rules!",
                    appStoreURL
                ])
            }
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            // Reset Progress
            Button {
                showingResetConfirmation = true
            } label: {
                SettingsRow(
                    icon: "trash.fill",
                    title: "Reset Progress",
                    subtitle: "Delete quiz history and statistics",
                    color: AppTheme.Colors.incorrect
                )
            }
        } header: {
            Text("Data")
        }
    }
    
    // MARK: - Feedback Section
    
    private var feedbackSection: some View {
        Section {
            // Rate on App Store
            Button {
                requestReview()
            } label: {
                SettingsRow(
                    icon: "star.fill",
                    title: "Rate on App Store",
                    subtitle: "Help us with a quick review",
                    color: AppTheme.Colors.coral
                )
            }
            
            // Share App
            Button {
                showingShareSheet = true
            } label: {
                SettingsRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Share App",
                    subtitle: "Tell your friends about Nautical Rules",
                    color: AppTheme.Colors.oceanBlue
                )
            }
        } header: {
            Text("Feedback")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            Button {
                showingAbout = true
            } label: {
                SettingsRow(
                    icon: "info.circle.fill",
                    title: "About",
                    subtitle: "Version 2.0.0",
                    color: AppTheme.Colors.primaryNavy
                )
            }
            
            Button {
                showingLegal = true
            } label: {
                SettingsRow(
                    icon: "doc.text.fill",
                    title: "Legal & Disclaimer",
                    subtitle: "Important information",
                    color: AppTheme.Colors.textSecondary
                )
            }
        } header: {
            Text("About")
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // App Icon
                    Image(systemName: "helm")
                        .font(.system(size: 80))
                        .foregroundStyle(AppTheme.Colors.primaryGradient)
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Nautical Rules")
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Version 2.0.0")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("About This App")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Nautical Rules is designed to help you study the USCG Navigation Rules (COLREGS) for both Inland and International waters.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Text("This app contains over 1,200 practice questions covering all aspects of the Navigation Rules, including Steering and Sailing Rules, Lights and Shapes, Sound Signals, and more.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Text("© 2025 Nautical Rules App")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .padding(AppTheme.Spacing.xxl)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Legal View

struct LegalView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Disclaimer Section
                    legalSection(
                        title: "Disclaimer",
                        content: """
                        Nautical Rules is an educational study aid designed to help users prepare for navigation rules examinations. This application is provided "as is" without warranty of any kind, either express or implied.
                        
                        THIS APP IS NOT AN OFFICIAL LEGAL RESOURCE. The content provided in this application should not be used as the sole source of information for actual navigation decisions, legal interpretations, or official maritime operations.
                        """
                    )
                    
                    // No Liability Section
                    legalSection(
                        title: "Limitation of Liability",
                        content: """
                        The developers, publishers, and distributors of this application shall not be held liable for any direct, indirect, incidental, special, consequential, or punitive damages arising from:
                        
                        • The use or inability to use this application
                        • Any errors, inaccuracies, or omissions in the content
                        • Any decisions made based on information provided by this app
                        • Any maritime incidents, accidents, or legal disputes
                        • Any exam results or professional outcomes
                        
                        Users assume all risks associated with the use of this application.
                        """
                    )
                    
                    // Not Official Section
                    legalSection(
                        title: "Not an Official Resource",
                        content: """
                        This application is not affiliated with, endorsed by, or officially connected to the United States Coast Guard (USCG), the International Maritime Organization (IMO), or any other governmental or regulatory body.
                        
                        For official navigation rules, regulations, and legal requirements, users should consult:
                        • Official USCG Navigation Rules publications
                        • International Regulations for Preventing Collisions at Sea (COLREGs)
                        • Applicable local, state, and federal maritime laws
                        """
                    )
                    
                    // Accuracy Section
                    legalSection(
                        title: "Accuracy of Information",
                        content: """
                        While we strive to provide accurate and up-to-date information, we make no representations or warranties about the completeness, reliability, or accuracy of the content in this application.
                        
                        Navigation rules and regulations may change over time. Users are responsible for verifying all information with current official sources before relying on it for any purpose.
                        """
                    )
                    
                    // Educational Use Section
                    legalSection(
                        title: "Educational Use Only",
                        content: """
                        This application is intended solely for educational and study purposes. It is designed to supplement—not replace—proper maritime education, training, and certification programs.
                        
                        By using this application, you acknowledge that you understand and accept these terms and limitations.
                        """
                    )
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Legal & Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func legalSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(content)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.cardBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(QuestionService.shared)
        .environmentObject(ProgressService.shared)
}
