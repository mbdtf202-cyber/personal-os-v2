import SwiftUI

struct Typography {
    // MARK: - Display
    static let displayLarge = Font.system(size: 32, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)
    
    // MARK: - Headline
    static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .default)
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .default)
    
    // MARK: - Title
    static let titleLarge = Font.system(size: 16, weight: .semibold, design: .default)
    static let titleMedium = Font.system(size: 14, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 12, weight: .semibold, design: .default)
    
    // MARK: - Body
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Label
    static let labelLarge = Font.system(size: 12, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 11, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
}
