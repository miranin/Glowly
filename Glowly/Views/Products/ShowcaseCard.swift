//
//  ShowcaseCard.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct ShowcaseCard: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(8)
                .background(Circle().fill(color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).fontWeight(.semibold)
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.12)))
    }
}

#Preview {
    ShowcaseCard(title: "Скоро истекает", icon: "exclamationmark.triangle.fill", color: .orange, count: 3)
        .padding()
}

