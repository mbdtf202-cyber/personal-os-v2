import Foundation

extension Decimal {
    var isNaN: Bool {
        // Decimal type doesn't have NaN values like floating point types
        // Check if the value is valid by comparing with itself
        return self != self
    }
    
    var isInfinite: Bool {
        // Decimal 不会是无限大，但为了 API 一致性提供此方法
        false
    }
    
    var isFinite: Bool {
        // Decimal values are always finite (no infinity)
        !isNaN
    }
    
    var isZero: Bool {
        self == 0
    }
}
