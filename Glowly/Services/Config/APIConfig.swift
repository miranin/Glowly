//
//  APIConfig.swift
//  Glowly
//
//  Created for AI integration
//

import Foundation

/// Configuration for AI API services
struct APIConfig {
    // MARK: - Claude API (Anthropic)
    /// Get your API key from: https://console.anthropic.com/
    static let claudeAPIKey = "YOUR_CLAUDE_API_KEY_HERE"
    static let claudeBaseURL = "https://api.anthropic.com/v1"
    static let claudeModel = "claude-3-5-sonnet-20241022" // Latest Claude 3.5 Sonnet

    // MARK: - OpenAI API (Alternative)
    /// Get your API key from: https://platform.openai.com/api-keys
    static let openAIAPIKey = "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"
    static let openAIBaseURL = "https://api.openai.com/v1"
    static let openAIModel = "gpt-4-turbo-preview"

    // MARK: - OpenRouter API (Multiple Models)
    /// Get your API key from: https://openrouter.ai/keys
    static let openRouterAPIKey = "YOUR_OPENROUTER_API_KEY_HERE"
    static let openRouterBaseURL = "https://openrouter.ai/api/v1"

    // MARK: - Active Provider
    enum AIProvider {
        case claude
        case openAI
        case openRouter
    }

    static let activeProvider: AIProvider = .claude

    // MARK: - API Settings
    static let maxTokens = 2000
    static let temperature = 0.7
    static let timeoutInterval: TimeInterval = 30

    // MARK: - Helper Methods
    static func getActiveAPIKey() -> String {
        switch activeProvider {
        case .claude:
            return claudeAPIKey
        case .openAI:
            return openAIAPIKey
        case .openRouter:
            return openRouterAPIKey
        }
    }

    static func getActiveBaseURL() -> String {
        switch activeProvider {
        case .claude:
            return claudeBaseURL
        case .openAI:
            return openAIBaseURL
        case .openRouter:
            return openRouterBaseURL
        }
    }

    static func getActiveModel() -> String {
        switch activeProvider {
        case .claude:
            return claudeModel
        case .openAI:
            return openAIModel
        case .openRouter:
            return "anthropic/claude-3.5-sonnet" // OpenRouter format
        }
    }
}

// MARK: - Security Note
/*
 ⚠️ IMPORTANT: For production apps, NEVER hardcode API keys in your source code!

 Better approaches:
 1. Use a backend server that proxies AI requests
 2. Store keys in Xcode build configuration
 3. Use environment variables
 4. Implement proper authentication with your backend

 For development, you can use this file but add it to .gitignore
 */
