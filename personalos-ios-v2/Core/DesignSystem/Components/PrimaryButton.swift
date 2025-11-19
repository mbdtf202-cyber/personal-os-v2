import SwiftUI

/// 主要按钮组件
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var style: ButtonStyle = .primary
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        case text
    }
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.light()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(Typography.titleMedium)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: style == .outline ? 1 : 0)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return MorandiColors.primary
        case .secondary:
            return MorandiColors.secondary
        case .outline, .text:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .secondary:
            return .white
        case .outline, .text:
            return MorandiColors.primary
        }
    }
    
    private var borderColor: Color {
        style == .outline ? MorandiColors.primary : Color.clear
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "主要按钮", action: {})
        PrimaryButton(title: "次要按钮", action: {}, style: .secondary)
        PrimaryButton(title: "轮廓按钮", action: {}, style: .outline)
        PrimaryButton(title: "文本按钮", action: {}, style: .text)
        PrimaryButton(title: "加载中", action: {}, isLoading: true)
        PrimaryButton(title: "禁用状态", action: {}, isDisabled: true)
    }
    .padding()
    .background(MorandiColors.background)
}
