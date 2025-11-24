import SwiftUI
import SwiftData

@Model
final class AssetItem {
    var id: UUID
    var symbol: String
    var name: String
    // ✅ P0 Fix: 使用 Decimal 类型确保金融精度
    @Attribute(.transformable(by: "DecimalTransformer"))
    var quantity: Decimal
    @Attribute(.transformable(by: "DecimalTransformer"))
    var currentPrice: Decimal
    @Attribute(.transformable(by: "DecimalTransformer"))
    var avgCost: Decimal
    var type: AssetType

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        quantity: Decimal,
        currentPrice: Decimal,
        avgCost: Decimal,
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
    
    var marketValue: Decimal {
        quantity * currentPrice
    }
    
    var pnl: Decimal {
        (currentPrice - avgCost) * quantity
    }
    
    var pnlPercent: Decimal {
        guard avgCost != 0 else { return 0 }
        return (currentPrice - avgCost) / avgCost
    }
    
    // Convenience initializer for backward compatibility
    convenience init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        quantity: Double,
        currentPrice: Double,
        avgCost: Double,
        type: AssetType
    ) {
        self.init(
            id: id,
            symbol: symbol,
            name: name,
            quantity: Decimal(quantity),
            currentPrice: Decimal(currentPrice),
            avgCost: Decimal(avgCost),
            type: type
        )
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
