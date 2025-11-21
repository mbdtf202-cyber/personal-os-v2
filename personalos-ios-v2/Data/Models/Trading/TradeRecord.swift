import SwiftUI
import SwiftData

@Model
final class TradeRecord {
    var id: String
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
