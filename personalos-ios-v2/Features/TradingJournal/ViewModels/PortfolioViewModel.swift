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

enum TradeType: String, CaseIterable, Codable {
    case buy = "Buy"
    case sell = "Sell"
}

enum TradeEmotion: String, CaseIterable, Codable {
    case excited = "Excited"
    case fearful = "Fearful"
    case neutral = "Neutral"
    case revenge = "Revenge"

    var color: Color {
        switch self {
        case .excited: return .orange
        case .fearful: return .purple
        case .neutral: return .blue
        case .revenge: return .red
        }
    }
}

struct TradeRecord: Identifiable, Codable {
    let id: String
    var symbol: String
    var type: TradeType
    var price: Double
    var quantity: Double
    var assetType: AssetType
    var emotion: TradeEmotion
    var note: String
    var date: Date

    init(id: String = UUID().uuidString, symbol: String, type: TradeType, price: Double, quantity: Double, assetType: AssetType, emotion: TradeEmotion, note: String, date: Date = Date()) {
        self.id = id
        self.symbol = symbol
        self.type = type
        self.price = price
        self.quantity = quantity
        self.assetType = assetType
        self.emotion = emotion
        self.note = note
        self.date = date
    }
}
