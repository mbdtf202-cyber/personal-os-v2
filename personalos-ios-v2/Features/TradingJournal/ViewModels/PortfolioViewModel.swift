import SwiftUI
import Observation

@Observable
@MainActor
class PortfolioViewModel {
    private let storageKey = "trade_records_v2"

    var totalBalance: Double = 0
    var dayPnL: Double = 0
    var dayPnLPercent: Double = 0

    var assets: [AssetItem] = []
    var equityCurve: [EquityPoint] = []
    var trades: [TradeRecord] = []

    init() {
        loadTrades()
        recalculatePortfolio()
    }

    func addTrade(symbol: String, type: TradeType, price: Double, quantity: Double, emotion: TradeEmotion, note: String, assetType: AssetType) {
        let record = TradeRecord(symbol: symbol.uppercased(), type: type, price: price, quantity: quantity, assetType: assetType, emotion: emotion, note: note)
        trades.append(record)
        saveTrades()
        recalculatePortfolio()
    }

    // MARK: - Private Helpers

    private func loadTrades() {
        if let saved: [TradeRecord] = try? DataManager.shared.load([TradeRecord].self, forKey: storageKey) {
            trades = saved
        } else {
            trades = PortfolioViewModel.sampleTrades
        }
    }

    private func saveTrades() {
        try? DataManager.shared.save(trades, forKey: storageKey)
    }

    private func recalculatePortfolio() {
        recalculateHoldings()
        recalculateEquity()
    }

    private func recalculateHoldings() {
        var holdings: [String: HoldingSnapshot] = [:]
        let sortedTrades = trades.sorted { $0.date < $1.date }

        for trade in sortedTrades {
            var snapshot = holdings[trade.symbol] ?? HoldingSnapshot(assetType: trade.assetType)
            snapshot.assetType = trade.assetType
            snapshot.latestPrice = trade.price

            switch trade.type {
            case .buy:
                snapshot.totalCost += trade.price * trade.quantity
                snapshot.quantity += trade.quantity
            case .sell:
                let quantityToSell = min(trade.quantity, snapshot.quantity)
                let averageCost = snapshot.quantity > 0 ? snapshot.totalCost / snapshot.quantity : trade.price
                snapshot.totalCost -= averageCost * quantityToSell
                snapshot.quantity -= quantityToSell
            }

            holdings[trade.symbol] = snapshot
        }

        assets = holdings.compactMap { symbol, snapshot in
            guard snapshot.quantity > 0 else { return nil }
            let avgCost = snapshot.quantity > 0 ? snapshot.totalCost / snapshot.quantity : 0
            return AssetItem(symbol: symbol,
                             name: symbol,
                             quantity: snapshot.quantity,
                             currentPrice: snapshot.latestPrice,
                             avgCost: avgCost,
                             type: snapshot.assetType)
        }
        .sorted { $0.symbol < $1.symbol }

        totalBalance = assets.reduce(0) { $0 + $1.marketValue }
    }

    private func recalculateEquity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayStarts = (0..<7)
            .compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
            .sorted()

        let sortedTrades = trades.sorted { $0.date < $1.date }
        var holdings: [String: HoldingSnapshot] = [:]
        var tradeIndex = 0

        if let earliestDay = dayStarts.first {
            while tradeIndex < sortedTrades.count, sortedTrades[tradeIndex].date < earliestDay {
                apply(sortedTrades[tradeIndex], to: &holdings)
                tradeIndex += 1
            }
        }

        var points: [EquityPoint] = []

        for dayStart in dayStarts {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            while tradeIndex < sortedTrades.count, sortedTrades[tradeIndex].date < nextDay {
                apply(sortedTrades[tradeIndex], to: &holdings)
                tradeIndex += 1
            }

            let equity = holdings.values.reduce(0) { partialResult, snapshot in
                partialResult + snapshot.quantity * snapshot.latestPrice
            }

            let symbol = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: dayStart) - 1]
            points.append(EquityPoint(day: symbol, value: equity))
        }

        equityCurve = points

        if let latest = points.last?.value, let previous = points.dropLast().last?.value {
            dayPnL = latest - previous
            dayPnLPercent = previous != 0 ? (dayPnL / previous) * 100 : 0
        } else {
            dayPnL = 0
            dayPnLPercent = 0
        }
    }

    private func apply(_ trade: TradeRecord, to holdings: inout [String: HoldingSnapshot]) {
        var snapshot = holdings[trade.symbol] ?? HoldingSnapshot(assetType: trade.assetType)
        snapshot.assetType = trade.assetType
        snapshot.latestPrice = trade.price

        switch trade.type {
        case .buy:
            snapshot.totalCost += trade.price * trade.quantity
            snapshot.quantity += trade.quantity
        case .sell:
            let quantityToSell = min(trade.quantity, snapshot.quantity)
            let averageCost = snapshot.quantity > 0 ? snapshot.totalCost / snapshot.quantity : trade.price
            snapshot.totalCost -= averageCost * quantityToSell
            snapshot.quantity -= quantityToSell
        }

        holdings[trade.symbol] = snapshot
    }

    private static var sampleTrades: [TradeRecord] {
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
    let symbol: String
    let type: TradeType
    let price: Double
    let quantity: Double
    let assetType: AssetType
    let emotion: TradeEmotion
    let note: String
    let date: Date

    init(symbol: String, type: TradeType, price: Double, quantity: Double, assetType: AssetType, emotion: TradeEmotion, note: String, date: Date = Date()) {
        self.id = UUID().uuidString
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
