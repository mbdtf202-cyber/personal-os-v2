import SwiftUI

/// ✅ MODULARIZATION: 设计系统主题（从主 App 移动到 DesignSystem Package）
public struct AppTheme {
    // MARK: - Colors
    public static let primaryText = Color("PrimaryText", bundle: .module)
    public static let secondaryText = Color("SecondaryText", bundle: .module)
    public static let mistBlue = Color("MistBlue", bundle: .module)
    public static let almond = Color("Almond", bundle: .module)
    public static let lavender = Color("Lavender", bundle: .module)
    
    // MARK: - Typography
    public static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    public static let headlineFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    public static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
    public static let captionFont = Font.system(size: 14, weight: .regular, design: .rounded)
    
    // MARK: - Spacing
    public static let spacing: CGFloat = 16
    public static let cornerRadius: CGFloat = 12
    
    private init() {}
}
