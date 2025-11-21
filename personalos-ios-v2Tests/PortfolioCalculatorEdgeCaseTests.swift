import XCTest
@testable import personalos_ios_v2

/// 投资组合计算器边界条件测试
/// ✅ CTO 要求：测试边界条件和异常情况
final class PortfolioCalculatorEdgeCaseTests: XCTestCase {
    var calculator: PortfolioCalculator!
    
    override func setUp() {
        super.setUp()
        calculator = PortfolioCalculator()
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    // MARK: - 边界条件测试
    
    func testEmptyTradesReturnsZeroBalance() {
        let result = calculator.calculate(with: []) { _, lastPrice in lastPrice }
        
        XCTAssertEqual(result.totalBalance, 0)
        XCTAssertEqual(result.assets.count, 0)
        XCTAssertEqual(result.dayPnL, 0)
    }
    
    func testSellMoreThanHolding() {
        // 测试卖出数量大于持仓的情况
        let trades = [
            TradeRecord(
                symbol: "AAPL",
                type: .buy,
                price: Decimal(100),
                quantity: Decimal(10),
                assetType: .stock,
                emotion: .neutral,
                note: "Buy"
            ),
            TradeRecord(
                symbol: "AAPL",
                type: .sell,
                price: Decimal(110),
                quantity: Decimal(15), // 卖出超过持仓
                assetType: .stock,
                emotion: .neutral,
                note: "Oversell"
            )
        ]
        
        let result = calculator.calculate(with: trades) { _, lastPrice in lastPrice }
        
        // 应该只卖出实际持有的数量
        let appleAsset = result.assets.first { $0.symbol == "AAPL" }
        XCTAssertNil(appleAsset, "Should have no remaining position after selling all")
    }
    
    func testNegativePriceHandling() {
        // 测试负价格（虽然不应该发生，但要确保不崩溃）
        let trades = [
            TradeRecord(
                symbol: "TEST",
                type: .buy,
                price: Decimal(-100), // 负价格
                quantity: Decimal(10),
                assetType: .stock,
                emotion: .neutral,
                note: "Invalid"
            )
        ]
        
        let result = calculator.calculate(with: trades) { _, lastPrice in lastPrice }
        
        // 应该能处理而不崩溃
        XCTAssertNotNil(result)
    }
    
    func testZeroQuantityTrade() {
        let trades = [
            TradeRecord(
                symbol: "AAPL",
                type: .buy,
                price: Decimal(100),
                quantity: Decimal(0), // 零数量
                assetType: .stock,
                emotion: .neutral,
                note: "Zero qty"
            )
        ]
        
        let result = calculator.calculate(with: trades) { _, lastPrice in lastPrice }
        
        XCTAssertEqual(result.assets.count, 0, "Zero quantity should not create asset")
    }
    
    func testDecimalPrecision() {
        // 测试 Decimal 精度
        let trades = [
            TradeRecord(
                symbol: "BTC",
                type: .buy,
                price: Decimal(string: "50000.123456789")!,
                quantity: Decimal(string: "0.00000001")!, // 1 satoshi
                assetType: .crypto,
                emotion: .neutral,
                note: "Precision test"
            )
        ]
        
        let result = calculator.calculate(with: trades) { _, lastPrice in lastPrice }
        
        let btcAsset = result.assets.first { $0.symbol == "BTC" }
        XCTAssertNotNil(btcAsset)
        
        // 验证精度保持
        let expectedValue = Decimal(string: "50000.123456789")! * Decimal(string: "0.00000001")!
        XCTAssertEqual(btcAsset?.marketValue, expectedValue)
    }
    
    func testMultipleBuySellCycles() {
        // 测试多次买卖循环
        var trades: [TradeRecord] = []
        
        for i in 0..<100 {
            trades.append(TradeRecord(
                symbol: "AAPL",
                type: .buy,
                price: Decimal(100 + i),
                quantity: Decimal(10),
                assetType: .stock,
                emotion: .neutral,
                note: "Buy \(i)"
            ))
            
            trades.append(TradeRecord(
                symbol: "AAPL",
                type: .sell,
                price: Decimal(105 + i),
                quantity: Decimal(5),
                assetType: .stock,
                emotion: .neutral,
                note: "Sell \(i)"
            ))
        }
        
        let result = calculator.calculate(with: trades) { _, lastPrice in lastPrice }
        
        // 应该能处理大量交易
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result.assets.count, 0)
    }
    
    func testConcurrentSymbols() {
        // 测试多个不同资产
        let symbols = ["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN"]
        var trades: [TradeRecord] = []
        
        for symbol in symbols {
            trades.append(TradeRecord(
                symbol: symbol,
                type: .buy,
                price: Decimal(100),
                quantity: Decimal(10),
                assetType: .stock,
                emotion: .neutral,
                note: "Buy \(symbol)"
            ))
        }
        
        let result = calculator.calculate(with: trades) { _, lastPrice in lastPrice }
        
        XCTAssertEqual(result.assets.count, symbols.count)
    }
    
    func testPnLCalculationAccuracy() {
        // 测试盈亏计算精度
        let trades = [
            TradeRecord(
                symbol: "AAPL",
                type: .buy,
                price: Decimal(string: "150.50")!,
                quantity: Decimal(string: "100.5")!,
                assetType: .stock,
                emotion: .neutral,
                note: "Buy"
            )
        ]
        
        let currentPrice = Decimal(string: "175.75")!
        let result = calculator.calculate(with: trades) { _, _ in currentPrice }
        
        let asset = result.assets.first!
        let expectedPnL = (currentPrice - Decimal(string: "150.50")!) * Decimal(string: "100.5")!
        
        XCTAssertEqual(asset.pnl, expectedPnL)
    }
}
