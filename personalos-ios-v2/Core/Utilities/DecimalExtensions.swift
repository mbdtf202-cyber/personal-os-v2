import Foundation

extension Decimal {
    var isNaN: Bool {
        self.isNaN
    }
    
    var isInfinite: Bool {
        // Decimal 不会是无限大，但为了 API 一致性提供此方法
        false
    }
    
    var isFinite: Bool {
        !isNaN && !isInfinite
    }
    
    var isZero: Bool {
        self == 0
    }
}
