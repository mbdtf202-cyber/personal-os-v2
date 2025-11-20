import XCTest
@testable import personalos_ios_v2

final class PortfolioCalculatorTests: XCTestCase {
    var calculator: PortfolioCalculator!
    
    override func setUp() {
        super.setUp()
        calculator = PortfolioCalculator()
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    // MARK: - Buy Tests
    
    func testSingleBuyTrade() {
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: 150.0,
            quantity: 10.0,
            assetType: .stock,
            emotion: .neutral,
            note: ""
        )
        
        let result = calculator.calculate(with: [trade]) { _, fallback in fallback ?? 150.0 }
        
        XCTAssertEqual(result.assets.count, 1)
        XCTAssertEqual(result.assets.first?.symbol, "AAPL")
        XCTAssertEqual(result.assets.first?.quantity, 10.0)
        XCTAssertEqual(result.assets.first?.avgCost, 150.0)
        XCTAssertEqual(result.totalBalance, 1500.0)
    }
    
    func testMultipleBuyTrades() {
        let trades = [
            TradeRecord(symbol: "AAPL", type: .buy, price: 150.0, quantity: 10.0, assetType: .stock, emotion: .neutral, note: ""),
            TradeRecord(symbol: "AAPL", type: .buy, price: 160.0, quantity: 5.0, assetType: .stock, emotion: .neutral, note: "")
        ]
        
        let result = calculator.calculate(with: trades) { _, fallback in fallback ?? 160.0 }
        
        XCTAssertEqual(result.assets.count, 1)
        XCTAssertEqual(result.assets.first?.quantity, 15.0)
        // Average cost: (150*10 + 160*5) / 15 = 153.33
        XCTAssertEqual(result.assets.first?.avgCost, 153.33, accuracy: 0.01)
    }
    
    // MARK: - Sell Tests
    
    func testBuyThenSell() {
        let trades = [
            TradeRecord(symbol: "AAPL", type: .buy, price: 150.0, quantity: 10.0, assetType: .stock, emotion: .neutral, note: ""),
            TradeRecord(symbol: "AAPL", type: .sell, price: 160.0, quantity: 5.0, assetType: .stock, emotion: .neutral, note: "")
        ]
        
        let result = calculator.calculate(with: trades) { _, fallback in fallback ?? 160.0 }
        
        XCTAssertEqual(result.assets.count, 1)
        XCTAssertEqual(result.assets.first?.quantity, 5.0)
        XCTAssertEqual(result.assets.first?.avgCost, 150.0)
    }
    
    func testSellAllShares() {
        let trades = [
            TradeRecord(symbol: "AAPL", type: .buy, price: 150.0, quantity: 10.0, assetType: .stock, emotion: .neutral, note: ""),
            TradeRecord(symbol: "AAPL", type: .sell, price: 160.0, quantity: 10.0, assetType: .stock, emotion: .neutral, note: "")
        ]
        
        let result = calculator.calculate(with: trades) { _, fallback in fallback ?? 160.0 }
        
        // Should have no assets after selling all
        XCTAssertEqual(result.assets.count, 0)
        XCTAssertEqual(result.totalBalance, 0.0)
    }
    
    // MARK: - Multiple Symbols Tests
    
    func testMultipleSymbols() {
        let trades = [
            TradeRecord(symbol: "AAPL", type: .buy, price: 150.0, quantity: 10.0, assetType: .stock, emotion: .neutral, note: ""),
            TradeRecord(symbol: "GOOGL", type: .buy, price: 140.0, quantity: 5.0, assetType: .stock, emotion: .neutral, note: ""),
            TradeRecord(symbol: "MSFT", type: .buy, price: 380.0, quantity: 2.0, assetType: .stock, emotion: .neutral, note: "")
        ]
        
        let result = calculator.calculate(with: trades) { symbol, _ in
            switch symbol {
            case "AAPL": return 150.0
            case "GOOGL": return 140.0
            case "MSFT": return 380.0
            default: return 100.0
            }
        }
        
        XCTAssertEqual(result.assets.count, 3)
        XCTAssertEqual(result.totalBalance, 150*10 + 140*5 + 380*2)
    }
    
    // MARK: - Price Lookup Tests
    
    func testPriceLookupWithCurrentPrice() {
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: 150.0,
            quantity: 10.0,
            assetType: .stock,
            emotion: .neutral,
            note: ""
        )
        
        // Current price is 175.0
        let result = calculator.calculate(with: [trade]) { _, _ in 175.0 }
        
        XCTAssertEqual(result.assets.first?.currentPrice, 175.0)
        XCTAssertEqual(result.assets.first?.marketValue, 1750.0)
        XCTAssertEqual(result.assets.first?.pnl, 250.0) // (175-150)*10
    }
    
    // MARK: - Edge Cases
    
    func testEmptyTrades() {
        let result = calculator.calculate(with: []) { _, _ in 100.0 }
        
        XCTAssertEqual(result.assets.count, 0)
        XCTAssertEqual(result.totalBalance, 0.0)
    }
    
    func testSellMoreThanOwned() {
        let trades = [
            TradeRecord(symbol: "AAPL", type: .buy, price: 150.0, quantity: 10.0, assetType: .stock, emotion: .neutral, note: ""),
            TradeRecord(symbol: "AAPL", type: .sell, price: 160.0, quantity: 15.0, assetType: .stock, emotion: .neutral, note: "")
        ]
        
        let result = calculator.calculate(with: trades) { _, fallback in fallback ?? 160.0 }
        
        // Should handle gracefully - no negative quantities
        XCTAssertEqual(result.assets.count, 0)
    }
}
