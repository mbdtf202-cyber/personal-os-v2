import SwiftUI
import SwiftData

@Model
final class AssetItem {
    var id: UUID
    var symbol: String
    var name: String
    // ✅ 使用 Double 而不是 Decimal，SwiftData 原生支持
    var quantity: Double
    var currentPrice: Double
    var avgCost: Double
    var type: AssetType

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        quantity: Double,
        currentPrice: Double,
        avgCost: Double,
        type: AssetType
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.currentPrice = currentPrice
        self.avgCost = avgCost
        self.type = type
    }
    
    var marketValue: Double {
        quantity * currentPrice
    }
    
    var pnl: Double {
        (currentPrice - avgCost) * quantity
    }
    
    var pnlPercent: Double {
        guard avgCost != 0 else { return 0 }
        return (currentPrice - avgCost) / avgCost
    }
    
    // 提供 Decimal 版本用于精确计算
    var quantityDecimal: Decimal {
        Decimal(quantity)
    }
    
    var currentPriceDecimal: Decimal {
        Decimal(currentPrice)
    }
    
    var avgCostDecimal: Decimal {
        Decimal(avgCost)
    }
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
