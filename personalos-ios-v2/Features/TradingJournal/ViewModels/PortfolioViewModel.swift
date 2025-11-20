import SwiftUI
import Observation

@Observable
@MainActor
class PortfolioViewModel {
    var totalBalance: Double = 0
    var dayPnL: Double = 0
    var dayPnLPercent: Double = 0

    var assets: [AssetItem] = []
    var equityCurve: [EquityPoint] = []
    
    // Trades are now passed in from the View which uses @Query
    
    let priceService = StockPriceService()
    private let calculator = PortfolioCalculator()

    func recalculatePortfolio(from trades: [TradeRecord]) {
        let result = calculator.calculate(with: trades) { symbol, fallback in
            priceService.quotes[symbol]?.price ?? priceService.getMockPrice(for: symbol, fallback: fallback)
        }

        assets = result.assets
        totalBalance = result.totalBalance
        equityCurve = result.equityCurve
        dayPnL = result.dayPnL
        dayPnLPercent = result.dayPnLPercent
    }

    func refreshPrices(for trades: [TradeRecord]) async {
        let symbols = Array(Set(trades.map { $0.symbol }))
        await priceService.fetchMultipleQuotes(symbols: symbols)
        recalculatePortfolio(from: trades)
    }
}

// AssetItem and AssetType moved to UnifiedSchema.swift

struct EquityPoint: Identifiable {
    let id = UUID()
    var day: String
    var value: Double
}

struct HoldingSnapshot {
    var quantity: Double = 0
    var totalCost: Double = 0
    var latestPrice: Double = 0
    var assetType: AssetType
}

// TradeRecord, TradeType, TradeEmotion moved to UnifiedSchema.swift
