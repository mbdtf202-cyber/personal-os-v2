import SwiftUI
import Observation

@Observable
class PortfolioViewModel {
    var totalBalance: Double = 0.0
    var assets: [AssetItem] = []
    // 暂时保留曲线防止报错，后续可根据历史数据生成
    var equityCurve: [EquityPoint] = [
        EquityPoint(day: "Mon", value: 10000),
        EquityPoint(day: "Today", value: 10000)
    ]

    // ⚠️ 核心计算引擎
    func recalculate(trades: [SchemaV1.TradeRecord]) {
        var holdings: [String: (qty: Double, cost: Double)] = [:]
        for trade in trades {
            let current = holdings[trade.symbol] ?? (qty: 0, cost: 0)
            if trade.type == "Buy" {
                let newQty = current.qty + trade.quantity
                let newCost = current.cost + (trade.price * trade.quantity)
                holdings[trade.symbol] = (qty: newQty, cost: newCost)
            } else {
                // 简单处理卖出：减少持仓数量，成本按比例减少
                let newQty = current.qty - trade.quantity
                let avgPrice = current.qty > 0 ? current.cost / current.qty : 0
                let newCost = current.cost - (avgPrice * trade.quantity)
                holdings[trade.symbol] = (qty: max(0, newQty), cost: max(0, newCost))
            }
        }

        self.assets = holdings.compactMap { symbol, data in
            guard data.qty > 0 else { return nil }
            let avgCost = data.cost / data.qty
            // 注意：CurrentPrice 暂时模拟为成本的 1.1 倍，后续需接 API
            return AssetItem(symbol: symbol, name: symbol, quantity: data.qty, currentPrice: avgCost * 1.1, avgCost: avgCost, type: .stock)
        }

        self.totalBalance = self.assets.reduce(0) { $0 + $1.marketValue }
    }
}

// 辅助结构体保持在文件底部
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

enum AssetType {
    case stock, crypto, forex

    var icon: String {
        switch self {
        case .stock: return "building.columns.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .forex: return "dollarsign.arrow.circlepath"
        }
    }
}

struct EquityPoint: Identifiable {
    let id = UUID()
    var day: String
    var value: Double
}
