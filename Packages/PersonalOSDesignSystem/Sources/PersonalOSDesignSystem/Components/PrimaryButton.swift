import SwiftUI

/// ✅ MODULARIZATION: 主按钮组件（从主 App 移动到 DesignSystem Package）
public struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.bodyFont)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.mistBlue)
                .cornerRadius(AppTheme.cornerRadius)
        }
    }
}
