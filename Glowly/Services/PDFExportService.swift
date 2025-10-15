//
//  PDFExportService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI
import PDFKit
import UIKit

class PDFExportService: ObservableObject {
    
    func createCosmeticBagPDF(products: [Product], userProfile: UserProfile) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Glowly App",
            kCGPDFContextAuthor: userProfile.name.isEmpty ? "Glowly User" : userProfile.name,
            kCGPDFContextTitle: "Моя косметичка"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Header
            drawHeader(context: context, pageRect: pageRect, userProfile: userProfile)
            
            // Products by category
            drawProductsByCategory(context: context, pageRect: pageRect, products: products)
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Glowly_CosmeticBag.pdf")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Error writing PDF: \(error)")
            return nil
        }
    }
    
    private func drawHeader(context: UIGraphicsPDFRendererContext, pageRect: CGRect, userProfile: UserProfile) {
        let headerRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: 100)
        
        // Title
        let titleText = "Моя косметичка"
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.systemPurple
        ]
        
        titleText.draw(in: CGRect(x: headerRect.minX, y: headerRect.minY, width: headerRect.width, height: 30), withAttributes: titleAttributes)
        
        // User info
        let userText = "Пользователь: \(userProfile.name.isEmpty ? "Glowly User" : userProfile.name)"
        let userFont = UIFont.systemFont(ofSize: 16)
        let userAttributes: [NSAttributedString.Key: Any] = [
            .font: userFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        userText.draw(in: CGRect(x: headerRect.minX, y: headerRect.minY + 35, width: headerRect.width, height: 20), withAttributes: userAttributes)
        
        // Date
        let dateText = "Создано: \(Date().formatted(date: .abbreviated, time: .omitted))"
        dateText.draw(in: CGRect(x: headerRect.minX, y: headerRect.minY + 60, width: headerRect.width, height: 20), withAttributes: userAttributes)
    }
    
    private func drawProductsByCategory(context: UIGraphicsPDFRendererContext, pageRect: CGRect, products: [Product]) {
        let categories = Dictionary(grouping: products) { $0.category }
        var currentY: CGFloat = 150
        
        for (category, categoryProducts) in categories.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            // Check if we need a new page
            if currentY > pageRect.height - 200 {
                context.beginPage()
                currentY = 50
            }
            
            // Category header
            let categoryText = category.rawValue
            let categoryFont = UIFont.boldSystemFont(ofSize: 18)
            let categoryAttributes: [NSAttributedString.Key: Any] = [
                .font: categoryFont,
                .foregroundColor: UIColor.systemBlue
            ]
            
            categoryText.draw(in: CGRect(x: 50, y: currentY, width: pageRect.width - 100, height: 25), withAttributes: categoryAttributes)
            currentY += 30
            
            // Products in category
            for product in categoryProducts {
                if currentY > pageRect.height - 150 {
                    context.beginPage()
                    currentY = 50
                }
                
                drawProduct(context: context, pageRect: pageRect, product: product, yPosition: &currentY)
            }
            
            currentY += 20 // Space between categories
        }
    }
    
    private func drawProduct(context: UIGraphicsPDFRendererContext, pageRect: CGRect, product: Product, yPosition: inout CGFloat) {
        let productRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 80)
        
        // Product name
        let nameFont = UIFont.boldSystemFont(ofSize: 16)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: UIColor.label
        ]
        
        product.name.draw(in: CGRect(x: productRect.minX, y: productRect.minY, width: productRect.width - 100, height: 20), withAttributes: nameAttributes)
        
        // Brand
        let brandText = "Бренд: \(product.brand)"
        let brandFont = UIFont.systemFont(ofSize: 14)
        let brandAttributes: [NSAttributedString.Key: Any] = [
            .font: brandFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        brandText.draw(in: CGRect(x: productRect.minX, y: productRect.minY + 20, width: productRect.width - 100, height: 20), withAttributes: brandAttributes)
        
        // Purchase date
        let purchaseText = "Куплено: \(product.purchaseDate.formatted(date: .abbreviated, time: .omitted))"
        purchaseText.draw(in: CGRect(x: productRect.minX, y: productRect.minY + 40, width: productRect.width - 100, height: 20), withAttributes: brandAttributes)
        
        
        // Product image (if available)
        if let imageData = product.imageData, let image = UIImage(data: imageData) {
            let imageSize = CGSize(width: 60, height: 60)
            let imageRect = CGRect(x: productRect.maxX - 70, y: productRect.minY, width: imageSize.width, height: imageSize.height)
            image.draw(in: imageRect)
        }
        
        yPosition += 90
    }
}
