import Foundation
import SwiftUI
import Combine

struct RiskConfig: Codable {
    var maxSingleTradeLoss: Double = 500.0
    var maxDailyLoss: Double = 1000.0
    var maxWeeklyLoss: Double = 3000.0
    var maxPositionSize: Double = 10000.0
    var maxPortfolioRisk: Double = 0.02 // 2%
    var stopLossRequired: Bool = true
}

struct RiskAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let message: String
    let severity: Severity
    let timestamp: Date
    
    enum AlertType {
        case singleTradeLoss
        case dailyLoss
        case weeklyLoss
        case positionSize
        case portfolioRisk
        case noStopLoss
        case correlation
    }
    
    enum Severity {
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
}

@MainActor
class RiskManager: ObservableObject {
    @Published var config: RiskConfig
    @Published var alerts: [RiskAlert] = []
    @Published var dailyLoss: Double = 0
    @Published var weeklyLoss: Double = 0
    
    init(config: RiskConfig? = nil) {
        let initialConfig = config ?? RiskConfig(
            maxSingleTradeLoss: 500.0,
            maxDailyLoss: 1000.0,
            maxWeeklyLoss: 3000.0,
            maxPositionSize: 10000.0,
            maxPortfolioRisk: 0.02,
            stopLossRequired: true
        )
        self._config = Published(initialValue: initialConfig)
        self._alerts = Published(initialValue: [])
        self._dailyLoss = Published(initialValue: 0)
        self._weeklyLoss = Published(initialValue: 0)
        loadConfig()
    }
    
    func evaluateTrade(_ trade: TradeRecord) -> [RiskAlert] {
        var newAlerts: [RiskAlert] = []
        
        // Check position size
        let positionValue = trade.quantity * trade.price
        if positionValue > config.maxPositionSize {
            newAlerts.append(RiskAlert(
                type: .positionSize,
                message: "Position size $\(String(format: "%.2f", positionValue)) exceeds limit",
                severity: .critical,
                timestamp: Date()
            ))
        } else if positionValue > config.maxPositionSize * 0.8 {
            newAlerts.append(RiskAlert(
                type: .positionSize,
                message: "Position size approaching limit: $\(String(format: "%.2f", positionValue))",
                severity: .warning,
                timestamp: Date()
            ))
        }
        
        // Check emotion-based risk
        if trade.emotion == .revenge || trade.emotion == .fearful {
            newAlerts.append(RiskAlert(
                type: .noStopLoss,
                message: "Trading with \(trade.emotion.rawValue) emotion - high risk",
                severity: .warning,
                timestamp: Date()
            ))
        }
        
        alerts.append(contentsOf: newAlerts)
        return newAlerts
    }
    
    func evaluateDailyRisk(trades: [TradeRecord]) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTrades = trades.filter { trade in
            Calendar.current.isDate(trade.date, inSameDayAs: today)
        }
        
        // Calculate daily P&L based on trade type
        dailyLoss = todayTrades.reduce(0) { sum, trade in
            let tradeValue = trade.quantity * trade.price
            return sum + (trade.type == .sell ? tradeValue : -tradeValue)
        }
        
        if dailyLoss < -config.maxDailyLoss {
            alerts.append(RiskAlert(
                type: .dailyLoss,
                message: "Daily loss limit exceeded: $\(String(format: "%.2f", abs(dailyLoss)))",
                severity: .critical,
                timestamp: Date()
            ))
        } else if dailyLoss < -config.maxDailyLoss * 0.8 {
            alerts.append(RiskAlert(
                type: .dailyLoss,
                message: "Approaching daily loss limit: $\(String(format: "%.2f", abs(dailyLoss)))",
                severity: .warning,
                timestamp: Date()
            ))
        }
    }
    
    func evaluateWeeklyRisk(trades: [TradeRecord]) {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let weekTrades = trades.filter { trade in
            trade.date >= weekAgo
        }
        
        weeklyLoss = weekTrades.reduce(0) { sum, trade in
            let tradeValue = trade.quantity * trade.price
            return sum + (trade.type == .sell ? tradeValue : -tradeValue)
        }
        
        if weeklyLoss < -config.maxWeeklyLoss {
            alerts.append(RiskAlert(
                type: .weeklyLoss,
                message: "Weekly loss limit exceeded: $\(String(format: "%.2f", abs(weeklyLoss)))",
                severity: .critical,
                timestamp: Date()
            ))
        }
    }
    
    func calculatePortfolioRisk(assets: [AssetItem]) -> Double {
        let totalValue = assets.reduce(0) { $0 + $1.marketValue }
        guard totalValue > 0 else { return 0 }
        
        let totalRisk = assets.reduce(0) { sum, asset in
            let volatility = 0.2 // Default 20% volatility
            return sum + (asset.marketValue * volatility)
        }
        
        return totalRisk / totalValue
    }
    
    func analyzeCorrelation(assets: [AssetItem]) -> [(String, String, Double)] {
        var correlations: [(String, String, Double)] = []
        
        for i in 0..<assets.count {
            for j in (i+1)..<assets.count {
                // Simplified correlation - in production, use historical price data
                // Generate a random correlation for demonstration
                let correlation = Double.random(in: 0.3...0.9)
                
                if correlation > 0.7 {
                    correlations.append((assets[i].symbol, assets[j].symbol, correlation))
                }
            }
        }
        
        return correlations
    }
    
    func clearOldAlerts() {
        let oneDayAgo = Date().addingTimeInterval(-86400)
        alerts.removeAll { $0.timestamp < oneDayAgo }
    }
    
    private func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "risk_config"),
           let loadedConfig = try? JSONDecoder().decode(RiskConfig.self, from: data) {
            self.config = loadedConfig
        }
    }
    
    func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "risk_config")
        }
    }
}
