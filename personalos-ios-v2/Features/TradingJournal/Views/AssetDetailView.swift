import SwiftUI
import Charts

struct AssetDetailView: View {
    let asset: AssetItem
    let trades: [TradeRecord]
    
    private var assetTrades: [TradeRecord] {
        trades.filter { $0.symbol == asset.symbol }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: asset.type.icon)
                            .font(.largeTitle)
                            .foregroundStyle(AppTheme.primaryText)
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: AppTheme.shadow, radius: 4, y: 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.symbol)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.primaryText)
                            Text(asset.type.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatItem(title: "Quantity", value: "\(asset.quantity, specifier: "%.2f")")
                        StatItem(title: "Avg Cost", value: "$\(asset.avgCost, specifier: "%.2f")")
                        StatItem(title: "Market Value", value: "$\(asset.marketValue, specifier: "%.2f")")
                        StatItem(title: "P&L", value: "$\(asset.pnl, specifier: "%.2f")", color: asset.pnl >= 0 ? AppTheme.matcha : AppTheme.coral)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                
                // Trade History
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trade History")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    
                    if assetTrades.isEmpty {
                        Text("No trades found")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(assetTrades) { trade in
                            TradeHistoryRow(trade: trade)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(asset.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    var color: Color = AppTheme.primaryText
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TradeHistoryRow: View {
    let trade: TradeRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(trade.type.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(trade.type == .buy ? AppTheme.matcha.opacity(0.2) : AppTheme.coral.opacity(0.2))
                        .foregroundStyle(trade.type == .buy ? AppTheme.matcha : AppTheme.coral)
                        .cornerRadius(6)
                    
                    Text(trade.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Text("\(trade.quantity, specifier: "%.2f") @ $\(trade.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText)
            }
            
            Spacer()
            
            Text("$\(trade.price * trade.quantity, specifier: "%.2f")")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: AppTheme.shadow, radius: 3, y: 1)
    }
}

#Preview {
    NavigationStack {
        AssetDetailView(
            asset: AssetItem(
                symbol: "AAPL",
                name: "Apple Inc.",
                quantity: 10,
                currentPrice: 175,
                avgCost: 150,
                type: .stock
            ),
            trades: []
        )
    }
}
