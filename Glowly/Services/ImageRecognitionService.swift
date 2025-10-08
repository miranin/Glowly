//
//  ImageRecognitionService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import Foundation
import Vision
import UIKit

class ImageRecognitionService: ObservableObject {
    static let shared = ImageRecognitionService()
    
    private init() {}
    
    func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            DispatchQueue.main.async {
                completion(recognizedText)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Error recognizing text: \(error)")
            completion("")
        }
    }
    
    func analyzeProduct(from image: UIImage, recognizedText: String, completion: @escaping (ProductAnalysis) -> Void) {
        // Simulate AI analysis - in a real app, this would call an AI service
        let analysis = analyzeProductFromText(recognizedText)
        
        DispatchQueue.main.async {
            completion(analysis)
        }
    }
    
    private func analyzeProductFromText(_ text: String) -> ProductAnalysis {
        let lowercaseText = text.lowercased()
        
        // Extract brand
        let brands = ["l'oreal", "maybelline", "mac", "urban decay", "cerave", "neutrogena", "olay", "nivea", "garnier", "revlon", "covergirl", "elf", "nyx", "too faced", "fenty", "rare beauty", "glossier", "milk", "tarte", "benefit"]
        let detectedBrand = brands.first { lowercaseText.contains($0) } ?? ""
        
        // Extract product name (simplified - look for common product keywords)
        let productKeywords = ["foundation", "concealer", "powder", "blush", "bronzer", "highlighter", "eyeshadow", "eyeliner", "mascara", "lipstick", "lip gloss", "lip liner", "primer", "setting spray", "cleanser", "moisturizer", "serum", "sunscreen", "mask", "toner", "essence", "cream", "lotion", "gel", "oil", "scrub", "exfoliant"]
        
        let detectedProduct = productKeywords.first { lowercaseText.contains($0) } ?? ""
        
        // Determine category based on keywords
        let category = determineCategory(from: lowercaseText)
        
        // Extract shade/color information
        let shadePatterns = ["shade", "color", "tone", "оттенок", "цвет"]
        let shade = extractShade(from: lowercaseText, patterns: shadePatterns)
        
        return ProductAnalysis(
            brand: detectedBrand.capitalized,
            productName: detectedProduct.capitalized,
            category: category,
            shade: shade,
            confidence: 0.8,
            rawText: text
        )
    }
    
    private func determineCategory(from text: String) -> ProductCategory {
        let categoryKeywords: [ProductCategory: [String]] = [
            .foundation: ["foundation", "тонал", "bb cream", "cc cream", "tinted moisturizer"],
            .concealer: ["concealer", "консилер", "corrector"],
            .powder: ["powder", "пудра", "setting powder", "finishing powder"],
            .blush: ["blush", "румяна", "cheek color"],
            .bronzer: ["bronzer", "бронзер", "contour"],
            .highlighter: ["highlighter", "хайлайтер", "illuminator"],
            .eyeshadow: ["eyeshadow", "тени", "eye shadow", "palette"],
            .eyeliner: ["eyeliner", "подводка", "eye liner", "kohl"],
            .mascara: ["mascara", "тушь", "eye lash"],
            .lipstick: ["lipstick", "помада", "lip color", "lipstick"],
            .lipGloss: ["lip gloss", "блеск", "lip shine"],
            .lipLiner: ["lip liner", "контур", "lip pencil"],
            .primer: ["primer", "праймер", "base", "prep"],
            .settingSpray: ["setting spray", "фиксатор", "finishing spray"],
            .cleanser: ["cleanser", "очищение", "face wash", "gel cleanser"],
            .moisturizer: ["moisturizer", "увлажнение", "cream", "lotion"],
            .serum: ["serum", "сыворотка", "essence", "treatment"],
            .sunscreen: ["sunscreen", "spf", "солнцезащитный", "sun protection"],
            .mask: ["mask", "маска", "treatment mask", "clay mask"]
        ]
        
        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { text.contains($0) }) {
                return category
            }
        }
        
        return .other
    }
    
    private func extractShade(from text: String, patterns: [String]) -> String {
        for pattern in patterns {
            if let range = text.range(of: pattern) {
                let afterPattern = String(text[range.upperBound...])
                let words = afterPattern.components(separatedBy: .whitespacesAndNewlines)
                if let firstWord = words.first(where: { !$0.isEmpty }) {
                    return firstWord
                }
            }
        }
        return ""
    }
}

struct ProductAnalysis {
    let brand: String
    let productName: String
    let category: ProductCategory
    let shade: String
    let confidence: Double
    let rawText: String
}
