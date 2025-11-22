import SwiftUI
import Observation

@Observable
@MainActor
class PortfolioViewModel {
    var totalBalance: Decimal = 0
    var dayPnL: Decimal = 0
    var dayPnLPercent: Decimal = 0
    var assets: [AssetItem] = []
    var equityCurve: [EquityPoint] = []
    
    var priceService: StockPriceService?
    private let calculator = PortfolioCalculator()

    func recalculatePortfolio(from trades: [TradeRecord]) {
        let result = calculator.calculate(with: trades) { symbol, fallback in
            if let price = priceService?.quotes[symbol]?.price {
                return Decimal(price)
            }
            return Decimal(fallback)
        }

        assets = result.assets
        totalBalance = result.totalBalance
        equityCurve = result.equityCurve
        dayPnL = result.dayPnL
        dayPnLPercent = result.dayPnLPercent
    }

    func refreshPrices(for trades: [TradeRecord]) async {
        guard let priceService = priceService else { return }
        let symbols = Array(Set(trades.map { $0.symbol }))
        do {
            _ = try await priceService.fetchMultipleQuotes(symbols: symbols)
            recalculatePortfolio(from: trades)
        } catch {
            Logger.error("Failed to refresh prices: \(error)", category: Logger.trading)
        }
    }
}


