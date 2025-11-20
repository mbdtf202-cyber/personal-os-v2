import SwiftUI

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
