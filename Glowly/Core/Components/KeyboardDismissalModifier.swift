//
//  KeyboardDismissalModifier.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import SwiftUI

/// Standard keyboard dismissal behavior for SwiftUI views
/// Dismisses keyboard when tapping outside of text fields
struct KeyboardDismissalModifier: ViewModifier {
    @FocusState private var isKeyboardVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isKeyboardVisible)
            .onTapGesture {
                // Dismiss keyboard when tapping anywhere
                isKeyboardVisible = false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                // Ensure keyboard state is reset when system hides keyboard
                isKeyboardVisible = false
            }
    }
}

/// Extension to easily apply keyboard dismissal to any view
extension View {
    /// Adds standard keyboard dismissal behavior
    /// Call this on the root view of any screen that has text fields
    func dismissKeyboardOnTap() -> some View {
        self.modifier(KeyboardDismissalModifier())
    }
}

/// Alternative approach using contentShape for better tap detection
struct KeyboardDismissalView<Content: View>: View {
    let content: Content
    @FocusState private var isKeyboardVisible: Bool
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .focused($isKeyboardVisible)
            .contentShape(Rectangle())
            .onTapGesture {
                isKeyboardVisible = false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
    }
}

/// Extension for the alternative approach
extension View {
    /// Wraps content in a keyboard-dismissing container
    func withKeyboardDismissal() -> some View {
        KeyboardDismissalView {
            self
        }
    }
}
