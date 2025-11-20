import SwiftUI
import Charts
import SwiftData

struct TradingDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StockPriceService.self) private var stockPriceService
    @Query(sort: \TradeRecord.date, order: .reverse) private var allTrades: [TradeRecord]
    
    private var recentTrades: [TradeRecord] {
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        return allTrades.filter { $0.date > ninetyDaysAgo }
    }
    @State private var viewModel = PortfolioViewModel()
    @State private var showLogForm = false
    @State private var showPriceError = false
    @State private var showAllHistory = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Price Error Banner
                        if let error = stockPriceService.error, showPriceError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppTheme.coral)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Price Update Failed")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                Spacer()
                                Button(action: { showPriceError = false }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(AppTheme.tertiaryText)
                                }
                            }
                            .padding()
                            .background(AppTheme.coral.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        balanceCard
                        tradingStatsGrid
                        equityChart
                        performanceMetrics
                        holdingsList
                        recentTradesSection
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Trading Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await viewModel.refreshPrices(for: recentTrades)
                            if stockPriceService.error != nil {
                                showPriceError = true
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .disabled(stockPriceService.isLoading)
                    .accessibilityLabel("Refresh Prices")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showLogForm = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.almond)
                    }
                    .accessibilityLabel("Log Trade")
                }
            }
            .sheet(isPresented: $showLogForm) {
                TradeLogForm()
            }
            .sheet(isPresented: $showAllHistory) {
                TradeHistoryListView()
            }
        }
        .onChange(of: recentTrades) { _, newTrades in
            viewModel.recalculatePortfolio(from: newTrades)
        }
        .onAppear {
            viewModel.priceService = stockPriceService
            viewModel.recalculatePortfolio(from: recentTrades)
            Task {
                await viewModel.refreshPrices(for: recentTrades)
                if stockPriceService.error != nil {
                    showPriceError = true
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var balanceCard: some View {
        let isPositive = viewModel.dayPnL >= 0

        return VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
            Text("$\(viewModel.totalBalance, specifier: "%.2f")")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
            HStack {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                Text("\(isPositive ? "+" : "-")$\(abs(viewModel.dayPnL), specifier: "%.2f") (\(abs(viewModel.dayPnLPercent), specifier: "%.2f")%)")
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(isPositive ? AppTheme.matcha : AppTheme.coral)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background((isPositive ? AppTheme.matcha : AppTheme.coral).opacity(0.15))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var equityChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Equity Curve (7D)")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            
            if viewModel.equityCurve.isEmpty {
                Text("Log trades to view your equity curve.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            } else {
                Chart {
                    ForEach(viewModel.equityCurve) { point in
                        LineMark(
                            x: .value("Day", point.day),
                            y: .value("Value", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.almond)
                        .symbol(Circle())

                        AreaMark(
                            x: .value("Day", point.day),
                            y: .value("Value", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.almond.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var tradingStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickStatCard(
                title: "Total Trades",
                value: "\(recentTrades.count)",
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
        guard !recentTrades.isEmpty else { return "0%" }
        let profitableTrades = recentTrades.filter { trade in
            // Simple heuristic: buy at lower price, sell at higher
            return trade.type == .sell
        }.count
        let rate = Double(profitableTrades) / Double(recentTrades.count) * 100
        return String(format: "%.1f%%", rate)
    }
    
    private var avgTradeSize: String {
        guard !recentTrades.isEmpty else { return "$0" }
        let total = recentTrades.reduce(0.0) { $0 + ($1.price * $1.quantity) }
        let avg = total / Double(recentTrades.count)
        return String(format: "$%.0f", avg)
    }
    
    private var bestTrade: String {
        guard !recentTrades.isEmpty else { return "$0" }
        let maxValue = recentTrades.map { $0.price * $0.quantity }.max() ?? 0
        return String(format: "$%.0f", maxValue)
    }
    
    private var performanceMetrics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            
            HStack(spacing: 16) {
                MetricBox(
                    title: "Total P&L",
                    value: String(format: "$%.2f", viewModel.dayPnL),
                    subtitle: String(format: "%.2f%%", viewModel.dayPnLPercent),
                    isPositive: viewModel.dayPnL >= 0
                )
                
                MetricBox(
                    title: "Portfolio Value",
                    value: String(format: "$%.2f", viewModel.totalBalance),
                    subtitle: "\(viewModel.assets.count) assets",
                    isPositive: true
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var recentTradesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Trades")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                
                Spacer()
                
                if !recentTrades.isEmpty {
                    Text("Last 5")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            if recentTrades.isEmpty {
                Text("No recent trades. Tap + to log your first trade.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentTrades.prefix(5)) { trade in
                    RecentTradeRow(trade: trade)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var holdingsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Holdings")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                
                Spacer()
                
                Button(action: { showAllHistory = true }) {
                    HStack(spacing: 4) {
                        Text("All History")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                    }
                    .foregroundStyle(AppTheme.mistBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.mistBlue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            if viewModel.assets.isEmpty {
                Text("No assets. Tap + to log a trade.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding()
            } else {
                ForEach(viewModel.assets) { asset in
                    NavigationLink(destination: AssetDetailView(asset: asset, trades: recentTrades)) {
                        HStack(spacing: 12) {
                            Image(systemName: asset.type.icon)
                                .font(.title2)
                                .foregroundStyle(AppTheme.primaryText)
                                .frame(width: 48, height: 48)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: AppTheme.shadow, radius: 4, y: 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(asset.symbol)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)
                                Text("\(asset.quantity, specifier: "%.2f") shares")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$\(asset.marketValue, specifier: "%.2f")")
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.primaryText)
                                HStack(spacing: 4) {
                                    Image(systemName: asset.pnl >= 0 ? "arrow.up" : "arrow.down")
                                    Text("\(abs(asset.pnlPercent * 100), specifier: "%.2f")%")
                                }
                                .font(.caption)
                                .foregroundStyle(asset.pnl >= 0 ? AppTheme.matcha : AppTheme.coral)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.primaryText)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: AppTheme.shadow, radius: 4, y: 2)
    }
}

struct MetricBox: View {
    let title: String
    let value: String
    let subtitle: String
    var isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(isPositive ? AppTheme.matcha : AppTheme.coral)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: AppTheme.shadow, radius: 4, y: 2)
    }
}

struct RecentTradeRow: View {
    let trade: TradeRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Type Badge
            ZStack {
                Circle()
                    .fill(trade.type == .buy ? AppTheme.matcha.opacity(0.15) : AppTheme.coral.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: trade.type == .buy ? "arrow.down" : "arrow.up")
                    .font(.caption)
                    .foregroundStyle(trade.type == .buy ? AppTheme.matcha : AppTheme.coral)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                
                HStack(spacing: 4) {
                    Text(trade.type.rawValue)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("•")
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text(trade.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(trade.price * trade.quantity, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                Text("\(trade.quantity, specifier: "%.2f") @ $\(trade.price, specifier: "%.2f")")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: AppTheme.shadow, radius: 3, y: 1)
    }
}

#Preview {
    TradingDashboardView()
        .modelContainer(for: TradeRecord.self, inMemory: true)
}
