import Foundation

// ✅ P2 Fix: 优化 Decimal 存储，避免 NSKeyedArchiver 性能开销
// 使用 String 存储以保持精度，避免序列化开销
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
