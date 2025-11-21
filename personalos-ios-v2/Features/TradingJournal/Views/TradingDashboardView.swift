import SwiftUI
import Charts
import SwiftData

struct TradingDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StockPriceService.self) private var stockPriceService
    
    // ✅ P0 Fix: 数据库级过滤，避免内存遍历 10,000+ 条记录
    // 使用静态计算的日期，让 SwiftData 在 SQLite 层面过滤
    private static var ninetyDaysAgo: Date {
        Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
    }
    
    @Query(
        filter: #Predicate<TradeRecord> { trade in
            trade.date > TradingDashboardView.ninetyDaysAgo
        },
        sort: \TradeRecord.date,
        order: .reverse
    ) private var recentTrades: [TradeRecord]
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
                        if let error = stockPriceService.error, showPriceError {
                            PriceErrorBanner(error: error, onDismiss: { showPriceError = false })
                        }
                        
                        BalanceCard(
                            totalBalance: viewModel.totalBalance,
                            dayPnL: viewModel.dayPnL,
                            dayPnLPercent: viewModel.dayPnLPercent
                        )
                        TradingStatsGrid(trades: recentTrades)
                        EquityChart(equityCurve: viewModel.equityCurve)
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
