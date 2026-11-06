import SwiftUI

struct MapPageScaffold<Content: View>: View {
    private let content: Content

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var pageState = MapPageState.shared
    @State private var hasEntered = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .offset(
                y: reduceMotion || hasEntered ? 0 : 18
            )
            .opacity(
                reduceMotion || hasEntered ? 1 : 0
            )
            .scaleEffect(
                reduceMotion || hasEntered ? 1.0 : 0.985
            )
            .animation(
                reduceMotion
                    ? nil
                    : .spring(response: 0.38, dampingFraction: 0.82),
                value: hasEntered
            )
            .background {
                GeometryReader { geometry in
                    MapBitmapBackdrop(
                        region: pageState.region,
                        size: geometry.size,
                        attributionHeight: 0
                    )
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .allowsHitTesting(false)
                }
                .ignoresSafeArea(.container)
            }
            .onAppear {
                hasEntered = true
            }
            .onDisappear {
                hasEntered = false
            }
    }
}

// MARK: - Reusable Modifiers

struct MapGlassControlGroup<Content: View>: View {
    private let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { content }
}

private struct MapControlGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let cornerRadius: CGFloat
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else if #available(iOS 26.0, *) {
            content.glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            content.background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct MapContentPanel: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let cornerRadius: CGFloat
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.primary)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground)
                        .opacity(reduceTransparency ? 1 : (colorScheme == .dark ? 0.88 : 0.92)))
                    .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func mapControlGlass(cornerRadius: CGFloat = 20) -> some View {
        modifier(MapControlGlass(cornerRadius: cornerRadius))
    }
    func mapContentPanel(cornerRadius: CGFloat = 24) -> some View {
        modifier(MapContentPanel(cornerRadius: cornerRadius))
    }
}
