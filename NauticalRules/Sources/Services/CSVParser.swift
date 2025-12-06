//
//  CSVParser.swift
//  NauticalRules
//
//  Utility for parsing the quiz question CSV file
//

import Foundation

// MARK: - CSV Parser

struct CSVParser {
    
    /// Parse the Nautical Rules Test Bank CSV file
    static func parseQuestions(from csvContent: String) -> [Question] {
        var questions: [Question] = []
        
        print("CSVParser: Content length: \(csvContent.count) characters")
        print("CSVParser: First 200 chars: \(String(csvContent.prefix(200)))")
        
        // Debug: Show character codes around first expected newline (around position 130)
        let debugChars = Array(csvContent.prefix(150).suffix(30))
        let charCodes = debugChars.map { char -> String in
            let ascii = char.asciiValue ?? 0
            if ascii == 10 { return "[LF]" }
            if ascii == 13 { return "[CR]" }
            if ascii < 32 { return "[\\(ascii)]" }
            return String(char)
        }
        print("CSVParser: Chars around pos 130: \(charCodes.joined())")
        
        // Check for BOM and remove if present
        var content = csvContent
        if content.hasPrefix("\u{FEFF}") {
            content = String(content.dropFirst())
            print("CSVParser: Removed BOM")
        }
        
        let rows = parseCSV(content)
        
        print("CSVParser: Parsed \(rows.count) rows from CSV")
        if rows.count > 0 {
            print("CSVParser: First row has \(rows[0].count) columns")
            print("CSVParser: Header: \(rows[0].prefix(5).joined(separator: ", "))...")
        }
        if rows.count > 1 {
            print("CSVParser: Second row has \(rows[1].count) columns")
            print("CSVParser: First few values: \(rows[1].prefix(3).joined(separator: " | "))")
        }
        
        // Skip header row
        let dataRows = rows.dropFirst()
        
        for (index, row) in dataRows.enumerated() {
            // Need at least 7 columns (id, text, options A-D, correct answer)
            guard row.count >= 7 else { 
                if index < 3 {
                    print("CSVParser: Row \(index) skipped - only \(row.count) columns: \(row.prefix(3))")
                }
                continue 
            }
            
            // Parse each column
            guard let id = Int(row[0].trimmingCharacters(in: .whitespaces)) else { 
                if index < 3 {
                    print("CSVParser: Row \(index) invalid ID: '\(row[0])'")
                }
                continue 
            }
            
            let questionText = row[1].trimmingCharacters(in: .whitespaces)
            let optionA = row[2].trimmingCharacters(in: .whitespaces)
            let optionB = row[3].trimmingCharacters(in: .whitespaces)
            let optionC = row[4].trimmingCharacters(in: .whitespaces)
            let optionD = row[5].trimmingCharacters(in: .whitespaces)
            let correctAnswerStr = row[6].trimmingCharacters(in: .whitespaces).uppercased()
            let diagramName = row.count > 7 ? row[7].trimmingCharacters(in: .whitespaces) : ""
            let categoryStr = row.count > 8 ? row[8].trimmingCharacters(in: .whitespaces) : ""
            let explanation = row.count > 9 ? row[9].trimmingCharacters(in: .whitespaces) : ""
            
            // Parse correct answer
            guard let correctAnswer = CorrectAnswer(rawValue: correctAnswerStr) else { 
                if index < 3 {
                    print("CSVParser: Row \(index) invalid answer: '\(correctAnswerStr)'")
                }
                continue 
            }
            
            // Parse category
            let category = QuestionCategory.from(string: categoryStr)
            
            // Create question
            let question = Question(
                id: id,
                text: questionText,
                optionA: optionA,
                optionB: optionB,
                optionC: optionC,
                optionD: optionD,
                correctAnswer: correctAnswer,
                diagramName: diagramName.isEmpty ? nil : diagramName,
                category: category,
                explanation: explanation
            )
            
            questions.append(question)
        }
        
        print("CSVParser: Successfully parsed \(questions.count) questions")
        return questions
    }
    
    /// Parse CSV content into rows and columns
    /// Handles quoted fields with commas and embedded newlines
    private static func parseCSV(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        // Normalize line endings first - replace all \r\n and \r with \n
        let normalizedContent = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        for char in normalizedContent {
            if insideQuotes {
                if char == "\"" {
                    // Check if it's an escaped quote by looking ahead
                    // We'll handle this by checking for double quotes in a second pass
                    insideQuotes = false
                } else {
                    currentField.append(char)
                }
            } else {
                switch char {
                case "\"":
                    // Check if this is a closing quote followed by another quote (escaped)
                    insideQuotes = true
                case ",":
                    currentRow.append(currentField)
                    currentField = ""
                case "\n":
                    currentRow.append(currentField)
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                    currentField = ""
                default:
                    currentField.append(char)
                }
            }
        }
        
        // Don't forget the last row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                rows.append(currentRow)
            }
        }
        
        // Handle escaped quotes (double quotes become single quotes)
        return rows.map { row in
            row.map { field in
                field.replacingOccurrences(of: "\"\"", with: "\"")
            }
        }
    }
}

// MARK: - CSV File Loader

extension CSVParser {
    
    /// Load questions from the bundled CSV file
    static func loadQuestionsFromBundle() -> [Question] {
        print("CSVParser: Attempting to load CSV from bundle...")
        
        // Try multiple resource name variations
        let resourceNames = [
            "Nautical Rules Test Bank",
            "Nautical_Rules_Test_Bank",
            "NauticalRulesTestBank"
        ]
        
        for resourceName in resourceNames {
            if let url = Bundle.main.url(forResource: resourceName, withExtension: "csv") {
                print("CSVParser: Found CSV at \(url.path)")
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let questions = parseQuestions(from: content)
                    if !questions.isEmpty {
                        return questions
                    }
                } catch {
                    print("CSVParser: Error loading CSV from \(resourceName): \(error)")
                }
            }
        }
        
        // Try loading from all CSV files in the bundle
        if let urls = Bundle.main.urls(forResourcesWithExtension: "csv", subdirectory: nil) {
            print("CSVParser: Found \(urls.count) CSV files in bundle")
            for url in urls {
                print("CSVParser: Trying \(url.lastPathComponent)")
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let questions = parseQuestions(from: content)
                    if !questions.isEmpty {
                        return questions
                    }
                } catch {
                    print("CSVParser: Error loading \(url.lastPathComponent): \(error)")
                }
            }
        }
        
        print("CSVParser: Could not find CSV file in bundle")
        print("CSVParser: Bundle path: \(Bundle.main.bundlePath)")
        
        return []
    }
    
    /// Load questions from a file path (for testing)
    static func loadQuestions(from filePath: String) -> [Question] {
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            return parseQuestions(from: content)
        } catch {
            print("CSVParser: Error loading CSV from path: \(error)")
            return []
        }
    }
}

