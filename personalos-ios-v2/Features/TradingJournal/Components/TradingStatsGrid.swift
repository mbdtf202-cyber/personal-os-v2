import SwiftUI

struct TradingStatsGrid: View {
    let trades: [TradeRecord]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickStatCard(
                title: "Total Trades",
                value: "\(trades.count)",
                icon: "chart.bar.fill",
                color: AppTheme.mistBlue
            )
            
            QuickStatCard(
                title: "Win Rate",
                value: winRate,
                icon: "target",
                color: AppTheme.matcha
            )
            
            QuickStatCard(
                title: "Avg Trade",
                value: avgTradeSize,
                icon: "dollarsign.circle.fill",
                color: AppTheme.almond
            )
            
            QuickStatCard(
                title: "Best Trade",
                value: bestTrade,
                icon: "arrow.up.circle.fill",
                color: AppTheme.matcha
            )
        }
    }
    
    private var winRate: String {
        guard !trades.isEmpty else { return "0%" }
        let profitableTrades = trades.filter { $0.type == .sell }.count
        let rate = Double(profitableTrades) / Double(trades.count) * 100
        return String(format: "%.1f%%", rate)
    }
    
    private var avgTradeSize: String {
        guard !trades.isEmpty else { return "$0" }
        let total = trades.reduce(0.0) { $0 + ($1.price * $1.quantity) }
        let avg = total / Double(trades.count)
        return String(format: "$%.0f", avg)
    }
    
    private var bestTrade: String {
        guard !trades.isEmpty else { return "$0" }
        let maxValue = trades.map { $0.price * $0.quantity }.max() ?? 0
        return String(format: "$%.0f", maxValue)
    }
}
