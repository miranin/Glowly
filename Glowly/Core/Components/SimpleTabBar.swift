//
//  SimpleTabBar.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

// MARK: - Tab Item
enum TabItem: Int, CaseIterable {
    case cosmetics = 0
    case feed = 1
    case add = 2
    case learning = 3
    case profile = 4
    
    var icon: String {
        switch self {
        case .cosmetics: return "house"
        case .feed: return "newspaper"
        case .add: return "plus.app"
        case .learning: return "book"
        case .profile: return "person.crop.circle"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .cosmetics: return "house.fill"
        case .feed: return "newspaper.fill"
        case .add: return "plus.app.fill"
        case .learning: return "book.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
    
    func title(languageManager: LanguageManager) -> String {
        switch self {
        case .cosmetics: return languageManager.translate("tab_cosmetics")
        case .feed: return languageManager.translate("tab_feed")
        case .add: return ""
        case .learning: return languageManager.translate("tab_learning")
        case .profile: return languageManager.translate("tab_profile")
        }
    }
}

// MARK: - Simple Tab Bar (Instagram Style)
struct SimpleTabBar: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var selectedTab: TabItem
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Regular Tab Bar
            HStack(spacing: 0) {
                ForEach(TabItem.allCases.filter { $0 != .add }, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 0) {
                            Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(selectedTab == tab ? .primary : .gray)
                                .frame(height: 24)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Space for center button
                    if tab == .feed {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 50)
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: -1)
            )
            
            // Floating Center Button
            Button {
                selectedTab = .add
            } label: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.9), Theme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .offset(y: -8)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        SimpleTabBar(selectedTab: .constant(.cosmetics))
    }
}

