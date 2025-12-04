//
//  AIHelperView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI
import Combine

struct AIHelperView: View {
    @ObservedObject var productStore: ProductStore
    @ObservedObject var userProfilePresenter: UserProfilePresenter
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var aiService = AIService.shared
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var streamingText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Full-screen background
                LinearGradient(
                    colors: [Theme.backgroundPowder, Theme.accentLight.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if messages.isEmpty {
                                    welcomeView
                                }
                                
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if isTyping {
                                    TypingIndicator()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .padding(.bottom, 20) // Отступ от input area
                        }
                        // Stronger canvas background for chat area only
                        .background(
                            LinearGradient(
                                colors: [Theme.backgroundPowder, Theme.accentLight.opacity(0.18)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .onChange(of: messages.count) { _ in
                            if let lastMessage = messages.last {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input area
                    inputArea
                }
            }
            .navigationTitle(languageManager.translate("ai_title"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if messages.isEmpty {
                    addWelcomeMessage()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .profileUpdated)) { notification in
                // Handle profile update
                handleProfileUpdate()
            }
            .dismissKeyboardOnTap()
            .alert("AI Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.3), Theme.accentDark.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.accent, Theme.accentDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            VStack(spacing: 8) {
                Text(languageManager.translate("ai_welcome_title"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(languageManager.translate("ai_welcome_desc"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                QuickActionButton(
                    title: languageManager.translate("ai_morning_routine"),
                    icon: "sunrise.fill",
                    color: Color(hex: "#FF9A8B")
                ) {
                    sendMessage(languageManager.translate("ai_morning_routine"))
                }
                
                QuickActionButton(
                    title: languageManager.translate("ai_makeup_advice"),
                    icon: "paintbrush.pointed.fill",
                    color: Color(hex: "#FF6A88")
                ) {
                    sendMessage(languageManager.translate("ai_makeup_advice"))
                }
                
                QuickActionButton(
                    title: languageManager.translate("ai_product_analysis"),
                    icon: "magnifyingglass.circle.fill",
                    color: Color(hex: "#FFB4A2")
                ) {
                    sendMessage(languageManager.translate("ai_product_analysis"))
                }
            }
        }
        .padding(20)
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField(languageManager.translate("ai_placeholder"), text: $inputText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                    )
                
                Button(action: { sendMessage() }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    inputText.isEmpty ?
                                    LinearGradient(colors: [Color.gray, Color.gray], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Theme.accent, Theme.accentDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: inputText.isEmpty ? Color.clear : Theme.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                }
                .disabled(inputText.isEmpty || isTyping)
                .scaleEffect(inputText.isEmpty ? 1.0 : 1.05)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 50) // Safe area для Tab Bar
        }
        // Solid bar to clearly separate from chat canvas
        .background(Theme.backgroundCard)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: -2)
    }
    
    private func sendMessage(_ text: String? = nil) {
        let messageText = text ?? inputText
        guard !messageText.isEmpty else { return }

        // Dismiss keyboard
        isInputFocused = false

        // Add user message
        let userMessage = ChatMessage(
            content: messageText,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)

        if text == nil {
            inputText = ""
        }

        // Send to real AI service
        isTyping = true
        streamingText = ""

        Task {
            do {
                // Build system prompt with user context
                let systemPrompt = AISystemPrompts.getSystemPrompt(
                    userProfile: userProfilePresenter.userProfile,
                    products: productStore.products
                )

                // Convert chat history to AI messages
                let aiMessages = messages.map { message in
                    AIMessage(
                        role: message.isUser ? .user : .assistant,
                        content: message.content
                    )
                }

                // Use streaming for better UX
                try await aiService.sendMessageStream(
                    messages: aiMessages,
                    systemPrompt: systemPrompt
                ) { chunk in
                    streamingText += chunk
                }

                // Add complete AI response
                let aiMessage = ChatMessage(
                    content: streamingText,
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(aiMessage)
                streamingText = ""
                isTyping = false

                HapticsService.shared.success()

            } catch let error as AIServiceError {
                isTyping = false
                streamingText = ""
                errorMessage = error.localizedDescription
                showError = true

                // Fallback to mock response if API fails
                let fallbackResponse = generateMockResponse(for: messageText)
                let aiMessage = ChatMessage(
                    content: fallbackResponse,
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(aiMessage)

                HapticsService.shared.warning()
            } catch {
                isTyping = false
                streamingText = ""
                errorMessage = "Unexpected error: \(error.localizedDescription)"
                showError = true

                HapticsService.shared.warning()
            }
        }
    }
    
    private func addWelcomeMessage() {
        // Mock data - будет с backend
        let welcomeMessage = ChatMessage(
            content: languageManager.translate("ai_welcome_message"),
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    private func handleProfileUpdate() {
        // Mock data - будет с backend
        let updateMessage = ChatMessage(
            content: languageManager.translate("ai_profile_updated"),
            isUser: false,
            timestamp: Date()
        )
        withAnimation {
            messages.append(updateMessage)
        }
        HapticsService.shared.success()
    }
    
    // MARK: - Fallback Mock Response (used when API fails)
    private func generateMockResponse(for input: String) -> String {
        let lowercaseInput = input.lowercased()

        if lowercaseInput.contains("рутин") || lowercaseInput.contains("утренн") {
            return generateRoutineAdvice()
        } else if lowercaseInput.contains("макияж") || lowercaseInput.contains("макияж") {
            return generateMakeupAdvice()
        } else if lowercaseInput.contains("анализ") || lowercaseInput.contains("продукт") {
            return generateProductAnalysis()
        } else {
            return generateGeneralAdvice()
        }
    }
    
    private func generateRoutineAdvice() -> String {
        let activeProducts = productStore.products.filter { $0.isActive }
        let skincareProducts = activeProducts.filter { 
            [.cleanser, .moisturizer, .serum, .sunscreen, .mask, .primer].contains($0.category)
        }
        let userProfile = userProfilePresenter.userProfile
        
        if skincareProducts.isEmpty {
            return "Для создания рутины добавь продукты по уходу за кожей в свою косметичку. Рекомендую начать с очищения, увлажнения и защиты от солнца."
        }
        
        var advice = "На основе твоего профиля (тип кожи: \(userProfile.skinType.rawValue)) и продуктов, рекомендую:\n\n"
        advice += "🌅 Утром:\n"
        
        // Personalized routine based on skin type
        if userProfile.skinType == .dry {
            advice += "1. Мягкое очищение\n"
            advice += "2. Увлажняющая сыворотка\n"
            advice += "3. Насыщенный крем\n"
            advice += "4. Солнцезащита\n\n"
        } else if userProfile.skinType == .oily {
            advice += "1. Очищающий гель\n"
            advice += "2. Тоник\n"
            advice += "3. Легкая сыворотка\n"
            advice += "4. Матирующий крем\n"
            advice += "5. Солнцезащита\n\n"
        } else {
            advice += "1. Очищение\n"
            advice += "2. Сыворотка (если есть)\n"
            advice += "3. Увлажняющий крем\n"
            advice += "4. Солнцезащитный крем\n\n"
        }
        
        advice += "🌙 Вечером:\n"
        advice += "1. Очищение\n"
        advice += "2. Сыворотка\n"
        advice += "3. Увлажняющий крем\n"
        advice += "4. Маска (1-2 раза в неделю)\n\n"
        
        // Add personalized tips based on skin conditions
        if !userProfile.skinConditions.isEmpty {
            advice += "💡 С учетом ваших особенностей:\n"
            if userProfile.skinConditions.contains(.acne) {
                advice += "- Используйте некомедогенные продукты\n"
            }
            if userProfile.skinConditions.contains(.redness) {
                advice += "- Избегайте агрессивных средств\n"
            }
        }
        
        return advice
    }
    
    private func generateMakeupAdvice() -> String {
        let makeupProducts = productStore.products.filter { $0.isActive && 
            [.foundation, .concealer, .powder, .blush, .bronzer, .highlighter, 
             .eyeshadow, .eyeliner, .mascara, .lipstick, .lipGloss].contains($0.category)
        }
        
        if makeupProducts.isEmpty {
            return "Добавь продукты для макияжа в косметичку, чтобы получить персональные советы по нанесению!"
        }
        
        return "Отлично! У тебя есть \(makeupProducts.count) продуктов для макияжа. Рекомендую такой порядок нанесения:\n\n1. Праймер (если есть)\n2. Тональный крем\n3. Консилер\n4. Пудра\n5. Бронзер и румяна\n6. Хайлайтер\n7. Тени для век\n8. Подводка\n9. Тушь\n10. Помада или блеск"
    }
    
    private func generateProductAnalysis() -> String {
        let activeProducts = productStore.products.filter { $0.isActive }
        
        var analysis = "Анализ твоей косметички:\n\n"
        analysis += "📊 Всего продуктов: \(activeProducts.count)\n"
        
        let categories = Set(activeProducts.map { $0.category })
        analysis += "📂 Категории: \(categories.count)\n\n"
        
        if activeProducts.count < 5 {
            analysis += "💡 Совет: Добавь больше продуктов для полноценного ухода!"
        } else {
            analysis += "✨ Отличная коллекция! У тебя есть все необходимое для ухода."
        }
        
        return analysis
    }
    
    private func generateGeneralAdvice() -> String {
        let tips = [
            "💡 Не забывай очищать кисти для макияжа раз в неделю",
            "🌞 Всегда используй солнцезащитный крем, даже зимой",
            "💧 Пей больше воды для здоровой кожи",
            "😴 Спи 7-8 часов для красивого цвета лица",
            "🥗 Здоровое питание отражается на коже"
        ]
        
        return tips.randomElement() ?? "Чем еще могу помочь с уходом за собой?"
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                userBubble
            } else {
                aiBubble
                Spacer()
            }
        }
    }
    
    private var userBubble: some View {
        Text(message.content)
            .font(.body)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent, Theme.accentDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            )
    }
    
    private var aiBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.accent, Theme.accentDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("AI Помощник")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(message.content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray5).opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.08), color.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [color.opacity(0.3), color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
            )
            Spacer()
        }
        .onAppear {
            animationOffset = -4
        }
    }
}
