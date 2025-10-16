//
//  BottomSheetNotice.swift
//  Glowly
//
//  Notice/Info bottom sheet with dimmed background (matches design)
//  Used for displaying informational messages, tips, confirmations
//

import SwiftUI

struct BottomSheetNotice: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        message: String,
        buttonTitle: String = "понятно",
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                // Title
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 32)

                // Message
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(4)

                // Button
                Button {
                    HapticsService.shared.impactMedium()
                    action()
                    dismiss()
                } label: {
                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.49, green: 0.83, blue: 0.99)) // Light blue #7DD3FC
                        )
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            // Home Indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black)
                .frame(width: 140, height: 5)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24
            )
            .fill(Color(.systemBackground))
        )
    }
}

// MARK: - View Modifier for Easy Use

struct BottomSheetNoticeModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                // Dimmed Background
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)

                // Bottom Sheet
                VStack {
                    Spacer()

                    BottomSheetNotice(
                        title: title,
                        message: message,
                        buttonTitle: buttonTitle,
                        action: {
                            action()
                            isPresented = false
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
    }
}

// MARK: - View Extension

extension View {
    func bottomSheetNotice(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        buttonTitle: String = "понятно",
        action: @escaping () -> Void = {}
    ) -> some View {
        modifier(
            BottomSheetNoticeModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                buttonTitle: buttonTitle,
                action: action
            )
        )
    }
}

// MARK: - Convenience Methods

extension View {
    /// Show success notice
    func successNotice(
        isPresented: Binding<Bool>,
        title: String = "успешно!",
        message: String,
        buttonTitle: String = "отлично",
        action: @escaping () -> Void = {}
    ) -> some View {
        bottomSheetNotice(
            isPresented: isPresented,
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            action: action
        )
    }

    /// Show info notice
    func infoNotice(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        buttonTitle: String = "понятно",
        action: @escaping () -> Void = {}
    ) -> some View {
        bottomSheetNotice(
            isPresented: isPresented,
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            action: action
        )
    }

    /// Show warning notice
    func warningNotice(
        isPresented: Binding<Bool>,
        title: String = "внимание",
        message: String,
        buttonTitle: String = "понятно",
        action: @escaping () -> Void = {}
    ) -> some View {
        bottomSheetNotice(
            isPresented: isPresented,
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            action: action
        )
    }

    /// Show tip notice
    func tipNotice(
        isPresented: Binding<Bool>,
        title: String = "совет",
        message: String,
        buttonTitle: String = "понятно",
        action: @escaping () -> Void = {}
    ) -> some View {
        bottomSheetNotice(
            isPresented: isPresented,
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            action: action
        )
    }
}

// MARK: - Previews

#Preview("Success Notice") {
    VStack {
        Text("Main Content")
            .font(.largeTitle)
    }
    .successNotice(
        isPresented: .constant(true),
        message: "Продукт успешно добавлен в вашу косметичку"
    )
}

#Preview("Info Notice") {
    VStack {
        Text("Main Content")
            .font(.largeTitle)
    }
    .infoNotice(
        isPresented: .constant(true),
        title: "обновление доступно",
        message: "Доступна новая версия приложения с улучшениями и исправлениями"
    )
}

#Preview("Warning Notice") {
    VStack {
        Text("Main Content")
            .font(.largeTitle)
    }
    .warningNotice(
        isPresented: .constant(true),
        message: "Срок годности этого продукта истекает через 7 дней"
    )
}

#Preview("Tip Notice") {
    VStack {
        Text("Main Content")
            .font(.largeTitle)
    }
    .tipNotice(
        isPresented: .constant(true),
        message: "Используйте Face ID для быстрого входа в приложение. Активируйте в настройках профиля."
    )
}
