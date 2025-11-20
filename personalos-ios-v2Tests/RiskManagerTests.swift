import XCTest
@testable import personalos_ios_v2

@MainActor
final class RiskManagerTests: XCTestCase {
    var riskManager: RiskManager!
    
    override func setUp() async throws {
        let config = RiskConfig(
            maxSingleTradeLoss: 500,
            maxDailyLoss: 1000,
            maxWeeklyLoss: 3000,
            maxPositionSize: 10000,
            maxPortfolioRisk: 0.02,
            stopLossRequired: true
        )
        riskManager = RiskManager(config: config)
    }
    
    func testPositionSizeAlert() {
        // Given
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: 150.0,
            quantity: 100,
            assetType: .stock,
            emotion: .neutral,
            note: "Test trade"
        )
        
        // When
        let alerts = riskManager.evaluateTrade(trade)
        
        // Then
        XCTAssertTrue(alerts.contains { $0.type == .positionSize })
    }
    
    func testEmotionBasedAlert() {
        // Given
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: 150.0,
            quantity: 10,
            assetType: .stock,
            emotion: .revenge,
            note: "Revenge trade"
        )
        
        // When
        let alerts = riskManager.evaluateTrade(trade)
        
        // Then
        XCTAssertTrue(alerts.contains { $0.type == .noStopLoss })
    }
    
    func testDailyRiskCalculation() {
        // Given
        let trades = [
            TradeRecord(symbol: "AAPL", type: .buy, price: 150.0, quantity: 10, assetType: .stock, emotion: .neutral, note: ""),
            TradeRecord(symbol: "GOOGL", type: .sell, price: 100.0, quantity: 5, assetType: .stock, emotion: .neutral, note: "")
        ]
        
        // When
        riskManager.evaluateDailyRisk(trades: trades)
        
        // Then
        XCTAssertNotEqual(riskManager.dailyLoss, 0)
    }
}
