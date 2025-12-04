//
//  AIService.swift
//  Glowly
//
//  AI service for connecting to Claude, OpenAI, and other LLM providers
//

import Foundation
import Combine

// MARK: - AI Service Protocol
protocol AIServiceProtocol {
    func sendMessage(
        messages: [AIMessage],
        systemPrompt: String?,
        stream: Bool
    ) async throws -> String

    func sendMessageStream(
        messages: [AIMessage],
        systemPrompt: String?,
        onChunk: @escaping (String) -> Void
    ) async throws
}

// MARK: - AI Message Model
struct AIMessage: Codable {
    let role: MessageRole
    let content: String

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
}

// MARK: - AI Service Error
enum AIServiceError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case decodingError
    case rateLimitExceeded
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError:
            return "Failed to decode API response"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .timeout:
            return "Request timed out. Please try again."
        }
    }
}

// MARK: - Main AI Service
@MainActor
class AIService: ObservableObject, AIServiceProtocol {
    static let shared = AIService()

    @Published var isLoading = false
    @Published var lastError: AIServiceError?

    private let session: URLSession
    private var currentTask: URLSessionDataTask?

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.timeoutInterval
        configuration.timeoutIntervalForResource = APIConfig.timeoutInterval * 2
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Main Send Message Method
    func sendMessage(
        messages: [AIMessage],
        systemPrompt: String? = nil,
        stream: Bool = false
    ) async throws -> String {
        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        // Validate API key
        let apiKey = APIConfig.getActiveAPIKey()
        guard !apiKey.isEmpty && !apiKey.contains("YOUR_") else {
            throw AIServiceError.invalidAPIKey
        }

        // Route to appropriate provider
        switch APIConfig.activeProvider {
        case .claude:
            return try await sendClaudeMessage(messages: messages, systemPrompt: systemPrompt)
        case .openAI:
            return try await sendOpenAIMessage(messages: messages, systemPrompt: systemPrompt)
        case .openRouter:
            return try await sendOpenRouterMessage(messages: messages, systemPrompt: systemPrompt)
        }
    }

    // MARK: - Streaming Method
    func sendMessageStream(
        messages: [AIMessage],
        systemPrompt: String? = nil,
        onChunk: @escaping (String) -> Void
    ) async throws {
        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        let apiKey = APIConfig.getActiveAPIKey()
        guard !apiKey.isEmpty && !apiKey.contains("YOUR_") else {
            throw AIServiceError.invalidAPIKey
        }

        switch APIConfig.activeProvider {
        case .claude:
            try await sendClaudeMessageStream(messages: messages, systemPrompt: systemPrompt, onChunk: onChunk)
        case .openAI:
            try await sendOpenAIMessageStream(messages: messages, systemPrompt: systemPrompt, onChunk: onChunk)
        case .openRouter:
            try await sendOpenRouterMessageStream(messages: messages, systemPrompt: systemPrompt, onChunk: onChunk)
        }
    }

    // MARK: - Claude API Implementation
    private func sendClaudeMessage(messages: [AIMessage], systemPrompt: String?) async throws -> String {
        let url = URL(string: "\(APIConfig.claudeBaseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(APIConfig.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body
        var requestBody: [String: Any] = [
            "model": APIConfig.claudeModel,
            "max_tokens": APIConfig.maxTokens,
            "temperature": APIConfig.temperature,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        ]

        if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
            requestBody["system"] = systemPrompt
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        // Handle errors
        if httpResponse.statusCode == 429 {
            throw AIServiceError.rateLimitExceeded
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw AIServiceError.apiError(errorResponse.error.message)
            }
            throw AIServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        return claudeResponse.content.first?.text ?? ""
    }

    // MARK: - Claude Streaming
    private func sendClaudeMessageStream(
        messages: [AIMessage],
        systemPrompt: String?,
        onChunk: @escaping (String) -> Void
    ) async throws {
        let url = URL(string: "\(APIConfig.claudeBaseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(APIConfig.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var requestBody: [String: Any] = [
            "model": APIConfig.claudeModel,
            "max_tokens": APIConfig.maxTokens,
            "temperature": APIConfig.temperature,
            "stream": true,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        ]

        if let systemPrompt = systemPrompt {
            requestBody["system"] = systemPrompt
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Stream handling
        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.invalidResponse
        }

        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" { break }

                if let data = jsonString.data(using: .utf8),
                   let event = try? JSONDecoder().decode(ClaudeStreamEvent.self, from: data),
                   event.type == "content_block_delta",
                   let text = event.delta?.text {
                    await MainActor.run {
                        onChunk(text)
                    }
                }
            }
        }
    }

    // MARK: - OpenAI API Implementation
    private func sendOpenAIMessage(messages: [AIMessage], systemPrompt: String?) async throws -> String {
        let url = URL(string: "\(APIConfig.openAIBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var apiMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        if let systemPrompt = systemPrompt {
            apiMessages.insert(["role": "system", "content": systemPrompt], at: 0)
        }

        let requestBody: [String: Any] = [
            "model": APIConfig.openAIModel,
            "messages": apiMessages,
            "max_tokens": APIConfig.maxTokens,
            "temperature": APIConfig.temperature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.invalidResponse
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return openAIResponse.choices.first?.message.content ?? ""
    }

    // MARK: - OpenAI Streaming
    private func sendOpenAIMessageStream(
        messages: [AIMessage],
        systemPrompt: String?,
        onChunk: @escaping (String) -> Void
    ) async throws {
        let url = URL(string: "\(APIConfig.openAIBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var apiMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        if let systemPrompt = systemPrompt {
            apiMessages.insert(["role": "system", "content": systemPrompt], at: 0)
        }

        let requestBody: [String: Any] = [
            "model": APIConfig.openAIModel,
            "messages": apiMessages,
            "max_tokens": APIConfig.maxTokens,
            "temperature": APIConfig.temperature,
            "stream": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.invalidResponse
        }

        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" { break }

                if let data = jsonString.data(using: .utf8),
                   let event = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: data),
                   let content = event.choices.first?.delta.content {
                    await MainActor.run {
                        onChunk(content)
                    }
                }
            }
        }
    }

    // MARK: - OpenRouter API Implementation
    private func sendOpenRouterMessage(messages: [AIMessage], systemPrompt: String?) async throws -> String {
        let url = URL(string: "\(APIConfig.openRouterBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(APIConfig.openRouterAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Glowly/1.0", forHTTPHeaderField: "HTTP-Referer")

        var apiMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        if let systemPrompt = systemPrompt {
            apiMessages.insert(["role": "system", "content": systemPrompt], at: 0)
        }

        let requestBody: [String: Any] = [
            "model": APIConfig.getActiveModel(),
            "messages": apiMessages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.invalidResponse
        }

        let openRouterResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return openRouterResponse.choices.first?.message.content ?? ""
    }

    // MARK: - OpenRouter Streaming
    private func sendOpenRouterMessageStream(
        messages: [AIMessage],
        systemPrompt: String?,
        onChunk: @escaping (String) -> Void
    ) async throws {
        // Similar to OpenAI streaming
        try await sendOpenAIMessageStream(messages: messages, systemPrompt: systemPrompt, onChunk: onChunk)
    }

    // MARK: - Cancel Request
    func cancelCurrentRequest() {
        currentTask?.cancel()
        isLoading = false
    }
}

// MARK: - Claude API Response Models
struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

struct ClaudeErrorResponse: Codable {
    let error: ClaudeError

    struct ClaudeError: Codable {
        let type: String
        let message: String
    }
}

struct ClaudeStreamEvent: Codable {
    let type: String
    let index: Int?
    let delta: ClaudeDelta?

    struct ClaudeDelta: Codable {
        let type: String?
        let text: String?
    }
}

// MARK: - OpenAI API Response Models
struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]

    struct OpenAIChoice: Codable {
        let index: Int
        let message: OpenAIMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }

    struct OpenAIMessage: Codable {
        let role: String
        let content: String
    }
}

struct OpenAIStreamResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIStreamChoice]

    struct OpenAIStreamChoice: Codable {
        let index: Int
        let delta: OpenAIDelta
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, delta
            case finishReason = "finish_reason"
        }
    }

    struct OpenAIDelta: Codable {
        let role: String?
        let content: String?
    }
}
