import SwiftUI
import Observation

@Observable
class PortfolioViewModel {
    var totalBalance: Double = 124500.00
    var dayPnL: Double = 1250.00
    var dayPnLPercent: Double = 1.02
    
    var assets: [AssetItem] = [
        AssetItem(symbol: "AAPL", name: "Apple Inc.", quantity: 150, currentPrice: 175.50, avgCost: 150.00, type: .stock),
        AssetItem(symbol: "BTC", name: "Bitcoin", quantity: 0.45, currentPrice: 42000.00, avgCost: 38000.00, type: .crypto),
        AssetItem(symbol: "NVDA", name: "Nvidia", quantity: 20, currentPrice: 480.00, avgCost: 400.00, type: .stock)
    ]
    
    var equityCurve: [EquityPoint] = [
        EquityPoint(day: "Mon", value: 118000),
        EquityPoint(day: "Tue", value: 119500),
        EquityPoint(day: "Wed", value: 119000),
        EquityPoint(day: "Thu", value: 121000),
        EquityPoint(day: "Fri", value: 123500),
        EquityPoint(day: "Sat", value: 124000),
        EquityPoint(day: "Sun", value: 124500)
    ]
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
    var pnlPercent: Double { (currentPrice - avgCost) / avgCost }
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
