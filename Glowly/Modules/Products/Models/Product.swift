//
//  Product.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

struct Product: Identifiable, Codable {
    let id = UUID()
    var name: String
    var brand: String
    var category: ProductCategory
    var purchaseDate: Date
    var expiryDate: Date?
    var barcode: String?
    var imageData: Data?
    var notes: String
    var isActive: Bool = true
    
    // Detailed Product Information
    var ingredients: String = ""
    var howToUse: String = ""
    var benefits: [String] = []
    var warnings: [String] = []
    
    // Personalization tags
    var isSensitiveSafe: Bool = false
    var isAcneSafe: Bool = true
    
    var daysUntilExpiry: Int? {
        guard let expiryDate = expiryDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: expiryDate).day
        return days
    }
    
    var isExpiringSoon: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days <= 30 && days > 0
    }
    
    var isExpired: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days <= 0
    }
}
