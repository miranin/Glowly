//
//  AISystemPrompts.swift
//  Glowly
//
//  System prompts for AI beauty assistant
//

import Foundation

struct AISystemPrompts {
    // MARK: - Main System Prompt
    static func getSystemPrompt(userProfile: UserProfile, products: [Product]) -> String {
        return """
        You are an AI beauty and skincare expert assistant for Glowly, a personalized cosmetics management app.

        ## Your Role
        - Provide personalized beauty advice based on the user's profile and products
        - Be friendly, supportive, and encouraging
        - Give practical, actionable recommendations
        - Explain skincare and makeup concepts in simple terms
        - Be culturally aware (user may speak Russian, English, or Kazakh)

        ## User Profile
        \(formatUserProfile(userProfile))

        ## User's Cosmetic Bag
        \(formatProducts(products))

        ## Guidelines
        1. **Personalization**: Always consider the user's skin type, concerns, and goals
        2. **Product-Aware**: Reference products from their cosmetic bag when relevant
        3. **Safety First**: Warn about potential allergens or harmful combinations
        4. **Expiration Tracking**: Remind users about expiring products
        5. **Routine Building**: Help create morning and evening routines
        6. **Ingredient Education**: Explain active ingredients and their benefits
        7. **Application Techniques**: Provide step-by-step application instructions

        ## Conversation Style
        - Use emojis sparingly for visual appeal (✨, 💡, 🌟, 💧, 🌅, 🌙)
        - Keep responses concise but informative
        - Ask clarifying questions when needed
        - Be encouraging and positive
        - Use bullet points and numbering for clarity

        ## Limitations
        - You cannot diagnose medical conditions
        - Recommend consulting a dermatologist for serious skin issues
        - Don't make claims about "miracle" results
        - Be honest about realistic timeframes for results

        ## Language
        Respond in the same language as the user's question. The user primarily uses Russian, but may switch to English or Kazakh.
        """
    }

    // MARK: - Context Formatters
    private static func formatUserProfile(_ profile: UserProfile) -> String {
        var text = "- Name: \(profile.name.isEmpty ? "User" : profile.name)\n"
        text += "- Skin Type: \(profile.skinType.rawValue)\n"

        if !profile.skinConditions.isEmpty {
            text += "- Skin Concerns: \(profile.skinConditions.map { $0.rawValue }.joined(separator: ", "))\n"
        }

        if !profile.beautyGoals.isEmpty {
            text += "- Beauty Goals: \(profile.beautyGoals.map { $0.rawValue }.joined(separator: ", "))\n"
        }

        if !profile.allergies.isEmpty {
            text += "- Allergies/Sensitivities: \(profile.allergies.map { $0.rawValue }.joined(separator: ", "))\n"
        }

        text += "- Experience Level: \(profile.experienceLevel.rawValue)\n"
        text += "- Makeup Frequency: \(profile.makeupFrequency.rawValue)\n"
        text += "- Routine Complexity: \(profile.skincareRoutineComplexity.rawValue)\n"

        return text
    }

    private static func formatProducts(_ products: [Product]) -> String {
        let activeProducts = products.filter { $0.isActive }

        if activeProducts.isEmpty {
            return "The user hasn't added any products yet."
        }

        var text = "Total active products: \(activeProducts.count)\n\n"

        // Group by category
        let categories = Dictionary(grouping: activeProducts) { $0.category }

        for (category, items) in categories.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            text += "**\(category.rawValue.capitalized)**:\n"
            for product in items {
                text += "  - \(product.name) by \(product.brand)"
                text += "\n"
            }
            text += "\n"
        }

        return text
    }

    // MARK: - Quick Action Prompts
    static let morningRoutinePrompt = """
    Create a personalized morning skincare routine for me based on my skin type and the products I have. Include step numbers and explain why each step is important.
    """

    static let eveningRoutinePrompt = """
    Create a personalized evening skincare routine for me. Include makeup removal, cleansing, and night care steps.
    """

    static let makeupAdvicePrompt = """
    Give me makeup application advice based on the makeup products I have in my cosmetic bag. Include the proper order of application.
    """

    static let productAnalysisPrompt = """
    Analyze the products in my cosmetic bag. Tell me if I'm missing any essential items and if any products might be expiring soon.
    """

    static let ingredientEducationPrompt = """
    Explain the key ingredients in my skincare products and their benefits for my skin type.
    """

    static let troubleshootingPrompt = """
    I'm experiencing some skin issues. Based on my profile and products, what could be causing them and how can I address them?
    """
}
