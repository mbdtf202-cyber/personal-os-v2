import SwiftUI
import Foundation

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - App Theme Palette
struct AppTheme {
    // 背景色：极淡的灰蓝/米白
    static let background = Color(hex: "F5F7FA")
    static let secondaryBackground = Color(hex: "FFFFFF")
    
    // 文字颜色：避免纯黑，使用深灰增加柔和度
    static let primaryText = Color(hex: "2C3E50")
    static let secondaryText = Color(hex: "95A5A6")
    static let tertiaryText = Color(hex: "BDC3C7")
    
    // 功能色 (莫兰迪色系)
    static let matcha = Color(hex: "A8D5BA")        // 抹茶绿 - 健康、完成
    static let mistBlue = Color(hex: "89C4F4")      // 雾霾蓝 - 工作、科技
    static let almond = Color(hex: "FDE3A7")        // 杏仁黄 - 财富、能量
    static let lavender = Color(hex: "D7BDE2")      // 薰衣草紫 - 灵感、社交
    static let coral = Color(hex: "FAB1A0")         // 珊瑚粉 - 心率、压力
    
    // 阴影与边框
    static let shadow = Color.black.opacity(0.05)
    static let border = Color.white.opacity(0.5)
}

// MARK: - Morandi Colors (兼容旧代码)
struct MorandiColors {
    static let primary = AppTheme.mistBlue
    static let secondary = AppTheme.lavender
    static let accent = AppTheme.almond
    
    static let background = AppTheme.background
    static let surface = AppTheme.secondaryBackground
    static let surfaceSecondary = Color(hex: "F9FAFB")
    
    static let textPrimary = AppTheme.primaryText
    static let textSecondary = AppTheme.secondaryText
    static let textTertiary = AppTheme.tertiaryText
    
    static let success = AppTheme.matcha
    static let warning = AppTheme.almond
    static let error = AppTheme.coral
    static let info = AppTheme.mistBlue
    
    static let divider = Color(hex: "E8EAED")
    static let border = AppTheme.border
}
