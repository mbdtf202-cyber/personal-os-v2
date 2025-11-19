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

// MARK: - Theme Styles
enum ThemeStyle: String, CaseIterable, Identifiable {
    case glass
    case vibrant
    case noir

    var id: String { rawValue }
    var title: String {
        switch self {
        case .glass: return "Glass"
        case .vibrant: return "Vibrant"
        case .noir: return "Noir"
        }
    }

    var subtitle: String {
        switch self {
        case .glass: return "iOS 17 风格玻璃质感"
        case .vibrant: return "多彩灵动的活力搭配"
        case .noir: return "低饱和夜间氛围"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .glass:
            return ThemePalette(
                background: Color(hex: "F5F7FA"),
                secondaryBackground: Color(hex: "FFFFFF"),
                primaryText: Color(hex: "2C3E50"),
                secondaryText: Color(hex: "95A5A6"),
                tertiaryText: Color(hex: "BDC3C7"),
                matcha: Color(hex: "A8D5BA"),
                mistBlue: Color(hex: "89C4F4"),
                almond: Color(hex: "FDE3A7"),
                lavender: Color(hex: "D7BDE2"),
                coral: Color(hex: "FAB1A0"),
                shadow: Color.black.opacity(0.05),
                border: Color.white.opacity(0.5)
            )
        case .vibrant:
            return ThemePalette(
                background: Color(hex: "F7F2FF"),
                secondaryBackground: Color(hex: "FFFFFF"),
                primaryText: Color(hex: "1F2D3D"),
                secondaryText: Color(hex: "6B7280"),
                tertiaryText: Color(hex: "9CA3AF"),
                matcha: Color(hex: "34D399"),
                mistBlue: Color(hex: "60A5FA"),
                almond: Color(hex: "FBBF24"),
                lavender: Color(hex: "A78BFA"),
                coral: Color(hex: "F472B6"),
                shadow: Color.black.opacity(0.08),
                border: Color.white.opacity(0.35)
            )
        case .noir:
            return ThemePalette(
                background: Color(hex: "0F172A"),
                secondaryBackground: Color(hex: "111827"),
                primaryText: Color(hex: "F8FAFC"),
                secondaryText: Color(hex: "CBD5E1"),
                tertiaryText: Color(hex: "94A3B8"),
                matcha: Color(hex: "22C55E"),
                mistBlue: Color(hex: "38BDF8"),
                almond: Color(hex: "F59E0B"),
                lavender: Color(hex: "C084FC"),
                coral: Color(hex: "FB7185"),
                shadow: Color.black.opacity(0.25),
                border: Color.white.opacity(0.08)
            )
        }
    }
}

struct ThemePalette {
    let background: Color
    let secondaryBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let matcha: Color
    let mistBlue: Color
    let almond: Color
    let lavender: Color
    let coral: Color
    let shadow: Color
    let border: Color
}

// MARK: - App Theme Palette
struct AppTheme {
    private static var palette: ThemePalette = ThemeStyle.glass.palette
    private static var style: ThemeStyle = .glass

    static var currentStyle: ThemeStyle { style }

    static func apply(style: ThemeStyle) {
        self.style = style
        self.palette = style.palette
    }

    // 背景色：极淡的灰蓝/米白
    static var background: Color { palette.background }
    static var secondaryBackground: Color { palette.secondaryBackground }

    // 文字颜色：避免纯黑，使用深灰增加柔和度
    static var primaryText: Color { palette.primaryText }
    static var secondaryText: Color { palette.secondaryText }
    static var tertiaryText: Color { palette.tertiaryText }

    // 功能色 (莫兰迪色系)
    static var matcha: Color { palette.matcha }
    static var mistBlue: Color { palette.mistBlue }
    static var almond: Color { palette.almond }
    static var lavender: Color { palette.lavender }
    static var coral: Color { palette.coral }

    // 阴影与边框
    static var shadow: Color { palette.shadow }
    static var border: Color { palette.border }

    // 兼容旧代码的别名
    static var primary: Color { mistBlue }
    static var secondary: Color { lavender }
    static var accent: Color { almond }
    static var surface: Color { secondaryBackground }
    static var textPrimary: Color { primaryText }
    static var textSecondary: Color { secondaryText }
    static var textTertiary: Color { tertiaryText }
    static var success: Color { matcha }
    static var warning: Color { almond }
    static var error: Color { coral }
    static var info: Color { mistBlue }
}

// MARK: - Morandi Colors (兼容旧代码)
struct MorandiColors {
    static var primary: Color { AppTheme.mistBlue }
    static var secondary: Color { AppTheme.lavender }
    static var accent: Color { AppTheme.almond }

    static var background: Color { AppTheme.background }
    static var surface: Color { AppTheme.secondaryBackground }
    static var surfaceSecondary: Color { Color(hex: "F9FAFB") }

    static var textPrimary: Color { AppTheme.primaryText }
    static var textSecondary: Color { AppTheme.secondaryText }
    static var textTertiary: Color { AppTheme.tertiaryText }

    static var success: Color { AppTheme.matcha }
    static var warning: Color { AppTheme.almond }
    static var error: Color { AppTheme.coral }
    static var info: Color { AppTheme.mistBlue }

    static var divider: Color { Color(hex: "E8EAED") }
    static var border: Color { AppTheme.border }
}
