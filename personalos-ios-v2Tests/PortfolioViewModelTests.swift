import XCTest
@testable import personalos_ios_v2

@MainActor
final class PortfolioViewModelTests: XCTestCase {
    var viewModel: PortfolioViewModel!
    
    override func setUp() {
        viewModel = PortfolioViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
    }
    
    // MARK: - calculateTotalValue Tests
    
    func testCalculateTotalValue_EmptyAssets() {
        let total = viewModel.calculateTotalValue(assets: [])
        XCTAssertEqual(total, 0.0, accuracy: 0.01)
    }
    
    func testCalculateTotalValue_MultipleAssets() {
        let assets = [
            AssetItem(symbol: "AAPL", name: "Apple", quantity: 10, currentPrice: 150.0, avgCost: 140.0, type: .stock),
            AssetItem(symbol: "BTC", name: "Bitcoin", quantity: 0.5, currentPrice: 40000.0, avgCost: 35000.0, type: .crypto)
        ]
        
        let total = viewModel.calculateTotalValue(assets: assets)
        // 10 * 150 + 0.5 * 40000 = 1500 + 20000 = 21500
        XCTAssertEqual(total, 21500.0, accuracy: 0.01)
    }
    
    // MARK: - calculateTotalPnL Tests
    
    func testCalculateTotalPnL_EmptyAssets() {
        let pnl = viewModel.calculateTotalPnL(assets: [])
        XCTAssertEqual(pnl, 0.0, accuracy: 0.01)
    }
    
    func testCalculateTotalPnL_Profit() {
        let assets = [
            AssetItem(symbol: "AAPL", name: "Apple", quantity: 10, currentPrice: 150.0, avgCost: 140.0, type: .stock)
        ]
        
        let pnl = viewModel.calculateTotalPnL(assets: assets)
        // (150 - 140) * 10 = 100
        XCTAssertEqual(pnl, 100.0, accuracy: 0.01)
    }
    
    func testCalculateTotalPnL_Loss() {
        let assets = [
            AssetItem(symbol: "AAPL", name: "Apple", quantity: 10, currentPrice: 130.0, avgCost: 140.0, type: .stock)
        ]
        
        let pnl = viewModel.calculateTotalPnL(assets: assets)
        // (130 - 140) * 10 = -100
        XCTAssertEqual(pnl, -100.0, accuracy: 0.01)
    }
    
    func testCalculateTotalPnL_Mixed() {
        let assets = [
            AssetItem(symbol: "AAPL", name: "Apple", quantity: 10, currentPrice: 150.0, avgCost: 140.0, type: .stock),
            AssetItem(symbol: "TSLA", name: "Tesla", quantity: 5, currentPrice: 200.0, avgCost: 220.0, type: .stock)
        ]
        
        let pnl = viewModel.calculateTotalPnL(assets: assets)
        // (150 - 140) * 10 + (200 - 220) * 5 = 100 - 100 = 0
        XCTAssertEqual(pnl, 0.0, accuracy: 0.01)
    }
    
    // MARK: - calculatePnLPercentage Tests
    
    func testCalculatePnLPercentage_ZeroCost() {
        let pnl = viewModel.calculatePnLPercentage(pnl: 100, totalCost: 0)
        XCTAssertEqual(pnl, 0.0, accuracy: 0.01)
    }
    
    func testCalculatePnLPercentage_Profit() {
        let pnl = viewModel.calculatePnLPercentage(pnl: 100, totalCost: 1000)
        XCTAssertEqual(pnl, 10.0, accuracy: 0.01)
    }
    
    func testCalculatePnLPercentage_Loss() {
        let pnl = viewModel.calculatePnLPercentage(pnl: -100, totalCost: 1000)
        XCTAssertEqual(pnl, -10.0, accuracy: 0.01)
    }
    
    // MARK: - groupAssetsByType Tests
    
    func testGroupAssetsByType() {
        let assets = [
            AssetItem(symbol: "AAPL", name: "Apple", quantity: 10, currentPrice: 150.0, avgCost: 140.0, type: .stock),
            AssetItem(symbol: "BTC", name: "Bitcoin", quantity: 0.5, currentPrice: 40000.0, avgCost: 35000.0, type: .crypto),
            AssetItem(symbol: "TSLA", name: "Tesla", quantity: 5, currentPrice: 200.0, avgCost: 220.0, type: .stock)
        ]
        
        let grouped = viewModel.groupAssetsByType(assets: assets)
        
        XCTAssertEqual(grouped[.stock]?.count, 2)
        XCTAssertEqual(grouped[.crypto]?.count, 1)
        XCTAssertNil(grouped[.forex])
    }
    
    // MARK: - Edge Cases
    
    func testAssetItem_MarketValue() {
        let asset = AssetItem(symbol: "AAPL", name: "Apple", quantity: 10, currentPrice: 150.0, avgCost: 140.0, type: .stock)
        XCTAssertEqual(asset.marketValue, 1500.0, accuracy: 0.01)
    }
    
    func testAssetItem_PnL() {
        let asset = AssetItem(symbol: "AAPL", name: "Apple", quantity: 10, currentPrice: 150.0, avgCost: 140.0, type: .stock)
        XCTAssertEqual(asset.pnl, 100.0, accuracy: 0.01)
    }
    
    func testAssetItem_PnLPercent() {
        let asset = AssetItem(symbol: "AAPL", name: "Apple", quantity: 10, currentPrice: 150.0, avgCost: 140.0, type: .stock)
        XCTAssertEqual(asset.pnlPercent, 0.0714, accuracy: 0.001) // (150-140)/140 ≈ 7.14%
    }
    
    func testAssetItem_PnLPercent_ZeroCost() {
        let asset = AssetItem(symbol: "AAPL", name: "Apple", quantity: 10, currentPrice: 150.0, avgCost: 0.0, type: .stock)
        XCTAssertEqual(asset.pnlPercent, 0.0, accuracy: 0.01)
    }
}
