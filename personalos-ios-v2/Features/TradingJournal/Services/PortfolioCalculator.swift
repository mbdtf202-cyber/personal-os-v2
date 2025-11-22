import Foundation

/// 纯计算引擎：根据交易记录计算持仓、资产和权益曲线
/// ✅ 使用 Double 以兼容 SwiftData 模型
struct PortfolioCalculator {
    struct Result {
        var assets: [AssetItem]
        var totalBalance: Decimal
        var equityCurve: [EquityPoint]
        var dayPnL: Decimal
        var dayPnLPercent: Decimal
    }

    /// `priceLookup` 用于注入实时价格。回退到 `lastTradePrice`。
    func calculate(with trades: [TradeRecord], priceLookup: (String, Double) -> Decimal) -> Result {
        let sortedTrades = trades.sorted { $0.date < $1.date }
        let holdings = computeHoldings(from: sortedTrades)
        let assets = buildAssets(from: holdings, priceLookup: priceLookup)

        let totalBalance = Decimal(assets.reduce(0.0) { $0 + $1.marketValue })
        let equityCurve = buildEquityCurve(from: sortedTrades)

        let latest = equityCurve.last?.value ?? 0
        let previous = equityCurve.dropLast().last?.value ?? 0
        let dayPnL = latest - previous
        let dayPnLPercent = previous != 0 ? (dayPnL / previous) * 100 : 0

        return Result(
            assets: assets.sorted { $0.symbol < $1.symbol },
            totalBalance: totalBalance,
            equityCurve: equityCurve,
            dayPnL: dayPnL,
            dayPnLPercent: dayPnLPercent
        )
    }

    private func computeHoldings(from trades: [TradeRecord]) -> [String: HoldingSnapshot] {
        var holdings: [String: HoldingSnapshot] = [:]

        for trade in trades {
            var snapshot = holdings[trade.symbol] ?? HoldingSnapshot(assetType: trade.assetType)
            snapshot.assetType = trade.assetType
            snapshot.latestPrice = trade.price

            switch trade.type {
            case .buy:
                snapshot.totalCost += trade.price * trade.quantity
                snapshot.quantity += trade.quantity
            case .sell:
                let sellQty = min(trade.quantity, snapshot.quantity)
                let avgCost = snapshot.quantity > 0 ? snapshot.totalCost / snapshot.quantity : trade.price
                snapshot.totalCost -= avgCost * sellQty
                snapshot.quantity -= sellQty
            }

            holdings[trade.symbol] = snapshot
        }

        return holdings
    }

    private func buildAssets(from holdings: [String: HoldingSnapshot], priceLookup: (String, Double) -> Decimal) -> [AssetItem] {
        holdings.compactMap { symbol, snapshot -> AssetItem? in
            guard snapshot.quantity > 0 else { return nil }
            let avgCost = snapshot.quantity > 0 ? snapshot.totalCost / snapshot.quantity : 0.0
            let currentPriceDecimal = priceLookup(symbol, snapshot.latestPrice)
            let currentPrice = Double(truncating: currentPriceDecimal as NSNumber)

            return AssetItem(
                symbol: symbol,
                name: symbol,
                quantity: snapshot.quantity,
                currentPrice: currentPrice,
                avgCost: avgCost,
                type: snapshot.assetType
            )
        }
    }

    private func buildEquityCurve(from trades: [TradeRecord]) -> [EquityPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayStarts = (0..<7)
            .compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
            .sorted()

        var holdings: [String: HoldingSnapshot] = [:]
        var tradeIndex = 0
        var points: [EquityPoint] = []

        if let earliestDay = dayStarts.first {
            while tradeIndex < trades.count, trades[tradeIndex].date < earliestDay {
                apply(trades[tradeIndex], to: &holdings)
                tradeIndex += 1
            }
        }

        for dayStart in dayStarts {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            while tradeIndex < trades.count, trades[tradeIndex].date < nextDay {
                apply(trades[tradeIndex], to: &holdings)
                tradeIndex += 1
            }

            let equity = holdings.values.reduce(0.0) { partial, snapshot in
                partial + snapshot.quantity * snapshot.latestPrice
            }

            let symbol = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: dayStart) - 1]
            points.append(EquityPoint(day: symbol, value: Decimal(equity)))
        }

        return points
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
            let sellQty = min(trade.quantity, snapshot.quantity)
            let avgCost = snapshot.quantity > 0 ? snapshot.totalCost / snapshot.quantity : trade.price
            snapshot.totalCost -= avgCost * sellQty
            snapshot.quantity -= sellQty
        }

        holdings[trade.symbol] = snapshot
    }
}

// MARK: - Supporting Types

struct HoldingSnapshot {
    var assetType: AssetType
    var quantity: Double = 0
    var totalCost: Double = 0
    var latestPrice: Double = 0
}

struct EquityPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Decimal
}
