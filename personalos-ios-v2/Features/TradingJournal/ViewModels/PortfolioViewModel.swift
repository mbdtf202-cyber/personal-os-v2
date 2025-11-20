import SwiftUI
import Observation

@Observable
class PortfolioViewModel {
    var totalBalance: Double = 0.0
    var assets: [AssetItem] = []
    var equityCurve: [EquityPoint] = [] // 暂时保留结构以防报错

    // ⚠️ 核心计算引擎
    func recalculate(trades: [SchemaV1.TradeRecord]) {
        var holdings: [String: (qty: Double, cost: Double)] = [:]
        for trade in trades {
            let current = holdings[trade.symbol] ?? (qty: 0, cost: 0)
            if trade.type == "Buy" {
                holdings[trade.symbol] = (qty: current.qty + trade.quantity, cost: current.cost + (trade.price * trade.quantity))
            } else {
                // 简化卖出逻辑
                holdings[trade.symbol] = (qty: current.qty - trade.quantity, cost: current.cost)
            }
        }

        self.assets = holdings.compactMap { symbol, data in
            guard data.qty > 0 else { return nil }
            let avgCost = data.cost / data.qty
            // ⚠️ 注意：CurrentPrice 暂时模拟为成本的 1.1 倍，后续需接 API
            return AssetItem(symbol: symbol, name: symbol, quantity: data.qty, currentPrice: avgCost * 1.1, avgCost: avgCost, type: .stock)
        }

        self.totalBalance = self.assets.reduce(0) { $0 + $1.marketValue }

        // 简单生成一个模拟曲线防止 UI 报错
        self.equityCurve = [
            EquityPoint(day: "Mon", value: totalBalance * 0.9),
            EquityPoint(day: "Today", value: totalBalance)
        ]
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
