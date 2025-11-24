import XCTest
@testable import personalos_ios_v2

// **Feature: system-architecture-upgrade-p0, Property 36: Complete trade history usage**
// **Feature: system-architecture-upgrade-p0, Property 37: Average cost completeness**
// **Feature: system-architecture-upgrade-p0, Property 38: Realized gains accuracy**
// **Feature: system-architecture-upgrade-p0, Property 39: Portfolio summary accuracy**

final class PortfolioCalculationTests: XCTestCase {
    
    var calculator: PortfolioCalculator!
    
    override func setUp() async throws {
        try await super.setUp()
        calculator = PortfolioCalculator()
    }
    
    override func tearDown() async throws {
        calculator = nil
        try await super.tearDown()
    }
    
    // MARK: - Property 36: Complete trade history usage
    
    func testUsesCompleteTradeHistory() async {
        // Property: Portfolio calculation should use ALL historical trades
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 10, daysAgo: 365),
            createTrade(symbol: "AAPL", type: .buy, price: 110, quantity: 10, daysAgo: 180),
            createTrade(symbol: "AAPL", type: .buy, price: 120, quantity: 10, daysAgo: 30)
        ]
        
        let result = await calculator.calculate(with: trades) { _, _ in Decimal(150) }
        
        // Should include all trades, not just recent ones
        let appleAsset = result.assets.first { $0.symbol == "AAPL" }
        XCTAssertNotNil(appleAsset, "Should have AAPL position")
        XCTAssertEqual(appleAsset?.quantity, Decimal(30), "Should include all 30 shares")
    }
    
    func testNoDateFiltering() async {
        // Property: No 90-day or other date filtering should be applied
        
        let oldTrade = createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 10, daysAgo: 500)
        let recentTrade = createTrade(symbol: "AAPL", type: .buy, price: 150, quantity: 5, daysAgo: 10)
        
        let result = await calculator.calculate(with: [oldTrade, recentTrade]) { _, _ in Decimal(150) }
        
        let asset = result.assets.first { $0.symbol == "AAPL" }
        XCTAssertEqual(asset?.quantity, Decimal(15), "Should include trades from 500 days ago")
    }
    
    func testHistoricalTradesAffectAvgCost() async {
        // Property: Old trades should affect average cost calculation
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 10, daysAgo: 365),
            createTrade(symbol: "AAPL", type: .buy, price: 200, quantity: 10, daysAgo: 1)
        ]
        
        let result = await calculator.calculate(with: trades) { _, _ in Decimal(150) }
        
        let asset = result.assets.first { $0.symbol == "AAPL" }
        // Average cost should be (100*10 + 200*10) / 20 = 150
        XCTAssertEqual(asset?.avgCost, Decimal(150), "Historical trades should affect avg cost")
    }
    
    // MARK: - Property 37: Average cost completeness
    
    func testAverageCostIncludesAllBuys() async {
        // Property: Average cost should include ALL buy transactions
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 10, daysAgo: 100),
            createTrade(symbol: "AAPL", type: .buy, price: 120, quantity: 10, daysAgo: 50),
            createTrade(symbol: "AAPL", type: .buy, price: 140, quantity: 10, daysAgo: 10)
        ]
        
        let result = await calculator.calculate(with: trades) { _, _ in Decimal(150) }
        
        let asset = result.assets.first { $0.symbol == "AAPL" }
        // Average: (100*10 + 120*10 + 140*10) / 30 = 120
        XCTAssertEqual(asset?.avgCost, Decimal(120), "Should include all buy transactions")
    }
    
    func testAverageCostAfterSells() async {
        // Property: Average cost should remain correct after sells
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 20, daysAgo: 100),
            createTrade(symbol: "AAPL", type: .sell, price: 150, quantity: 10, daysAgo: 50)
        ]
        
        let result = await calculator.calculate(with: trades) { _, _ in Decimal(150) }
        
        let asset = result.assets.first { $0.symbol == "AAPL" }
        XCTAssertEqual(asset?.avgCost, Decimal(100), "Avg cost should remain 100 after sell")
        XCTAssertEqual(asset?.quantity, Decimal(10), "Should have 10 shares remaining")
    }
    
    // MARK: - Property 38: Realized gains accuracy
    
    func testRealizedGainsFromCompleteHistory() async {
        // Property: Realized gains should match sells against complete cost basis
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 10, daysAgo: 100),
            createTrade(symbol: "AAPL", type: .sell, price: 150, quantity: 10, daysAgo: 50)
        ]
        
        let realizedGains = await calculator.calculateRealizedGains(from: trades)
        
        // Gain: (150 - 100) * 10 = 500
        XCTAssertEqual(realizedGains, Decimal(500), "Realized gains should be accurate")
    }
    
    func testRealizedGainsWithMultipleBuys() async {
        // Property: Realized gains should use average cost from all buys
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 10, daysAgo: 100),
            createTrade(symbol: "AAPL", type: .buy, price: 120, quantity: 10, daysAgo: 50),
            createTrade(symbol: "AAPL", type: .sell, price: 150, quantity: 10, daysAgo: 10)
        ]
        
        let realizedGains = await calculator.calculateRealizedGains(from: trades)
        
        // Avg cost: (100*10 + 120*10) / 20 = 110
        // Gain: (150 - 110) * 10 = 400
        XCTAssertEqual(realizedGains, Decimal(400), "Should use average cost from all buys")
    }
    
    func testRealizedLosses() async {
        // Property: Realized losses should be calculated correctly
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, price: 150, quantity: 10, daysAgo: 100),
            createTrade(symbol: "AAPL", type: .sell, price: 100, quantity: 10, daysAgo: 50)
        ]
        
        let realizedGains = await calculator.calculateRealizedGains(from: trades)
        
        // Loss: (100 - 150) * 10 = -500
        XCTAssertEqual(realizedGains, Decimal(-500), "Realized losses should be negative")
    }
    
    // MARK: - Property 39: Portfolio summary accuracy
    
    func testPortfolioSummaryMatchesCalculations() async {
        // Property: Portfolio summary should exactly match calculated positions
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 10, daysAgo: 100),
            createTrade(symbol: "GOOGL", type: .buy, price: 200, quantity: 5, daysAgo: 50)
        ]
        
        let result = await calculator.calculate(with: trades) { symbol, _ in
            symbol == "AAPL" ? Decimal(150) : Decimal(250)
        }
        
        // AAPL: 10 * 150 = 1500
        // GOOGL: 5 * 250 = 1250
        // Total: 2750
        XCTAssertEqual(result.totalBalance, Decimal(2750), "Total balance should match")
        XCTAssertEqual(result.assets.count, 2, "Should have 2 assets")
    }
    
    func testEmptyPortfolio() async {
        // Property: Empty trade history should result in empty portfolio
        
        let result = await calculator.calculate(with: []) { _, _ in Decimal(0) }
        
        XCTAssertEqual(result.assets.count, 0, "Should have no assets")
        XCTAssertEqual(result.totalBalance, Decimal(0), "Balance should be zero")
    }
    
    func testClosedPositionsNotIncluded() async {
        // Property: Fully closed positions should not appear in portfolio
        
        let trades = [
            createTrade(symbol: "AAPL", type: .buy, price: 100, quantity: 10, daysAgo: 100),
            createTrade(symbol: "AAPL", type: .sell, price: 150, quantity: 10, daysAgo: 50)
        ]
        
        let result = await calculator.calculate(with: trades) { _, _ in Decimal(150) }
        
        XCTAssertEqual(result.assets.count, 0, "Closed positions should not appear")
    }
    
    // MARK: - Trade Validation Tests
    
    func testValidateInsufficientQuantity() async {
        // Property: Validation should detect insufficient quantity for sell
        
        let positions = ["AAPL": Position(symbol: "AAPL", quantity: 5, avgCost: 100, costBasis: 500)]
        let trade = createTrade(symbol: "AAPL", type: .sell, price: 150, quantity: 10, daysAgo: 0)
        
        do {
            try await calculator.validateTrade(trade, against: positions)
            XCTFail("Should throw insufficient quantity error")
        } catch let error as ValidationError {
            if case .insufficientQuantity(let symbol, let available, let requested) = error {
                XCTAssertEqual(symbol, "AAPL")
                XCTAssertEqual(available, Decimal(5))
                XCTAssertEqual(requested, Decimal(10))
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testValidateNegativePosition() async {
        // Property: Validation should prevent negative positions
        
        let positions = ["AAPL": Position(symbol: "AAPL", quantity: 10, avgCost: 100, costBasis: 1000)]
        let trade = createTrade(symbol: "AAPL", type: .sell, price: 150, quantity: 15, daysAgo: 0)
        
        do {
            try await calculator.validateTrade(trade, against: positions)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is ValidationError, "Should be validation error")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTrade(
        symbol: String,
        type: TradeType,
        price: Double,
        quantity: Double,
        daysAgo: Int
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
