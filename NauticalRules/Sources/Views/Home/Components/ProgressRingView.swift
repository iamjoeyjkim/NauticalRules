//
//  ProgressRingView.swift
//  NauticalRules
//
//  Animated circular progress indicator
//

import SwiftUI

struct ProgressRingView: View {
    
    // MARK: - Properties
    
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var gradient: LinearGradient = AppTheme.Colors.oceanGradient
    var backgroundColor: Color = AppTheme.Colors.border
    
    @State private var animatedProgress: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(
                    backgroundColor,
                    lineWidth: lineWidth
                )
            
            // Progress Ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.Animation.smooth, value: animatedProgress)
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = min(max(progress, 0), 1)
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = min(max(newValue, 0), 1)
        }
    }
}

// MARK: - Progress Ring with Percentage

struct ProgressRingWithLabel: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let label: String
    var gradient: LinearGradient = AppTheme.Colors.oceanGradient
    
    var body: some View {
        ProgressRingView(
            progress: progress,
            lineWidth: lineWidth,
            size: size,
            gradient: gradient
        )
        .overlay {
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.primaryNavy)
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Small Progress Ring

struct SmallProgressRing: View {
    let progress: Double
    var color: Color = AppTheme.Colors.oceanBlue
    var size: CGFloat = 24
    var lineWidth: CGFloat = 3
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AppTheme.Colors.border,
                    lineWidth: lineWidth
                )
            
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        ProgressRingView(
            progress: 0.72,
            lineWidth: 12,
            size: 120
        )
        
        ProgressRingWithLabel(
            progress: 0.85,
            lineWidth: 10,
            size: 100,
            label: "Mastery"
        )
        
        HStack(spacing: 20) {
            SmallProgressRing(progress: 0.3, color: AppTheme.Colors.incorrect)
            SmallProgressRing(progress: 0.6, color: AppTheme.Colors.warning)
            SmallProgressRing(progress: 0.9, color: AppTheme.Colors.correct)
        }
    }
    .padding()
}
