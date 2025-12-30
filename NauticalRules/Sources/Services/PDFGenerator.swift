//
//  PDFGenerator.swift
//  NauticalRules
//
//  Generates PDF documents for test results
//

import UIKit
import SwiftUI

/// Generates PDF documents for quiz/test results
class PDFGenerator {
    
    // MARK: - Shared Instance
    
    static let shared = PDFGenerator()
    
    // MARK: - PDF Generation
    
    /// Generates a PDF document with test results
    /// - Parameters:
    ///   - mode: The test mode name (e.g., "Quick Test", "Practice")
    ///   - date: The date the test was taken
    ///   - score: The score percentage
    ///   - correctCount: Number of correct answers
    ///   - totalQuestions: Total number of questions
    ///   - timeTaken: Time taken in seconds
    ///   - questions: Array of questions
    ///   - answers: Dictionary mapping question ID to user's answer
    /// - Returns: PDF data, or nil if generation failed
    func generateTestResultsPDF(
        mode: String,
        date: Date,
        score: Double,
        correctCount: Int,
        totalQuestions: Int,
        timeTaken: TimeInterval,
        questions: [Question],
        answers: [Int: CorrectAnswer]
    ) -> Data? {
        
        let pageWidth: CGFloat = 612 // Letter size
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = pdfRenderer.pdfData { context in
            var currentY: CGFloat = margin
            
            // Start first page
            context.beginPage()
            
            // Title
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let title = "Nautical Rules Test Results"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor(red: 0.1, green: 0.21, blue: 0.36, alpha: 1) // primaryNavy
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: currentY, width: titleSize.width, height: titleSize.height)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            currentY += titleSize.height + 20
            
            // Date and Mode
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: date)
            
            let infoFont = UIFont.systemFont(ofSize: 14, weight: .regular)
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: infoFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            let dateText = "Date: \(dateString)"
            dateText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: infoAttributes)
            currentY += 20
            
            let modeText = "Mode: \(mode)"
            modeText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: infoAttributes)
            currentY += 30
            
            // Score Card
            currentY = drawScoreCard(
                context: context,
                at: currentY,
                margin: margin,
                contentWidth: contentWidth,
                score: score,
                correctCount: correctCount,
                totalQuestions: totalQuestions,
                timeTaken: timeTaken
            )
            
            currentY += 30
            
            // Questions Section
            let sectionTitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
            let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: sectionTitleFont,
                .foregroundColor: UIColor.black
            ]
            
            let questionsTitle = "Questions & Answers"
            questionsTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: sectionTitleAttributes)
            currentY += 30
            
            // Draw each question
            for (index, question) in questions.enumerated() {
                let userAnswer = answers[question.id]
                let isCorrect = userAnswer == question.correctAnswer
                
                // Check if we need a new page
                let estimatedHeight: CGFloat = 200 // Estimate for question block
                if currentY + estimatedHeight > pageHeight - margin {
                    context.beginPage()
                    currentY = margin
                }
                
                currentY = drawQuestion(
                    context: context,
                    at: currentY,
                    margin: margin,
                    contentWidth: contentWidth,
                    pageHeight: pageHeight,
                    index: index + 1,
                    question: question,
                    userAnswer: userAnswer,
                    isCorrect: isCorrect
                )
                
                currentY += 20
            }
        }
        
        return data
    }
    
    // MARK: - Helper Methods
    
    private func drawScoreCard(
        context: UIGraphicsPDFRendererContext,
        at y: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        score: Double,
        correctCount: Int,
        totalQuestions: Int,
        timeTaken: TimeInterval
    ) -> CGFloat {
        var currentY = y
        
        // Score percentage
        let scoreFont = UIFont.systemFont(ofSize: 48, weight: .bold)
        let scoreColor: UIColor = score >= 80 ? .systemGreen : (score >= 60 ? .systemOrange : .systemRed)
        let scoreAttributes: [NSAttributedString.Key: Any] = [
            .font: scoreFont,
            .foregroundColor: scoreColor
        ]
        
        let scoreText = "\(Int(score))%"
        let scoreSize = scoreText.size(withAttributes: scoreAttributes)
        let scoreRect = CGRect(x: margin, y: currentY, width: scoreSize.width, height: scoreSize.height)
        scoreText.draw(in: scoreRect, withAttributes: scoreAttributes)
        currentY += scoreSize.height + 10
        
        // Correct count
        let detailFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: detailFont,
            .foregroundColor: UIColor.darkGray
        ]
        
        let correctText = "\(correctCount) of \(totalQuestions) correct"
        correctText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: detailAttributes)
        currentY += 25
        
        // Time taken
        let minutes = Int(timeTaken) / 60
        let seconds = Int(timeTaken) % 60
        let timeText = "Time: \(String(format: "%d:%02d", minutes, seconds))"
        timeText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: detailAttributes)
        currentY += 25
        
        return currentY
    }
    
    private func drawQuestion(
        context: UIGraphicsPDFRendererContext,
        at y: CGFloat,
        margin: CGFloat,
        contentWidth: CGFloat,
        pageHeight: CGFloat,
        index: Int,
        question: Question,
        userAnswer: CorrectAnswer?,
        isCorrect: Bool
    ) -> CGFloat {
        var currentY = y
        
        // Question number and status
        let statusSymbol = isCorrect ? "✓" : "✗"
        let statusColor: UIColor = isCorrect ? .systemGreen : .systemRed
        
        let questionHeaderFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let questionHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: questionHeaderFont,
            .foregroundColor: UIColor.black
        ]
        
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: questionHeaderFont,
            .foregroundColor: statusColor
        ]
        
        let headerText = "Question \(index) "
        headerText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: questionHeaderAttributes)
        
        let headerSize = headerText.size(withAttributes: questionHeaderAttributes)
        statusSymbol.draw(at: CGPoint(x: margin + headerSize.width, y: currentY), withAttributes: statusAttributes)
        currentY += 22
        
        // Category badge
        let categoryFont = UIFont.systemFont(ofSize: 11, weight: .medium)
        let categoryText = "[\(question.category.shortName)]"
        let categoryAttributes: [NSAttributedString.Key: Any] = [
            .font: categoryFont,
            .foregroundColor: UIColor.gray
        ]
        categoryText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: categoryAttributes)
        currentY += 18
        
        // Question text
        let questionFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let questionAttributes: [NSAttributedString.Key: Any] = [
            .font: questionFont,
            .foregroundColor: UIColor.black
        ]
        
        let questionRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 1000)
        let boundingRect = question.cleanText.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: questionAttributes,
            context: nil
        )
        question.cleanText.draw(in: questionRect, withAttributes: questionAttributes)
        currentY += boundingRect.height + 12
        
        // Answer options
        let optionFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let letters = ["A", "B", "C", "D"]
        
        for (optionIndex, optionText) in question.options.enumerated() {
            guard optionIndex < letters.count else { continue }
            
            let letter = letters[optionIndex]
            let answer = CorrectAnswer.allCases[optionIndex]
            let isUserAnswer = userAnswer == answer
            let isCorrectAnswer = question.correctAnswer == answer
            
            // Determine styling
            var optionColor: UIColor = .black
            var prefix = ""
            
            if isCorrectAnswer {
                optionColor = .systemGreen
                prefix = "✓ "
            }
            if isUserAnswer && !isCorrect {
                optionColor = .systemRed
                prefix = "✗ "
            }
            if isUserAnswer && isCorrect {
                prefix = "✓ "
            }
            
            let optionAttributes: [NSAttributedString.Key: Any] = [
                .font: optionFont,
                .foregroundColor: optionColor
            ]
            
            let fullOptionText = "\(prefix)\(letter). \(optionText)"
            let optionRect = CGRect(x: margin + 15, y: currentY, width: contentWidth - 15, height: 1000)
            let optionBoundingRect = fullOptionText.boundingRect(
                with: CGSize(width: contentWidth - 15, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: optionAttributes,
                context: nil
            )
            fullOptionText.draw(in: optionRect, withAttributes: optionAttributes)
            currentY += optionBoundingRect.height + 4
        }
        
        // Explanation
        if !question.explanation.isEmpty {
            currentY += 8
            
            let explanationLabelFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
            let explanationLabelAttributes: [NSAttributedString.Key: Any] = [
                .font: explanationLabelFont,
                .foregroundColor: UIColor.systemOrange
            ]
            "Explanation:".draw(at: CGPoint(x: margin, y: currentY), withAttributes: explanationLabelAttributes)
            currentY += 14
            
            let explanationFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            let explanationAttributes: [NSAttributedString.Key: Any] = [
                .font: explanationFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            let explanationRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 1000)
            let explanationBoundingRect = question.explanation.boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: explanationAttributes,
                context: nil
            )
            question.explanation.draw(in: explanationRect, withAttributes: explanationAttributes)
            currentY += explanationBoundingRect.height
        }
        
        // Separator line
        currentY += 10
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin, y: currentY))
        linePath.addLine(to: CGPoint(x: margin + contentWidth, y: currentY))
        UIColor.lightGray.setStroke()
        linePath.lineWidth = 0.5
        linePath.stroke()
        currentY += 5
        
        return currentY
    }
    
    /// Saves PDF data to a temporary file and returns the URL
    func savePDFToTemp(data: Data, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
