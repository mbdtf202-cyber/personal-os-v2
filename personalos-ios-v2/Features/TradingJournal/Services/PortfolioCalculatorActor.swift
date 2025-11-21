import Foundation

/// 后台 Actor 用于执行耗时的投资组合计算
/// ✅ 避免阻塞主线程
actor PortfolioCalculatorActor {
    private let calculator = PortfolioCalculator()
    
    func calculate(
        with trades: [TradeRecord],
        priceLookup: @Sendable (String, Decimal) -> Decimal
    ) async -> PortfolioCalculator.Result {
        calculator.calculate(with: trades, priceLookup: priceLookup)
    }
    
    func calculateEquityCurve(from trades: [TradeRecord]) async -> [EquityPoint] {
        let result = calculator.calculate(with: trades) { _, lastPrice in lastPrice }
        return result.equityCurve
    }
    
    func calculateTotalBalance(from assets: [AssetItem]) async -> Decimal {
        assets.reduce(Decimal.zero) { $0 + $1.marketValue }
    }
}
