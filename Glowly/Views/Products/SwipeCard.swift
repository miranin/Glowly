//
//  SwipeCard.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct SwipeCard<Content: View>: View {
    let content: Content
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onTap: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    private let threshold: CGFloat = 120
    
    init(onSwipeLeft: @escaping () -> Void, onSwipeRight: @escaping () -> Void, onTap: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.onTap = onTap
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
            )
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                        rotation = Double(value.translation.width / 20)
                    }
                    .onEnded { value in
                        if value.translation.width > threshold {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                offset = CGSize(width: 1000, height: 0)
                                rotation = 12
                            }
                            HapticsService.shared.impactMedium()
                            onSwipeRight()
                        } else if value.translation.width < -threshold {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                offset = CGSize(width: -1000, height: 0)
                                rotation = -12
                            }
                            HapticsService.shared.warning()
                            onSwipeLeft()
                        } else {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                offset = .zero
                                rotation = 0
                            }
                        }
                    }
            )
            .onTapGesture {
                HapticsService.shared.impactLight()
                onTap()
            }
    }
}

#Preview {
    SwipeCard(onSwipeLeft: {}, onSwipeRight: {}, onTap: {}) {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: [.pink,.purple], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 240)
            Text("Demo Product").font(.headline)
            Text("Brand").font(.subheadline).foregroundColor(.secondary)
        }
        .padding()
        .frame(height: 360)
    }
    .padding()
}

