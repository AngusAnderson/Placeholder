import SwiftUI

private struct TabContentEntrance: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 1 : opacity)
            .onAppear {
                if reduceMotion { opacity = 1 }
                else { withAnimation(.easeInOut(duration: 0.55)) { opacity = 1 } }
            }
            .onDisappear { opacity = 0 }
    }
}

extension View {
    func tabContentEntrance() -> some View { modifier(TabContentEntrance()) }
}
