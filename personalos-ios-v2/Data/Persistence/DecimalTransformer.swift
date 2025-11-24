import Foundation

// ✅ EXTREME FIX 2: Dual-storage for Decimal - String for precision + Int64 for queries
// String: 保持精度用于显示和计算
// Int64: 缩放后的整数用于 SQL 查询和排序（精确到 0.0001，即 10000 倍）

@objc(DecimalTransformer)
final class DecimalTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let decimal = value as? Decimal else { return nil }
        // 使用字符串存储，保持精度且性能更好
        return NSDecimalNumber(decimal: decimal).stringValue
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let string = value as? String else { return nil }
        return Decimal(string: string)
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(
            DecimalTransformer(),
            forName: NSValueTransformerName("DecimalTransformer")
        )
    }
}

// ✅ EXTREME FIX 2: Decimal 扩展支持查询优化
extension Decimal {
    var isInfinite: Bool {
        // Decimal 类型不支持无穷大，总是返回 false
        return false
    }
    
    /// Convert to scaled Int64 for SQL queries (4 decimal places precision)
    /// Example: 123.4567 -> 1234567
    var scaledInt64: Int64 {
        let scaled = self * 10000
        return NSDecimalNumber(decimal: scaled).int64Value
    }
    
    /// Create Decimal from scaled Int64
    static func fromScaledInt64(_ value: Int64) -> Decimal {
        return Decimal(value) / 10000
    }
}
