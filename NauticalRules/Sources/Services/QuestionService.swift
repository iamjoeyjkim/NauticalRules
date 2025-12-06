//
//  QuestionService.swift
//  NauticalRules
//
//  Service for managing and providing quiz questions
//

import Foundation
import SwiftUI

// MARK: - Question Service

@MainActor
class QuestionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var allQuestions: [Question] = []
    @Published private(set) var isLoaded: Bool = false
    @Published private(set) var loadError: String?
    
    // MARK: - Computed Properties
    
    var questionCount: Int {
        allQuestions.count
    }
    
    var categories: [QuestionCategory] {
        QuestionCategory.allCases
    }
    
    var jurisdictions: [JurisdictionType] {
        JurisdictionType.allCases
    }
    
    // MARK: - Singleton
    
    static let shared = QuestionService()
    
    private init() {}
    
    // MARK: - Loading
    
    func loadQuestions() {
        guard !isLoaded else { return }
        
        print("=== QuestionService: Starting to load questions ===")
        print("Bundle path: \(Bundle.main.bundlePath)")
        
        // Debug: List all resources in bundle
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("Files in bundle root (\(items.count) items):")
                for item in items.prefix(20) {
                    print("  - \(item)")
                }
                if items.count > 20 {
                    print("  ... and \(items.count - 20) more")
                }
            } catch {
                print("Error listing bundle contents: \(error)")
            }
        }
        
        // Try to find CSV files
        if let csvURLs = Bundle.main.urls(forResourcesWithExtension: "csv", subdirectory: nil) {
            print("CSV files found: \(csvURLs.count)")
            for url in csvURLs {
                print("  - \(url.lastPathComponent)")
            }
        } else {
            print("No CSV files found in bundle!")
        }
        
        let questions = CSVParser.loadQuestionsFromBundle()
        
        if questions.isEmpty {
            loadError = "Failed to load questions from the test bank."
            print("ERROR: No questions loaded!")
        } else {
            allQuestions = questions
            isLoaded = true
            print("SUCCESS: Loaded \(questions.count) questions")
        }
        
        print("=== QuestionService: Finished loading ===")
    }
    
    func loadQuestions(from content: String) {
        let questions = CSVParser.parseQuestions(from: content)
        allQuestions = questions
        isLoaded = !questions.isEmpty
        if questions.isEmpty {
            loadError = "No questions parsed from content."
        }
    }
    
    // MARK: - Filtering
    
    func questions(for category: QuestionCategory) -> [Question] {
        allQuestions.filter { $0.category == category }
    }
    
    func questions(for jurisdiction: JurisdictionType) -> [Question] {
        allQuestions.filter { $0.jurisdiction == jurisdiction }
    }
    
    func questions(for category: QuestionCategory?, jurisdiction: JurisdictionType?) -> [Question] {
        allQuestions.filter { question in
            let categoryMatch = category == nil || question.category == category
            let jurisdictionMatch = jurisdiction == nil || question.jurisdiction == jurisdiction
            return categoryMatch && jurisdictionMatch
        }
    }
    
    func question(withId id: Int) -> Question? {
        allQuestions.first { $0.id == id }
    }
    
    func getQuestions(ids: Set<Int>) -> [Question] {
        allQuestions.filter { ids.contains($0.id) }
    }
    
    func questions(withIds ids: Set<Int>) -> [Question] {
        allQuestions.filter { ids.contains($0.id) }
    }
    
    func questions(withIds ids: [Int]) -> [Question] {
        let idSet = Set(ids)
        return allQuestions.filter { idSet.contains($0.id) }
    }
    
    // MARK: - Statistics
    
    func questionCount(for category: QuestionCategory) -> Int {
        questions(for: category).count
    }
    
    func questionCount(for jurisdiction: JurisdictionType) -> Int {
        questions(for: jurisdiction).count
    }
    
    func getCategoryBreakdown() -> [QuestionCategory: Int] {
        var breakdown: [QuestionCategory: Int] = [:]
        for category in QuestionCategory.allCases {
            breakdown[category] = questionCount(for: category)
        }
        return breakdown
    }
    
    func getJurisdictionBreakdown() -> [JurisdictionType: Int] {
        var breakdown: [JurisdictionType: Int] = [:]
        for jurisdiction in JurisdictionType.allCases {
            breakdown[jurisdiction] = questionCount(for: jurisdiction)
        }
        return breakdown
    }
    
    // MARK: - Quiz Generation
    
    func generateQuiz(
        mode: QuizMode,
        questionCount: Int? = nil,
        excludeIds: Set<Int> = []
    ) -> [Question] {
        var pool: [Question]
        
        switch mode {
        case .practice(let category):
            pool = category != nil ? questions(for: category!) : allQuestions
            
        case .exam(let count, _):
            pool = allQuestions
            let shuffled = pool.filter { !excludeIds.contains($0.id) }.shuffled()
            return Array(shuffled.prefix(count))
            
        case .quickQuiz(let count):
            pool = allQuestions.shuffled()
            return Array(pool.prefix(count))
            
        case .review:
            // This should be called with specific IDs from progress service
            return []
            
        case .study(let category):
            pool = category != nil ? questions(for: category!) : allQuestions
        }
        
        // Apply count limit if specified
        var result = pool.filter { !excludeIds.contains($0.id) }
        
        if let count = questionCount {
            result = Array(result.shuffled().prefix(count))
        } else {
            result = result.shuffled()
        }
        
        return result
    }
    
    func generateReviewQuiz(incorrectIds: Set<Int>) -> [Question] {
        questions(withIds: incorrectIds).shuffled()
    }
    
    func generateBookmarkedQuiz(bookmarkedIds: Set<Int>) -> [Question] {
        questions(withIds: bookmarkedIds).shuffled()
    }
    
    // MARK: - Search
    
    func search(query: String) -> [Question] {
        guard !query.isEmpty else { return allQuestions }
        
        let lowercasedQuery = query.lowercased()
        
        return allQuestions.filter { question in
            question.text.lowercased().contains(lowercasedQuery) ||
            question.optionA.lowercased().contains(lowercasedQuery) ||
            question.optionB.lowercased().contains(lowercasedQuery) ||
            question.optionC.lowercased().contains(lowercasedQuery) ||
            question.optionD.lowercased().contains(lowercasedQuery) ||
            question.explanation.lowercased().contains(lowercasedQuery)
        }
    }
    
    // MARK: - Diagrams
    
    func hasDiagram(question: Question) -> Bool {
        question.hasDiagram
    }
    
    func getDiagramURL(for question: Question) -> URL? {
        guard let diagramName = question.diagramName, !diagramName.isEmpty else { return nil }
        
        // Try to find the diagram in the bundle
        // First try the exact name
        if let url = Bundle.main.url(forResource: diagramName, withExtension: "svg") {
            return url
        }
        
        // Try with "diagram_" prefix if it's just a number
        if let number = Int(diagramName) {
            let formattedName = String(format: "diagram_%02d", number)
            if let url = Bundle.main.url(forResource: formattedName, withExtension: "svg") {
                return url
            }
        }
        
        return nil
    }
}

// MARK: - Question Service Extensions

extension QuestionService {
    
    /// Get random questions for daily challenge
    func getDailyChallenge(count: Int = 5) -> [Question] {
        // Use date as seed for consistent daily questions
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let seed = Int(today.timeIntervalSince1970)
        
        var generator = SeededRandomNumberGenerator(seed: UInt64(seed))
        var shuffled = allQuestions
        shuffled.shuffle(using: &generator)
        
        return Array(shuffled.prefix(count))
    }
}

// MARK: - Seeded Random Generator

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
