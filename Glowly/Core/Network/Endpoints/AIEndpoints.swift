//
//  AIEndpoints.swift
//  Glowly
//
//  Routes AI requests through the Glowly backend (keeps API keys server-side).
//  Replaces direct Claude/OpenAI calls in AIService.swift.
//
//  NOTE: Uses the existing AIMessage type declared in AIService.swift.
//

import Foundation

// MARK: - AI Endpoints

enum AIEndpoints: APIEndpoint {
    /// POST /api/products/analyze-image — authenticated multipart upload → full pipeline
    case analyzeImage

    /// POST /api/products/analyze — public multipart upload → analysis only (no auth, no DB save)
    case analyzePublic

    /// POST /api/ai/chat — proxied Claude chat
    case chat(BackendChatRequest)

    /// GET /api/ai/recommendations — RAG-powered product recommendations
    case recommendations

    var path: String {
        switch self {
        case .analyzeImage:
            return "/api/products/analyze-image"
        case .analyzePublic:
            return "/api/products/analyze"
        case .chat:
            return "/api/ai/chat"
        case .recommendations:
            return "/api/ai/recommendations"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .analyzeImage, .analyzePublic, .chat:
            return .post
        case .recommendations:
            return .get
        }
    }

    var body: Encodable? {
        switch self {
        case .analyzeImage, .analyzePublic:
            return nil // multipart handled by NetworkService.upload()
        case .chat(let request):
            return request
        case .recommendations:
            return nil
        }
    }

    var timeoutInterval: TimeInterval {
        switch self {
        // Claude vision analysis takes ~15-20s; allow generous headroom for
        // upload latency + processing so the client never quits before the server.
        case .analyzeImage, .analyzePublic: return 75
        default: return 30
        }
    }
}

// MARK: - MCP Endpoints

enum MCPEndpoints: APIEndpoint {
    case listTools
    case executeTool(MCPToolRequest)

    var path: String {
        switch self {
        case .listTools:    return "/api/mcp/tools"
        case .executeTool:  return "/api/mcp/execute"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .listTools:    return .get
        case .executeTool:  return .post
        }
    }

    var body: Encodable? {
        switch self {
        case .listTools:            return nil
        case .executeTool(let req): return req
        }
    }
}

// MARK: - Request Models
// (AIMessage is already declared in AIService.swift — do not redeclare here)

/// Wrapper sent to POST /api/ai/chat.
/// Uses the existing AIMessage type from AIService.swift.
struct BackendChatRequest: Encodable {
    /// Flattened to [String: String] for the backend's camelCase schema
    struct BackendMessage: Encodable {
        let role: String
        let content: String
    }

    let messages: [BackendMessage]

    /// Convert from the app's AIMessage (which uses MessageRole enum) to
    /// the plain-string format the backend expects.
    init(from aiMessages: [AIMessage]) {
        self.messages = aiMessages.map {
            BackendMessage(role: $0.role.rawValue, content: $0.content)
        }
    }
}

struct MCPToolRequest: Encodable {
    let tool: String
    let input: [String: String]
}

// MARK: - Response Models

struct AnalyzeProductResponse: Decodable {
    let analyzedProduct: AnalyzedProductResult
    let savedProduct: BackendProduct?
    let recommendations: [BackendRecommendation]
    let workflowSteps: [String]
}

struct AnalyzedProductResult: Decodable {
    let brand: String
    let productName: String
    let category: String
    let applicationZone: String

    // Rich fields from improved vision pipeline
    let productDescription: String
    let keyIngredients: [String]
    let ingredients: [String]
    let ingredientsRaw: String
    let skinTypes: [String]
    let detectedConcerns: [String]
    let usageTime: String

    let howToUse: String
    let benefits: [String]
    let warnings: [String]

    let isSensitiveSafe: Bool
    let isAcneSafe: Bool
    let confidence: Double
    let needsConfirmation: Bool
    let reasoning: String
    let dataSource: String
    let sourceUrl: String
    let ocrText: String
    let aiRawDescription: String

    // Convenience: map backend category string → iOS ProductCategory
    var mappedCategory: ProductCategory {
        switch category.lowercased() {
        // Skincare
        case "cleanser":       return .cleanser
        case "toner":          return .toner
        case "essence":        return .essence
        case "serum":          return .serum
        case "moisturizer":    return .moisturizer
        case "eye_cream":      return .eyeCream
        case "oil":            return .faceOil
        case "exfoliant":      return .exfoliant
        case "spot_treatment": return .spotTreatment
        case "mist":           return .mist
        case "sunscreen":      return .sunscreen
        case "mask":           return .mask
        case "lip_care":       return .lipCare
        // Makeup
        case "foundation":     return .foundation
        case "concealer":      return .concealer
        case "powder":         return .powder
        case "blush":          return .blush
        case "bronzer":        return .bronzer
        case "highlighter":    return .highlighter
        case "eyeshadow":      return .eyeshadow
        case "eyeliner":       return .eyeliner
        case "mascara":        return .mascara
        case "lipstick":       return .lipstick
        case "lip_gloss":      return .lipGloss
        case "lip_liner":      return .lipLiner
        case "primer":         return .primer
        case "setting_spray":  return .settingSpray
        default:               return .other
        }
    }
}

struct BackendProduct: Decodable {
    let id: String
    let name: String
    let brand: String
    let category: String
    let applicationZone: String?
    let ingredients: String
    let ingredientsList: [String]
    let aiConfidence: Double
    let needsConfirmation: Bool
}

struct BackendRecommendation: Decodable {
    let productName: String
    let brand: String
    let category: String
    let reason: String
    let priority: Int
    let ingredientSynergy: [String]
}

struct BackendChatResponse: Decodable {
    let content: String
    let model: String
}

struct BackendRecommendationsResponse: Decodable {
    let recommendations: [BackendRecommendation]
    let profileSummary: String
    let missingRoutineSteps: [String]
}
