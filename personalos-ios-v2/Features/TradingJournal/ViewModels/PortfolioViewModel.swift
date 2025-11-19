import SwiftUI
import Observation
import SwiftData

@Observable
@MainActor
class PortfolioViewModel {
    var totalBalance: Double = 0
    var dayPnL: Double = 0
    var dayPnLPercent: Double = 0

    var assets: [AssetItem] = []
    var equityCurve: [EquityPoint] = []
    var trades: [TradeRecord] = []
    
    let priceService = StockPriceService()
    private let calculator = PortfolioCalculator()

    func recalculate(with trades: [TradeRecord]) {
        self.trades = trades
        let result = calculator.calculate(with: trades) { symbol, fallback in
            priceService.quotes[symbol]?.price ?? priceService.getMockPrice(for: symbol, fallback: fallback)
        }

        assets = result.assets
        totalBalance = result.totalBalance
        equityCurve = result.equityCurve
        dayPnL = result.dayPnL
        dayPnLPercent = result.dayPnLPercent
    }

    func refreshPrices() async {
        let symbols = Array(Set(trades.map { $0.symbol }))
        await priceService.fetchMultipleQuotes(symbols: symbols)
        recalculate(with: trades)
    }

    func addTrade(
        symbol: String,
        type: TradeType,
        price: Double,
        quantity: Double,
        emotion: TradeEmotion,
        note: String,
        assetType: AssetType,
        in context: ModelContext
    ) throws {
        let record = TradeRecord(
            symbol: symbol,
            type: type,
            price: price,
            quantity: quantity,
            assetType: assetType,
            emotion: emotion,
            note: note
        )

        context.insert(record)
        try context.save()
    }

    static func seedSampleTrades() -> [TradeRecord] {
        let calendar = Calendar.current
        let today = Date()
        return [
            TradeRecord(symbol: "AAPL", type: .buy, price: 150, quantity: 50, assetType: .stock, emotion: .neutral, note: "Initial position", date: calendar.date(byAdding: .day, value: -6, to: today) ?? today),
            TradeRecord(symbol: "AAPL", type: .buy, price: 155, quantity: 40, assetType: .stock, emotion: .excited, note: "Breakout add", date: calendar.date(byAdding: .day, value: -4, to: today) ?? today),
            TradeRecord(symbol: "BTC", type: .buy, price: 38000, quantity: 0.2, assetType: .crypto, emotion: .neutral, note: "Dip buy", date: calendar.date(byAdding: .day, value: -3, to: today) ?? today),
            TradeRecord(symbol: "AAPL", type: .sell, price: 165, quantity: 20, assetType: .stock, emotion: .fearful, note: "Trim into strength", date: calendar.date(byAdding: .day, value: -1, to: today) ?? today),
            TradeRecord(symbol: "BTC", type: .buy, price: 42000, quantity: 0.25, assetType: .crypto, emotion: .excited, note: "Momentum entry", date: today)
        ]
    }
}

struct AssetItem: Identifiable {
    let id = UUID()
    var symbol: String
    var name: String
    var quantity: Double
    var currentPrice: Double
    var avgCost: Double
    var type: AssetType

    var marketValue: Double { quantity * currentPrice }
    var pnl: Double { (currentPrice - avgCost) * quantity }
    var pnlPercent: Double { avgCost == 0 ? 0 : (currentPrice - avgCost) / avgCost }
}

enum AssetType: String, CaseIterable, Codable {
    case stock, crypto, forex

    var icon: String {
        switch self {
        case .stock: return "building.columns.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .forex: return "dollarsign.arrow.circlepath"
        }
    }

    var label: String {
        switch self {
        case .stock: return "Stock"
        case .crypto: return "Crypto"
        case .forex: return "Forex"
        }
    }
}

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
