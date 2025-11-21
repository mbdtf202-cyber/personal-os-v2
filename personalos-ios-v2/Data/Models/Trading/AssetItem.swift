import SwiftUI
import SwiftData

@Model
final class AssetItem {
    var id: UUID
    var symbol: String
    var name: String
    @Attribute(.transformable(by: DecimalTransformer.self))
    var quantity: Decimal
    @Attribute(.transformable(by: DecimalTransformer.self))
    var currentPrice: Decimal
    @Attribute(.transformable(by: DecimalTransformer.self))
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
