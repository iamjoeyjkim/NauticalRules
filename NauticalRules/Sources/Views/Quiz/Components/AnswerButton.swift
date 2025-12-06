//
//  AnswerButton.swift
//  NauticalRules
//
//  Interactive answer option button with state-based styling
//

import SwiftUI

struct AnswerButton: View {
    
    // MARK: - Properties
    
    let letter: String
    let text: String
    let state: AnswerState
    let isCorrectAnswer: Bool
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Letter Circle
                ZStack {
                    Circle()
                        .fill(letterBackgroundColor)
                        .frame(width: 36, height: 36)
                    
                    if state == .correct || (isCorrectAnswer && state != .normal) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else if state == .incorrect {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text(letter)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(letterTextColor)
                    }
                }
                
                // Answer Text
                Text(text)
                    .font(AppTheme.Typography.answerText)
                    .foregroundColor(state.textColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Result indicator
                if isCorrectAnswer {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.correct)
                        .font(.title3)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(state.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(state.borderColor, lineWidth: state == .selected ? 2 : 1)
            )
        }
        .buttonStyle(AnswerButtonStyle())
    }
    
    // MARK: - Helper Properties
    
    private var letterBackgroundColor: Color {
        switch state {
        case .normal:
            return AppTheme.Colors.background
        case .selected:
            return AppTheme.Colors.oceanBlue
        case .correct:
            return AppTheme.Colors.correct
        case .incorrect:
            return AppTheme.Colors.incorrect
        }
    }
    
    private var letterTextColor: Color {
        switch state {
        case .normal:
            return AppTheme.Colors.textSecondary
        case .selected, .correct, .incorrect:
            return .white
        }
    }
}

// MARK: - Answer Button Style

struct AnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        AnswerButton(
            letter: "A",
            text: "This is a normal answer option that might be quite long and wrap to multiple lines.",
            state: .normal,
            isCorrectAnswer: false
        ) {}
        
        AnswerButton(
            letter: "B",
            text: "This is a selected answer",
            state: .selected,
            isCorrectAnswer: false
        ) {}
        
        AnswerButton(
            letter: "C",
            text: "This is the correct answer",
            state: .correct,
            isCorrectAnswer: true
        ) {}
        
        AnswerButton(
            letter: "D",
            text: "This is an incorrect answer",
            state: .incorrect,
            isCorrectAnswer: false
        ) {}
    }
    .padding()
    .background(AppTheme.Colors.background)
}
