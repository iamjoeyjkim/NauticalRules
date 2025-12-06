//
//  ExplanationCard.swift
//  NauticalRules
//
//  Card showing the explanation for a question's answer
//

import SwiftUI

struct ExplanationCard: View {
    
    // MARK: - Properties
    
    let explanation: String
    @State private var isExpanded: Bool = true
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            Button {
                withAnimation(AppTheme.Animation.smooth) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(AppTheme.Colors.coral)
                    
                    Text("Explanation")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.caption)
                }
            }
            
            // Content
            if isExpanded {
                Text(cleanExplanation)
                    .font(AppTheme.Typography.explanationText)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.coral.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .stroke(AppTheme.Colors.coral.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Clean up explanation text
    private var cleanExplanation: String {
        var cleaned = explanation
        // Remove "Reference:" prefixes if they start a new line
        cleaned = cleaned.replacingOccurrences(of: "\n\nReference:", with: "\n\nReference:")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Rule Reference Card

struct RuleReferenceCard: View {
    let rule: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "book.closed.fill")
                .foregroundColor(AppTheme.Colors.primaryNavy)
            
            Text(rule)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.primaryNavy)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            Capsule()
                .fill(AppTheme.Colors.primaryNavy.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ExplanationCard(
            explanation: "Rule 34(d) of the Inland Rules covers the danger/doubt signal, which is five or more short, rapid blasts. If you doubt the crossing vessel's intentions or whether a safe pass will occur, you must sound the danger signal.\n\nReference: USCG Navigation Rules, Inland Rule 34(d)"
        )
        
        RuleReferenceCard(rule: "Rule 34(d)")
    }
    .padding()
    .background(AppTheme.Colors.background)
}
