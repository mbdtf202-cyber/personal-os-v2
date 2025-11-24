import Foundation

extension Decimal {
    var isNaN: Bool {
        // Decimal type doesn't have NaN values like floating point types
        // Check if the value is valid by comparing with itself
        return self != self
    }
    
    // Note: Decimal already has isInfinite in Foundation, so we don't redefine it
    
    var isFinite: Bool {
        // Decimal values are always finite (no infinity)
        !isNaN && !isInfinite
    }
    
    var isZero: Bool {
        self == 0
    }
}
