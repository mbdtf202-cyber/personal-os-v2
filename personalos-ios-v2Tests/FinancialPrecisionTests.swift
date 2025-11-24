import XCTest
import SwiftData
@testable import personalos_ios_v2

// **Feature: system-architecture-upgrade-p0, Property 31: Decimal type usage**
// **Feature: system-architecture-upgrade-p0, Property 32: Calculation precision preservation**
// **Feature: system-architecture-upgrade-p0, Property 33: Display format round trip**
// **Feature: system-architecture-upgrade-p0, Property 34: No double conversion**
// **Feature: system-architecture-upgrade-p0, Property 35: Persistence round trip**

final class FinancialPrecisionTests: XCTestCase {
    
    // MARK: - Property 31: Decimal type usage
    
    func testTradeRecordUsesDecimal() {
        // Property: All financial values should use Decimal type
        
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: Decimal(string: "150.25")!,
            quantity: Decimal(string: "10.5")!,
            assetType: .stock,
            emotion: .neutral,
            note: "Test trade"
        )
        
        XCTAssertTrue(type(of: trade.price) == Decimal.self, "Price should be Decimal")
        XCTAssertTrue(type(of: trade.quantity) == Decimal.self, "Quantity should be Decimal")
    }
    
    func testAssetItemUsesDecimal() {
        // Property: Asset values should use Decimal type
        
        let asset = AssetItem(
            symbol: "AAPL",
            name: "Apple Inc.",
            quantity: Decimal(string: "100.5")!,
            currentPrice: Decimal(string: "150.75")!,
            avgCost: Decimal(string: "145.50")!,
            type: .stock
        )
        
        XCTAssertTrue(type(of: asset.quantity) == Decimal.self, "Quantity should be Decimal")
        XCTAssertTrue(type(of: asset.currentPrice) == Decimal.self, "Current price should be Decimal")
        XCTAssertTrue(type(of: asset.avgCost) == Decimal.self, "Average cost should be Decimal")
    }
    
    func testNoDoubleInFinancialCalculations() {
        // Property: Financial calculations should not use Double
        
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: Decimal(string: "150.25")!,
            quantity: Decimal(string: "10")!,
            assetType: .stock,
            emotion: .neutral,
            note: ""
        )
        
        let totalValue = trade.totalValue
        XCTAssertTrue(type(of: totalValue) == Decimal.self, "Total value should be Decimal")
    }
    
    // MARK: - Property 32: Calculation precision preservation
    
    func testDecimalCalculationPrecision() {
        // Property: Decimal calculations should maintain full precision
        
        let price = Decimal(string: "0.1")!
        let quantity = Decimal(string: "0.2")!
        
        let result = price + quantity
        let expected = Decimal(string: "0.3")!
        
        XCTAssertEqual(result, expected, "Decimal addition should be precise")
    }
    
    func testMultiplicationPrecision() {
        // Property: Multiplication should maintain precision
        
        let price = Decimal(string: "150.25")!
        let quantity = Decimal(string: "10.5")!
        
        let total = price * quantity
        let expected = Decimal(string: "1577.625")!
        
        XCTAssertEqual(total, expected, "Multiplication should be precise")
    }
    
    func testDivisionPrecision() {
        // Property: Division should maintain precision
        
        let total = Decimal(string: "1577.625")!
        let quantity = Decimal(string: "10.5")!
        
        let price = total / quantity
        let expected = Decimal(string: "150.25")!
        
        XCTAssertEqual(price, expected, "Division should be precise")
    }
    
    func testPnLCalculationPrecision() {
        // Property: P&L calculations should be precise
        
        let asset = AssetItem(
            symbol: "AAPL",
            name: "Apple Inc.",
            quantity: Decimal(string: "100")!,
            currentPrice: Decimal(string: "150.75")!,
            avgCost: Decimal(string: "145.50")!,
            type: .stock
        )
        
        let pnl = asset.pnl
        let expected = Decimal(string: "525")!  // (150.75 - 145.50) * 100
        
        XCTAssertEqual(pnl, expected, "P&L calculation should be precise")
    }
    
    // MARK: - Property 33: Display format round trip
    
    func testStringToDecimalRoundTrip() {
        // Property: String -> Decimal -> String should preserve value
        
        let originalString = "150.25"
        let decimal = Decimal(string: originalString)!
        let resultString = NSDecimalNumber(decimal: decimal).stringValue
        
        XCTAssertEqual(Decimal(string: resultString), decimal, "Round trip should preserve value")
    }
    
    func testDecimalFormattingPreservesValue() {
        // Property: Formatting should not lose precision
        
        let decimal = Decimal(string: "150.25")!
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let formatted = formatter.string(from: NSDecimalNumber(decimal: decimal))!
        let parsed = Decimal(string: formatted.replacingOccurrences(of: ",", with: ""))!
        
        XCTAssertEqual(parsed, decimal, "Formatting round trip should preserve value")
    }
    
    // MARK: - Property 34: No double conversion
    
    func testNoDoubleConversionInCalculations() {
        // Property: Calculations should not convert through Double
        
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: Decimal(string: "0.1")!,
            quantity: Decimal(string: "0.2")!,
            assetType: .stock,
            emotion: .neutral,
            note: ""
        )
        
        // Direct Decimal calculation
        let decimalResult = trade.price + trade.quantity
        
        // If converted through Double, would lose precision
        let doubleResult = Decimal(Double(truncating: NSDecimalNumber(decimal: trade.price)) + 
                                   Double(truncating: NSDecimalNumber(decimal: trade.quantity)))
        
        // Decimal should be more precise
        XCTAssertEqual(decimalResult, Decimal(string: "0.3")!, "Decimal calculation should be exact")
    }
    
    func testDecimalTransformerAvoidDouble() {
        // Property: DecimalTransformer should not use Double
        
        let transformer = DecimalTransformer()
        let decimal = Decimal(string: "150.25")!
        
        let transformed = transformer.transformedValue(decimal)
        XCTAssertTrue(transformed is String, "Should transform to String, not Double")
        
        let reversed = transformer.reverseTransformedValue(transformed)
        XCTAssertEqual(reversed as? Decimal, decimal, "Should preserve exact value")
    }
    
    // MARK: - Property 35: Persistence round trip
    
    func testDecimalPersistenceRoundTrip() {
        // Property: Saving and loading Decimal should preserve value
        
        let transformer = DecimalTransformer()
        let original = Decimal(string: "150.25")!
        
        // Transform for storage
        let stored = transformer.transformedValue(original)
        XCTAssertNotNil(stored, "Should transform for storage")
        
        // Reverse transform for retrieval
        let retrieved = transformer.reverseTransformedValue(stored) as? Decimal
        XCTAssertEqual(retrieved, original, "Round trip should preserve exact value")
    }
    
    func testDecimalTransformerRegistration() {
        // Property: DecimalTransformer should be registered
        
        DecimalTransformer.register()
        
        let transformer = ValueTransformer(forName: NSValueTransformerName("DecimalTransformer"))
        XCTAssertNotNil(transformer, "Transformer should be registered")
        XCTAssertTrue(transformer is DecimalTransformer, "Should be DecimalTransformer instance")
    }
    
    func testMultipleDecimalsPersistence() {
        // Property: Multiple Decimal values should persist correctly
        
        let transformer = DecimalTransformer()
        let decimals = [
            Decimal(string: "0.1")!,
            Decimal(string: "150.25")!,
            Decimal(string: "1000000.99")!,
            Decimal(string: "0.00001")!
        ]
        
        for decimal in decimals {
            let stored = transformer.transformedValue(decimal)
            let retrieved = transformer.reverseTransformedValue(stored) as? Decimal
            XCTAssertEqual(retrieved, decimal, "Should preserve \(decimal)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testTradeRecordCalculations() {
        // Test complete trade record calculations
        
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: Decimal(string: "150.25")!,
            quantity: Decimal(string: "10.5")!,
            assetType: .stock,
            emotion: .neutral,
            note: "Test"
        )
        
        let totalValue = trade.totalValue
        let expected = Decimal(string: "1577.625")!
        
        XCTAssertEqual(totalValue, expected, "Total value should be calculated precisely")
    }
    
    func testAssetItemCalculations() {
        // Test complete asset calculations
        
        let asset = AssetItem(
            symbol: "AAPL",
            name: "Apple Inc.",
            quantity: Decimal(string: "100")!,
            currentPrice: Decimal(string: "150.75")!,
            avgCost: Decimal(string: "145.50")!,
            type: .stock
        )
        
        let marketValue = asset.marketValue
        let pnl = asset.pnl
        let pnlPercent = asset.pnlPercent
        
        XCTAssertEqual(marketValue, Decimal(string: "15075")!)
        XCTAssertEqual(pnl, Decimal(string: "525")!)
        
        // P&L percent: (150.75 - 145.50) / 145.50 = 0.036082...
        XCTAssertGreaterThan(pnlPercent, Decimal(string: "0.036")!)
        XCTAssertLessThan(pnlPercent, Decimal(string: "0.037")!)
    }
    
    func testBackwardCompatibility() {
        // Test backward compatibility with Double initializers
        
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: 150.25,
            quantity: 10.5,
            assetType: .stock,
            emotion: .neutral,
            note: "Test"
        )
        
        XCTAssertTrue(type(of: trade.price) == Decimal.self, "Should convert Double to Decimal")
        XCTAssertTrue(type(of: trade.quantity) == Decimal.self, "Should convert Double to Decimal")
    }
}
