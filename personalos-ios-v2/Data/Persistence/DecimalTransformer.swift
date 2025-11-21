import Foundation

@objc(DecimalTransformer)
final class DecimalTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let decimal = value as? Decimal else { return nil }
        return NSKeyedArchiver.archivedData(withRootObject: NSDecimalNumber(decimal: decimal))
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data,
              let number = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSDecimalNumber.self, from: data) else {
            return nil
        }
        return number.decimalValue
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(
            DecimalTransformer(),
            forName: NSValueTransformerName("DecimalTransformer")
        )
    }
}
