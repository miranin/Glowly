//
//  LanguageSwitcher.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct LanguageSwitcher: View {
    @ObservedObject var languageManager: LanguageManager
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppLanguage.allCases) { language in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        HapticsService.shared.impactLight()
                        languageManager.changeLanguage(language)
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(language.flag)
                            .font(.system(size: 32))
                        
                        Text(language.displayName)
                            .font(.system(size: 13, weight: languageManager.currentLanguage == language ? .semibold : .regular))
                            .foregroundColor(languageManager.currentLanguage == language ? Theme.accent : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(languageManager.currentLanguage == language ? 
                                  Theme.accent.opacity(0.1) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(languageManager.currentLanguage == language ? 
                                           Theme.accent : Color.clear, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

