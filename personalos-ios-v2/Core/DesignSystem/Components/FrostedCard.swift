import SwiftUI

struct FrostedCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = Color.white
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    FrostedCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("示例卡片")
                .font(Typography.headlineSmall)
                .foregroundColor(AppTheme.primaryText)
            Text("这是一个磨砂卡片组件")
                .font(Typography.bodySmall)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
    .padding()
    .background(AppTheme.background)
}
