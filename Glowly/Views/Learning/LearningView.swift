//
//  LearningView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct LearningView: View {
    @ObservedObject var productStore: ProductStore
    @ObservedObject var userProfilePresenter: UserProfilePresenter
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            Picker("", selection: $selectedTab) {
                Text(languageManager.translate("learning_ai_chat")).tag(0)
                Text(languageManager.translate("learning_articles")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            if selectedTab == 0 {
                AIHelperView(productStore: productStore, userProfilePresenter: userProfilePresenter)
            } else {
                ArticlesView()
            }
        }
    }
}

// MARK: - Articles View
struct ArticlesView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var articles: [Article] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(articles) { article in
                    ArticleCard(article: article, languageManager: languageManager)
                }
            }
            .padding()
            .padding(.bottom, 80) // Safe area для Tab Bar
        }
        .onAppear {
            // Mock data - будет с backend
            articles = Article.mockArticles(languageManager: languageManager)
        }
        .onChange(of: languageManager.currentLanguage) { _, _ in
            // Mock data - будет с backend
            articles = Article.mockArticles(languageManager: languageManager)
        }
    }
}

// MARK: - Article Model
struct Article: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageUrl: String?
    let readTime: Int // minutes
    let category: String
    
    // Mock data - будет с backend
    static func mockArticles(languageManager: LanguageManager) -> [Article] {
        return [
            Article(
                title: languageManager.currentLanguage == .russian ? "10 советов по уходу за кожей" : 
                       languageManager.currentLanguage == .english ? "10 Skincare Tips" : 
                       "Тері күтімі бойынша 10 кеңес",
                description: languageManager.currentLanguage == .russian ? "Узнайте основные правила ежедневного ухода" :
                            languageManager.currentLanguage == .english ? "Learn the basic rules of daily care" :
                            "Күнделікті күтімнің негізгі ережелерін біліңіз",
                imageUrl: nil,
                readTime: 5,
                category: languageManager.translate("article_category_skincare")
            ),
            Article(
                title: languageManager.currentLanguage == .russian ? "Как правильно выбрать тональный крем" :
                       languageManager.currentLanguage == .english ? "How to Choose Foundation" :
                       "Тональды кремді қалай таңдау керек",
                description: languageManager.currentLanguage == .russian ? "Полное руководство по выбору foundation" :
                            languageManager.currentLanguage == .english ? "Complete guide to choosing foundation" :
                            "Foundation таңдау бойынша толық нұсқаулық",
                imageUrl: nil,
                readTime: 7,
                category: languageManager.translate("article_category_makeup")
            ),
            Article(
                title: languageManager.currentLanguage == .russian ? "SPF защита: что нужно знать" :
                       languageManager.currentLanguage == .english ? "SPF Protection: What You Need to Know" :
                       "SPF қорғанысы: не білу керек",
                description: languageManager.currentLanguage == .russian ? "Почему солнцезащитный крем важен каждый день" :
                            languageManager.currentLanguage == .english ? "Why sunscreen is important every day" :
                            "Неліктен күн қорғағыш крем күн сайын маңызды",
                imageUrl: nil,
                readTime: 4,
                category: languageManager.translate("article_category_protection")
            )
        ]
    }
}

// MARK: - Article Card
struct ArticleCard: View {
    let article: Article
    let languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.2), Theme.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 180)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.accent)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(article.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.accent)
                    .textCase(.uppercase)
                
                Text(article.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(article.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("\(article.readTime) \(languageManager.translate("article_read_time"))")
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    LearningView(productStore: ProductStore(), userProfilePresenter: UserProfilePresenter())
}

