//
//  Question.swift
//  NauticalRules
//
//  Core data model for quiz questions
//

import Foundation

// MARK: - Question Model

struct Question: Identifiable, Codable, Hashable {
    let id: Int
    let text: String
    let optionA: String
    let optionB: String
    let optionC: String
    let optionD: String
    let correctAnswer: CorrectAnswer
    let diagramName: String?
    let category: QuestionCategory
    let explanation: String
    let chapterCategory: String
    
    // Computed property to get jurisdiction type from question text
    var jurisdiction: JurisdictionType {
        if text.hasPrefix("INLAND ONLY") {
            return .inlandOnly
        } else if text.hasPrefix("INTERNATIONAL ONLY") {
            return .internationalOnly
        } else if text.contains("BOTH INTERNATIONAL & INLAND") || text.contains("BOTH INTERNATIONAL \u{0026} INLAND") {
            return .both
        }
        return .both
    }
    
    // Clean question text without jurisdiction prefix
    var cleanText: String {
        var cleaned = text
        let prefixes = ["INLAND ONLY ", "INTERNATIONAL ONLY ", "BOTH INTERNATIONAL & INLAND ", "BOTH INTERNATIONAL \u{0026} INLAND "]
        for prefix in prefixes {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                break
            }
        }
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
    
    // All options as an array
    var options: [String] {
        [optionA, optionB, optionC, optionD]
    }
    
    // Get the correct answer text
    var correctAnswerText: String {
        switch correctAnswer {
        case .a: return optionA
        case .b: return optionB
        case .c: return optionC
        case .d: return optionD
        }
    }
    
    // Check if answer is correct
    func isCorrect(_ answer: CorrectAnswer) -> Bool {
        return answer == correctAnswer
    }
    
    // Has diagram
    var hasDiagram: Bool {
        guard let diagram = diagramName else { return false }
        return !diagram.isEmpty
    }
}

// MARK: - Correct Answer Enum

enum CorrectAnswer: String, Codable, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    
    var index: Int {
        switch self {
        case .a: return 0
        case .b: return 1
        case .c: return 2
        case .d: return 3
        }
    }
    
    static func from(index: Int) -> CorrectAnswer? {
        switch index {
        case 0: return .a
        case 1: return .b
        case 2: return .c
        case 3: return .d
        default: return nil
        }
    }
}

// MARK: - Question Category

enum QuestionCategory: String, Codable, CaseIterable, Identifiable {
    case partA = "Part A: General"
    case partB = "Part B: Steering and Sailing Rules"
    case partC = "Part C: Lights and Shapes"
    case partD = "Part D: Sounds and Light Signals"
    case annexes = "Annexes"
    
    var id: String { rawValue }
    
    var shortName: String {
        switch self {
        case .partA: return "General"
        case .partB: return "Steering & Sailing"
        case .partC: return "Lights & Shapes"
        case .partD: return "Sounds & Signals"
        case .annexes: return "Annexes"
        }
    }
    
    var icon: String {
        switch self {
        case .partA: return "doc.text"
        case .partB: return "helm"
        case .partC: return "lightbulb"
        case .partD: return "speaker.wave.2"
        case .annexes: return "list.clipboard"
        }
    }
    
    var color: String {
        switch self {
        case .partA: return "1a365d"     // Navy
        case .partB: return "2c5282"     // Blue
        case .partC: return "ed8936"     // Orange
        case .partD: return "38b2ac"     // Teal
        case .annexes: return "805ad5"   // Purple
        }
    }
    
    static func from(string: String) -> QuestionCategory {
        for category in QuestionCategory.allCases {
            if string.contains(category.rawValue) || category.rawValue.contains(string) {
                return category
            }
        }
        // Try partial matches
        let lowercased = string.lowercased()
        if lowercased.contains("general") { return .partA }
        if lowercased.contains("steering") || lowercased.contains("sailing") { return .partB }
        if lowercased.contains("light") && lowercased.contains("shape") { return .partC }
        if lowercased.contains("sound") || lowercased.contains("signal") { return .partD }
        if lowercased.contains("annex") { return .annexes }
        
        return .partA // Default
    }
}

// MARK: - Jurisdiction Type

enum JurisdictionType: String, Codable, CaseIterable {
    case inlandOnly = "INLAND ONLY"
    case internationalOnly = "INTERNATIONAL ONLY"
    case both = "BOTH"
    
    var displayName: String {
        switch self {
        case .inlandOnly: return "Inland Only"
        case .internationalOnly: return "International Only"
        case .both: return "Inland & International"
        }
    }
    
    var shortName: String {
        switch self {
        case .inlandOnly: return "Inland"
        case .internationalOnly: return "Int'l"
        case .both: return "Inland & International"
        }
    }
    
    var color: String {
        switch self {
        case .inlandOnly: return "48bb78"      // Green
        case .internationalOnly: return "4299e1" // Blue
        case .both: return "805ad5"             // Purple
        }
    }
}
