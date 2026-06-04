//
//  ProductAnalyzingView.swift
//  Glowly
//
//  Prominent, animated "AI is analyzing" state shown while the backend
//  vision pipeline identifies a product. Used by all photo-upload flows.
//

import SwiftUI

struct ProductAnalyzingView: View {
    let image: UIImage?

    @State private var stageIndex = 0
    @State private var pulse = false
    @State private var scanOffset: CGFloat = -1

    private let stages: [(icon: String, text: String)] = [
        ("photo.fill", "Загружаю фото…"),
        ("text.viewfinder", "Читаю этикетку…"),
        ("sparkle.magnifyingglass", "Определяю бренд и категорию…"),
        ("flask.fill", "Анализирую состав…"),
        ("checkmark.seal.fill", "Почти готово…")
    ]

    private let stageTimer = Timer.publish(every: 1.6, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            imageOrIcon

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Theme.accent)
                    Text(stages[stageIndex].text)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .contentTransition(.opacity)
                        .id(stageIndex)
                }

                Text("AI определяет продукт и собирает\nполную информацию о нём")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            stageDots

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(stageTimer) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                if stageIndex < stages.count - 1 { stageIndex += 1 }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                scanOffset = 1
            }
        }
    }

    // MARK: - Image with scan line, or pulsing sparkle

    @ViewBuilder
    private var imageOrIcon: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 210, height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(scanLine)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Theme.accent.opacity(0.35), lineWidth: 1.5)
                )
                .shadow(color: Theme.accent.opacity(0.18), radius: 16, x: 0, y: 6)
        } else {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 130, height: 130)
                    .scaleEffect(pulse ? 1.12 : 0.9)
                Circle()
                    .fill(Theme.accent.opacity(0.10))
                    .frame(width: 95, height: 95)
                Image(systemName: "sparkles")
                    .font(.system(size: 46, weight: .light))
                    .foregroundColor(Theme.accent)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }
        }
    }

    private var scanLine: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, Theme.accent.opacity(0.55), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 40)
            .offset(y: scanOffset * (geo.size.height + 40) / 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var stageDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<stages.count, id: \.self) { i in
                Capsule()
                    .fill(i <= stageIndex ? Theme.accent : Color(.systemGray4))
                    .frame(width: i == stageIndex ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.4), value: stageIndex)
            }
        }
    }
}

#Preview {
    ProductAnalyzingView(image: nil)
}
