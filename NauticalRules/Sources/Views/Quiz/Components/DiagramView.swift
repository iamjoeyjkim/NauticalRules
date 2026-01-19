//
//  DiagramView.swift
//  NauticalRules
//
//  View for displaying SVG diagrams associated with questions
//

import SwiftUI
import WebKit

// MARK: - SVG Web View

struct SVGWebView: UIViewRepresentable {
    let svgContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Create HTML wrapper for SVG with proper scaling
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { 
                    width: 100%; 
                    height: 100%; 
                    background: #C5CCD3;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    border-radius: 8px;
                }
                svg {
                    max-width: 100%;
                    max-height: 100%;
                    width: auto;
                    height: auto;
                    transform: scale(2);
                }
            </style>
        </head>
        <body>
            \(svgContent)
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Diagram View

struct DiagramView: View {
    
    // MARK: - Properties
    
    let diagramName: String?
    @State private var svgContent: String?
    @State private var loadError: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        if let name = diagramName, !name.isEmpty {
            VStack(spacing: AppTheme.Spacing.sm) {
                if let content = svgContent {
                    SVGWebView(svgContent: content)
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                        .frame(maxWidth: .infinity)
                } else if loadError {
                    diagramPlaceholder
                } else {
                    SwiftUI.ProgressView()
                        .frame(height: 100)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
            .onAppear {
                loadSVG(named: name)
            }
            .onChange(of: diagramName) { oldValue, newValue in
                // Reset state and reload when diagram name changes
                svgContent = nil
                loadError = false
                if let newName = newValue, !newName.isEmpty {
                    loadSVG(named: newName)
                }
            }
        }
    }
    
    // MARK: - SVG Loading
    
    private func loadSVG(named name: String) {
        // Clean the name - remove any extension if present
        let cleanName = name.replacingOccurrences(of: ".svg", with: "")
        
        // Try different naming conventions
        var possibleNames: [String] = []
        
        // If name already has "diagram_" prefix, use it as-is first
        if cleanName.hasPrefix("diagram_") {
            possibleNames.append(cleanName)
        } else {
            // Try with prefix
            possibleNames.append("diagram_\(cleanName)")
            // Try formatted number if it's a number
            if let num = Int(cleanName) {
                possibleNames.append(String(format: "diagram_%02d", num))
            }
        }
        // Always also try exact name
        possibleNames.append(cleanName)
        
        for possibleName in possibleNames {
            // Try loading from Diagrams subdirectory
            if let url = Bundle.main.url(forResource: possibleName, withExtension: "svg", subdirectory: "Diagrams") {
                loadSVGFromURL(url)
                return
            }
            
            // Try loading from bundle root
            if let url = Bundle.main.url(forResource: possibleName, withExtension: "svg") {
                loadSVGFromURL(url)
                return
            }
        }
        
        loadError = true
    }
    
    private func loadSVGFromURL(_ url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            svgContent = content
        } catch {
            loadError = true
        }
    }
    
    // MARK: - Placeholder
    
    private var diagramPlaceholder: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("Diagram: \(diagramName ?? "Unknown")")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("Could not load diagram")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(AppTheme.Colors.border.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}

// MARK: - Full Screen Diagram View

struct FullScreenDiagramView: View {
    let diagramName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Close Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                
                Spacer()
                
                // Diagram
                DiagramView(diagramName: diagramName)
                    .padding()
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DiagramView(diagramName: "01")
        DiagramView(diagramName: nil)
    }
    .padding()
    .background(AppTheme.Colors.cardBackground)
}
