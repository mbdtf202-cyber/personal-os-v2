import SwiftUI
import SwiftData

@Model
final class TradeRecord {
    var id: String
    var symbol: String
    var type: TradeType
    // ✅ P0 Fix: 使用 Decimal 类型确保金融精度
    @Attribute(.transformable(by: "DecimalTransformer"))
    var price: Decimal
    @Attribute(.transformable(by: "DecimalTransformer"))
    var quantity: Decimal
    
    // ✅ EXTREME FIX 2: 添加缩放整数字段用于高效 SQL 查询
    // 存储 price * 10000 和 quantity * 10000，支持数值比较和排序
    var priceScaled: Int64 = 0
    var quantityScaled: Int64 = 0
    
    var assetType: AssetType
    var emotion: TradeEmotion
    var note: String
    var date: Date

    init(
        id: String = UUID().uuidString,
        symbol: String,
        type: TradeType,
        price: Decimal,
        quantity: Decimal,
        assetType: AssetType,
        emotion: TradeEmotion,
        note: String,
        date: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.type = type
        self.price = price
        self.quantity = quantity
        self.priceScaled = price.scaledInt64
        self.quantityScaled = quantity.scaledInt64
        self.assetType = assetType
        self.emotion = emotion
        self.note = note
        self.date = date
    }
    
    var totalValue: Decimal {
        price * quantity
    }
    
    // Convenience initializer for backward compatibility
    convenience init(
        id: String = UUID().uuidString,
        symbol: String,
        type: TradeType,
        price: Double,
        quantity: Double,
        assetType: AssetType,
        emotion: TradeEmotion,
        note: String,
        date: Date = Date()
    ) {
        self.init(
            id: id,
            symbol: symbol,
            type: type,
            price: Decimal(price),
            quantity: Decimal(quantity),
            assetType: assetType,
            emotion: emotion,
            note: note,
            date: date
        )
    }
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
