//
//  Theme.swift
//  NauticalRules
//
//  Design System for Nautical Rules Quiz App
//

import SwiftUI

// MARK: - App Theme

struct AppTheme {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary Palette - Nautical Navy
        static let primaryNavy = Color(hex: "1a365d")
        static let primaryNavyLight = Color(hex: "2c5282")
        static let primaryNavyDark = Color(hex: "0f2744")
        
        // Ocean Blues
        static let oceanBlue = Color(hex: "3182ce")
        static let oceanBlueLight = Color(hex: "4299e1")
        static let seaFoam = Color(hex: "38b2ac")
        
        // Accent Colors
        static let coral = Color(hex: "ed8936")
        static let sunset = Color(hex: "f6ad55")
        
        // Semantic Colors
        static let correct = Color(hex: "48bb78")
        static let correctLight = Color(hex: "68d391")
        static let incorrect = Color(hex: "f56565")
        static let incorrectLight = Color(hex: "fc8181")
        static let warning = Color(hex: "ed8936")
        
        // Neutral Colors
        static let background = Color(hex: "f7fafc")
        static let backgroundDark = Color(hex: "1a202c")
        static let cardBackground = Color.white
        static let cardBackgroundDark = Color(hex: "2d3748")
        static let textPrimary = Color(hex: "1a202c")
        static let textSecondary = Color(hex: "718096")
        static let textTertiary = Color(hex: "a0aec0")
        static let border = Color(hex: "e2e8f0")
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [primaryNavy, oceanBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let oceanGradient = LinearGradient(
            colors: [oceanBlue, seaFoam],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let sunsetGradient = LinearGradient(
            colors: [coral, sunset],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let correctGradient = LinearGradient(
            colors: [correct, correctLight],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let incorrectGradient = LinearGradient(
            colors: [incorrect, incorrectLight],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Display
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        // Body
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let bodyMedium = Font.system(size: 17, weight: .medium)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionBold = Font.system(size: 12, weight: .semibold)
        
        // Question specific
        static let questionText = Font.system(size: 18, weight: .medium)
        static let answerText = Font.system(size: 16, weight: .regular)
        static let explanationText = Font.system(size: 15, weight: .regular)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let sm = Shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        static let md = Shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let lg = Shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let xl = Shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
    }
}

// MARK: - Shadow Helper

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(colorScheme == .dark ? AppTheme.Colors.cardBackgroundDark : AppTheme.Colors.cardBackground)
                    .shadow(
                        color: AppTheme.Shadows.md.color,
                        radius: AppTheme.Shadows.md.radius,
                        x: AppTheme.Shadows.md.x,
                        y: AppTheme.Shadows.md.y
                    )
            )
    }
}

struct GlassCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: AppTheme.Shadows.lg.color,
                        radius: AppTheme.Shadows.lg.radius,
                        x: AppTheme.Shadows.lg.x,
                        y: AppTheme.Shadows.lg.y
                    )
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(isEnabled ? AppTheme.Colors.primaryGradient : LinearGradient(colors: [AppTheme.Colors.textTertiary], startPoint: .leading, endPoint: .trailing))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.Colors.primaryNavy)
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(AppTheme.Colors.primaryNavy, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func glassCardStyle() -> some View {
        modifier(GlassCardStyle())
    }
    
    func applyShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
