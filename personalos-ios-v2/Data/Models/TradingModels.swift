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
