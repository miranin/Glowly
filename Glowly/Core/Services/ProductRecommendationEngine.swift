//
//  ProductRecommendationEngine.swift
//  Glowly
//
//  AI-powered product recommendation engine based on user personalization
//

import Foundation

struct ProductRecommendation: Identifiable {
    let id = UUID()
    let productName: String
    let brand: String
    let category: String
    let reason: String
    let priority: Int
    let imageAsset: String?
}

@MainActor
final class ProductRecommendationEngine {
    static let shared = ProductRecommendationEngine()

    private init() {}

    /// Generate personalized product recommendations based on user profile
    func generateRecommendations(for userProfile: UserProfile) -> [ProductRecommendation] {
        var recommendations: [ProductRecommendation] = []

        // 1. Skincare Recommendations based on Skin Type
        recommendations.append(contentsOf: recommendForSkinType(userProfile.skinType))

        // 2. Treatment Products based on Skin Conditions
        recommendations.append(contentsOf: recommendForConditions(userProfile.skinConditions))

        // 3. Essential Products based on Beauty Goals
        recommendations.append(contentsOf: recommendForGoals(userProfile.beautyGoals))

        // 4. Routine Products based on Experience Level
        recommendations.append(contentsOf: recommendForExperience(
            userProfile.experienceLevel,
            routineComplexity: userProfile.skincareRoutineComplexity
        ))

        // 5. Safe Products considering Allergies
        recommendations = filterForAllergies(recommendations, allergies: userProfile.allergies, sensitivities: userProfile.sensitivities)

        // Sort by priority and return top recommendations
        return Array(recommendations.sorted { $0.priority > $1.priority }.prefix(6))
    }

    // MARK: - Skin Type Recommendations

    private func recommendForSkinType(_ skinType: SkinType) -> [ProductRecommendation] {
        switch skinType {
        case .dry:
            return [
                ProductRecommendation(
                    productName: "Hydrating Cream",
                    brand: "CeraVe",
                    category: "Moisturizer",
                    reason: "Rich hydration for dry skin",
                    priority: 10,
                    imageAsset: "beauty-1"
                ),
                ProductRecommendation(
                    productName: "Hyaluronic Acid Serum",
                    brand: "The Ordinary",
                    category: "Serum",
                    reason: "Deep moisture retention",
                    priority: 9,
                    imageAsset: "beauty-2"
                )
            ]

        case .oily:
            return [
                ProductRecommendation(
                    productName: "Oil-Free Gel Moisturizer",
                    brand: "Neutrogena",
                    category: "Moisturizer",
                    reason: "Lightweight hydration without oil",
                    priority: 10,
                    imageAsset: "beauty-1"
                ),
                ProductRecommendation(
                    productName: "Niacinamide Serum",
                    brand: "The Ordinary",
                    category: "Serum",
                    reason: "Controls oil production",
                    priority: 9,
                    imageAsset: "beauty-2"
                )
            ]

        case .combination:
            return [
                ProductRecommendation(
                    productName: "Balancing Moisturizer",
                    brand: "La Roche-Posay",
                    category: "Moisturizer",
                    reason: "Balances combination skin",
                    priority: 10,
                    imageAsset: "beauty-1"
                ),
                ProductRecommendation(
                    productName: "Gentle Cleanser",
                    brand: "CeraVe",
                    category: "Cleanser",
                    reason: "Gentle for all skin zones",
                    priority: 8,
                    imageAsset: "beauty-3"
                )
            ]

        case .sensitive:
            return [
                ProductRecommendation(
                    productName: "Sensitive Skin Cream",
                    brand: "La Roche-Posay Toleriane",
                    category: "Moisturizer",
                    reason: "Soothing for sensitive skin",
                    priority: 10,
                    imageAsset: "beauty-1"
                ),
                ProductRecommendation(
                    productName: "Gentle Micellar Water",
                    brand: "Bioderma",
                    category: "Cleanser",
                    reason: "No-rinse gentle cleansing",
                    priority: 9,
                    imageAsset: "beauty-2"
                )
            ]

        case .normal, .notSpecified:
            return [
                ProductRecommendation(
                    productName: "Daily Moisturizer",
                    brand: "CeraVe",
                    category: "Moisturizer",
                    reason: "Perfect for normal skin",
                    priority: 8,
                    imageAsset: "beauty-1"
                )
            ]
        }
    }

    // MARK: - Skin Condition Recommendations

    private func recommendForConditions(_ conditions: [SkinCondition]) -> [ProductRecommendation] {
        var recommendations: [ProductRecommendation] = []

        for condition in conditions {
            switch condition {
            case .acne:
                recommendations.append(ProductRecommendation(
                    productName: "Salicylic Acid Treatment",
                    brand: "Paula's Choice",
                    category: "Treatment",
                    reason: "Targets acne and breakouts",
                    priority: 10,
                    imageAsset: "beauty-2"
                ))

            case .fineLines:
                recommendations.append(ProductRecommendation(
                    productName: "Retinol Serum",
                    brand: "The Ordinary",
                    category: "Anti-Aging",
                    reason: "Reduces fine lines and wrinkles",
                    priority: 9,
                    imageAsset: "beauty-3"
                ))

            case .hyperpigmentation:
                recommendations.append(ProductRecommendation(
                    productName: "Vitamin C Serum",
                    brand: "SkinCeuticals",
                    category: "Brightening",
                    reason: "Brightens dark spots",
                    priority: 9,
                    imageAsset: "beauty-1"
                ))

            case .redness:
                recommendations.append(ProductRecommendation(
                    productName: "Centella Calming Cream",
                    brand: "Dr. Jart+",
                    category: "Soothing",
                    reason: "Reduces redness and inflammation",
                    priority: 8,
                    imageAsset: "beauty-2"
                ))

            case .dryPatches:
                recommendations.append(ProductRecommendation(
                    productName: "Ceramide Repair Cream",
                    brand: "CeraVe",
                    category: "Treatment",
                    reason: "Repairs dry patches",
                    priority: 8,
                    imageAsset: "beauty-3"
                ))

            case .largesPores:
                recommendations.append(ProductRecommendation(
                    productName: "Pore-Refining Toner",
                    brand: "Paula's Choice",
                    category: "Toner",
                    reason: "Minimizes pore appearance",
                    priority: 7,
                    imageAsset: "beauty-1"
                ))

            case .darkCircles:
                recommendations.append(ProductRecommendation(
                    productName: "Eye Cream with Caffeine",
                    brand: "The Ordinary",
                    category: "Eye Care",
                    reason: "Reduces dark circles",
                    priority: 7,
                    imageAsset: "beauty-2"
                ))

            case .rosacea, .eczema, .psoriasis:
                recommendations.append(ProductRecommendation(
                    productName: "Gentle Soothing Cream",
                    brand: "La Roche-Posay",
                    category: "Treatment",
                    reason: "Calms sensitive skin conditions",
                    priority: 9,
                    imageAsset: "beauty-3"
                ))

            case .noIssues:
                break
            }
        }

        return recommendations
    }

    // MARK: - Beauty Goals Recommendations

    private func recommendForGoals(_ goals: [BeautyGoal]) -> [ProductRecommendation] {
        var recommendations: [ProductRecommendation] = []

        for goal in goals {
            switch goal {
            case .acneTreatment:
                recommendations.append(ProductRecommendation(
                    productName: "Gentle Exfoliating Cleanser",
                    brand: "CeraVe",
                    category: "Cleanser",
                    reason: "Promotes clear, healthy skin",
                    priority: 8,
                    imageAsset: "beauty-1"
                ))

            case .antiAging:
                recommendations.append(ProductRecommendation(
                    productName: "Peptide Complex",
                    brand: "The Ordinary",
                    category: "Anti-Aging",
                    reason: "Supports skin firmness",
                    priority: 9,
                    imageAsset: "beauty-2"
                ))

            case .brighten:
                recommendations.append(ProductRecommendation(
                    productName: "Brightening Essence",
                    brand: "SK-II",
                    category: "Essence",
                    reason: "Illuminates complexion",
                    priority: 8,
                    imageAsset: "beauty-3"
                ))

            case .hydration:
                recommendations.append(ProductRecommendation(
                    productName: "Hydrating Mask",
                    brand: "Laneige",
                    category: "Mask",
                    reason: "Intensive hydration boost",
                    priority: 7,
                    imageAsset: "beauty-1"
                ))

            case .evenTone:
                recommendations.append(ProductRecommendation(
                    productName: "Alpha Arbutin Serum",
                    brand: "The Ordinary",
                    category: "Brightening",
                    reason: "Evens skin tone",
                    priority: 8,
                    imageAsset: "beauty-2"
                ))

            case .firmness:
                recommendations.append(ProductRecommendation(
                    productName: "Firming Neck Cream",
                    brand: "StriVectin",
                    category: "Anti-Aging",
                    reason: "Improves skin firmness",
                    priority: 7,
                    imageAsset: "beauty-3"
                ))

            case .glowySkin:
                recommendations.append(ProductRecommendation(
                    productName: "Glow Serum",
                    brand: "Glossier",
                    category: "Serum",
                    reason: "Natural radiant glow",
                    priority: 8,
                    imageAsset: "beauty-1"
                ))

            case .minimize:
                recommendations.append(ProductRecommendation(
                    productName: "Pore Minimizing Primer",
                    brand: "Benefit",
                    category: "Primer",
                    reason: "Refines pore appearance",
                    priority: 6,
                    imageAsset: "beauty-2"
                ))

            case .naturalLook, .dramaticLook:
                break
            }
        }

        return recommendations
    }

    // MARK: - Experience Level Recommendations

    private func recommendForExperience(_ level: ExperienceLevel, routineComplexity: RoutineComplexity) -> [ProductRecommendation] {
        switch level {
        case .beginner:
            return [
                ProductRecommendation(
                    productName: "Simple 3-Step Routine Set",
                    brand: "CeraVe",
                    category: "Kit",
                    reason: "Easy to start skincare journey",
                    priority: 9,
                    imageAsset: "beauty-1"
                ),
                ProductRecommendation(
                    productName: "Sunscreen SPF 50",
                    brand: "La Roche-Posay",
                    category: "Sun Protection",
                    reason: "Essential daily protection",
                    priority: 10,
                    imageAsset: "beauty-2"
                )
            ]

        case .intermediate:
            if routineComplexity == .extensive {
                return [
                    ProductRecommendation(
                        productName: "Multi-Acid Peel",
                        brand: "The Ordinary",
                        category: "Treatment",
                        reason: "Advanced weekly treatment",
                        priority: 7,
                        imageAsset: "beauty-3"
                    )
                ]
            } else {
                return [
                    ProductRecommendation(
                        productName: "Targeted Serum",
                        brand: "The Ordinary",
                        category: "Serum",
                        reason: "Customizable active treatment",
                        priority: 8,
                        imageAsset: "beauty-2"
                    )
                ]
            }

        case .advanced, .professional:
            return [
                ProductRecommendation(
                    productName: "Professional-Grade Vitamin C",
                    brand: "SkinCeuticals C E Ferulic",
                    category: "Serum",
                    reason: "High-performance formula",
                    priority: 9,
                    imageAsset: "beauty-1"
                )
            ]
        }
    }

    // MARK: - Allergy Filtering

    private func filterForAllergies(_ recommendations: [ProductRecommendation], allergies: [CommonAllergen], sensitivities: [CommonAllergen]) -> [ProductRecommendation] {
        // In production, this would filter out products containing allergens
        // For now, we'll add a note if user has allergies
        return recommendations
    }
}
