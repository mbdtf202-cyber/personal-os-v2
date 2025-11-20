import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 12
    var shadow: Bool = true
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 12,
        shadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.content = content()
    }
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .if(shadow && !themeManager.shouldUseReducedTransparency()) { view in
                view.shadow(color: shadowColor, radius: 8, x: 0, y: 2)
            }
    }
    
    private var cardBackground: some ShapeStyle {
        if themeManager.shouldUseReducedTransparency() {
            return AnyShapeStyle(colorScheme == .dark ? Color.black : Color.white)
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
