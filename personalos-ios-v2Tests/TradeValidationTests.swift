import XCTest
@testable import personalos_ios_v2

// **Feature: system-architecture-upgrade-p0, Property 42: Sell quantity validation**
// **Feature: system-architecture-upgrade-p0, Property 43: Negative position prevention**
// **Feature: system-architecture-upgrade-p0, Property 44: Position non-negativity invariant**
// **Feature: system-architecture-upgrade-p0, Property 45: Zero position closure**
// **Feature: system-architecture-upgrade-p0, Property 46: Inconsistency detection**

final class TradeValidationTests: XCTestCase {
    
    var calculator: PortfolioCalculator!
    
    override func setUp() async throws {
        try await super.setUp()
        calculator = PortfolioCalculator()
    }
    
    override func tearDown() async throws {
        calculator = nil
        try await super.tearDown()
    }
    
    // MARK: - Property 42: Sell quantity validation
    
    func testSellQuantityValidation() async throws {
        // Property: System should verify sufficient quantity for sell
        
        let positions = ["AAPL": Position(symbol: "AAPL", quantity: 10, avgCost: 100, costBasis: 1000)]
        
        // Valid sell
        let validTrade = createTrade(symbol: "AAPL", type: .sell, quantity: 5)
        try await calculator.validateTrade(validTrade, against: positions)
        
        // Invalid sell - insufficient quantity
        let invalidTrade = createTrade(symbol: "AAPL", type: .sell, quantity: 15)
        
        do {
            try await calculator.validateTrade(invalidTrade, against: positions)
            XCTFail("Should throw insufficient quantity error")
        } catch let error as ValidationError {
            if case .insufficientQuantity(let symbol, let available, let requested) = error {
                XCTAssertEqual(symbol, "AAPL")
                XCTAssertEqual(available, Decimal(10))
                XCTAssertEqual(requested, Decimal(15))
            } else {
                XCTFail("Wrong validation error type")
            }
        }
    }
    
    func testSellWithoutPosition() async throws {
        // Property: Cannot sell without owning the asset
        
        let positions: [String: Position] = [:]
        let trade = createTrade(symbol: "AAPL", type: .sell, quantity: 10)
        
        do {
            try await calculator.validateTrade(trade, against: positions)
            XCTFail("Should throw insufficient quantity error")
        } catch let error as ValidationError {
            if case .insufficientQuantity(let symbol, let available, _) = error {
                XCTAssertEqual(symbol, "AAPL")
                XCTAssertEqual(available, Decimal(0))
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testExactQuantitySell() async throws {
        // Property: Can sell exact quantity owned
        
        let positions = ["AAPL": Position(symbol: "AAPL", quantity: 10, avgCost: 100, costBasis: 1000)]
        let trade = createTrade(symbol: "AAPL", type: .sell, quantity: 10)
        
        // Should not throw
        try await calculator.validateTrade(trade, against: positions)
    }
    
    // MARK: - Property 43: Negative position prevention
    
    func testNegativePositionPrevention() async throws {
        // Property: System should reject trades that would result in negative position
        
        let positions = ["AAPL": Position(symbol: "AAPL", quantity: 10, avgCost: 100, costBasis: 1000)]
        let trade = createTrade(symbol: "AAPL", type: .sell, quantity: 15)
        
        do {
            try await calculator.validateTrade(trade, against: positions)
            XCTFail("Should prevent negative position")
        } catch {
            XCTAssertTrue(error is ValidationError, "Should throw validation error")
        }
    }
    
    func testOversellPrevention() async throws {
        // Property: Cannot sell more than owned
        
        let positions = ["AAPL": Position(symbol: "AAPL", quantity: 5, avgCost: 100, costBasis: 500)]
        let trade = createTrade(symbol: "AAPL", type: .sell, quantity: 10)
        
        do {
            try await calculator.validateTrade(trade, against: positions)
            XCTFail("Should prevent overselling")
        } catch let error as ValidationError {
            if case .insufficientQuantity = error {
                XCTAssertTrue(true, "Correct error type")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    // MARK: - Property 44: Position non-negativity invariant
    
    func testPositionNonNegativityInvariant() async {
        // Property: All positions should have non-negative quantities
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, quantity: 10, daysAgo: 10),
            createTrade(symbol: "AAPL", type: .sell, quantity: 5, daysAgo: 5)
        ]
        
        let result = await calculator.calculate(with: trades) { _, _ in Decimal(150) }
        
        for asset in result.assets {
            XCTAssertGreaterThanOrEqual(asset.quantity, 0, "Position quantity should be non-negative")
        }
    }
    
    func testSequentialTradesNonNegativity() async {
        // Property: Sequential valid trades should maintain non-negative positions
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, quantity: 20, daysAgo: 20),
            createTrade(symbol: "AAPL", type: .sell, quantity: 5, daysAgo: 15),
            createTrade(symbol: "AAPL", type: .sell, quantity: 5, daysAgo: 10),
            createTrade(symbol: "AAPL", type: .buy, quantity: 10, daysAgo: 5)
        ]
        
        let result = await calculator.calculate(with: trades) { _, _ in Decimal(150) }
        
        let asset = result.assets.first { $0.symbol == "AAPL" }
        XCTAssertNotNil(asset)
        XCTAssertEqual(asset?.quantity, Decimal(20), "Should have 20 shares")
        XCTAssertGreaterThanOrEqual(asset?.quantity ?? 0, 0)
    }
    
    // MARK: - Property 45: Zero position closure
    
    func testZeroPositionClosure() async {
        // Property: Position reaching zero should be properly closed
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, quantity: 10, daysAgo: 10),
            createTrade(symbol: "AAPL", type: .sell, quantity: 10, daysAgo: 5)
        ]
        
        let result = await calculator.calculate(with: trades) { _, _ in Decimal(150) }
        
        // Closed position should not appear in assets
        let asset = result.assets.first { $0.symbol == "AAPL" }
        XCTAssertNil(asset, "Closed position should not appear in portfolio")
    }
    
    func testPartialThenFullClosure() async {
        // Property: Partial sells followed by full closure
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, quantity: 20, daysAgo: 20),
            createTrade(symbol: "AAPL", type: .sell, quantity: 10, daysAgo: 15),
            createTrade(symbol: "AAPL", type: .sell, quantity: 10, daysAgo: 10)
        ]
        
        let result = await calculator.calculate(with: trades) { _, _ in Decimal(150) }
        
        let asset = result.assets.first { $0.symbol == "AAPL" }
        XCTAssertNil(asset, "Fully closed position should not appear")
    }
    
    // MARK: - Property 46: Inconsistency detection
    
    func testInvalidPriceDetection() async throws {
        // Property: System should detect invalid prices
        
        let positions: [String: Position] = [:]
        let trade = createTrade(symbol: "AAPL", type: .buy, price: -100, quantity: 10)
        
        do {
            try await calculator.validateTrade(trade, against: positions)
            XCTFail("Should detect invalid price")
        } catch let error as ValidationError {
            if case .invalidPrice = error {
                XCTAssertTrue(true, "Correct error type")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testZeroPriceDetection() async throws {
        // Property: Zero price should be invalid
        
        let positions: [String: Position] = [:]
        let trade = createTrade(symbol: "AAPL", type: .buy, price: 0, quantity: 10)
        
        do {
            try await calculator.validateTrade(trade, against: positions)
            XCTFail("Should detect zero price")
        } catch let error as ValidationError {
            if case .invalidPrice = error {
                XCTAssertTrue(true, "Correct error type")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testInvalidQuantityDetection() async throws {
        // Property: System should detect invalid quantities
        
        let positions: [String: Position] = [:]
        let trade = createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: -10)
        
        do {
            try await calculator.validateTrade(trade, against: positions)
            XCTFail("Should detect invalid quantity")
        } catch let error as ValidationError {
            if case .invalidInput(let field, _) = error {
                XCTAssertEqual(field, "quantity")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testZeroQuantityDetection() async throws {
        // Property: Zero quantity should be invalid
        
        let positions: [String: Position] = [:]
        let trade = createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 0)
        
        do {
            try await calculator.validateTrade(trade, against: positions)
            XCTFail("Should detect zero quantity")
        } catch {
            XCTAssertTrue(error is ValidationError, "Should be validation error")
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteValidationWorkflow() async throws {
        // Test complete validation workflow
        
        var positions: [String: Position] = [:]
        
        // Buy trade - should pass
        let buyTrade = createTrade(symbol: "AAPL", type: .buy, quantity: 10)
        try await calculator.validateTrade(buyTrade, against: positions)
        
        // Update positions
        positions["AAPL"] = Position(symbol: "AAPL", quantity: 10, avgCost: 100, costBasis: 1000)
        
        // Valid sell - should pass
        let validSell = createTrade(symbol: "AAPL", type: .sell, quantity: 5)
        try await calculator.validateTrade(validSell, against: positions)
        
        // Invalid sell - should fail
        let invalidSell = createTrade(symbol: "AAPL", type: .sell, quantity: 15)
        
        do {
            try await calculator.validateTrade(invalidSell, against: positions)
            XCTFail("Should fail validation")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTrade(
        symbol: String,
        type: TradeType,
        price: Double = 100,
        quantity: Double,
        daysAgo: Int = 0
    ) -> TradeRecord {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return TradeRecord(
            symbol: symbol,
            type: type,
            price: Decimal(price),
            quantity: Decimal(quantity),
            assetType: .stock,
            emotion: .neutral,
            note: "",
            date: date
        )
    }
}
