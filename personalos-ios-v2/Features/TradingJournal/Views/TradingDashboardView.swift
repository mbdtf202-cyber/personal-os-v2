import SwiftUI
import Charts
import SwiftData

struct TradingDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stockPriceService = StockPriceService()
    
    // ✅ EXTREME OPTIMIZATION 3: 移除 @Query，完全由 ViewModel 管理数据加载
    // 避免 @Query 在 View 初始化时建立观察，防止 10万+ 记录时主线程掉帧
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
                        // ✅ P0 Fix: Data source warning banner
                        if stockPriceService.isUsingMockData {
                            DataSourceWarningBanner(
                                dataSource: "Demo Data",
                                message: "Configure Stock API key in Settings for real-time prices",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange
                            )
                        }
                        
                        if let error = stockPriceService.error, showPriceError {
                            PriceErrorBanner(error: error, onDismiss: { showPriceError = false })
                        }
                        
                        if viewModel.isCalculating {
                            CalculationProgressView(
                                progress: viewModel.calculationProgress,
                                status: viewModel.calculationStatus,
                                onCancel: { viewModel.cancelCalculation() }
                            )
                        }
                        
                        if let error = viewModel.calculationError {
                            ErrorBanner(message: error)
                        }
                        
                        BalanceCard(
                            totalBalance: Double(truncating: viewModel.totalBalance as NSNumber),
                            dayPnL: Double(truncating: viewModel.dayPnL as NSNumber),
                            dayPnLPercent: Double(truncating: viewModel.dayPnLPercent as NSNumber)
                        )
                        TradingStatsGrid(trades: viewModel.recentTrades)
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
                            await viewModel.refreshPrices(for: viewModel.recentTrades)
                            if stockPriceService.error != nil {
                                showPriceError = true
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .disabled(stockPriceService.isLoading || viewModel.isLoadingTrades)
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
        .task {
            // ✅ EXTREME OPTIMIZATION 3: 懒加载数据，避免 View 初始化时的性能开销
            viewModel.setModelContext(modelContext)
            viewModel.priceService = stockPriceService
            
            // 异步加载数据
            await viewModel.loadRecentTrades()
            await viewModel.refreshPrices(for: viewModel.recentTrades)
            
            if stockPriceService.error != nil {
                showPriceError = true
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
                    value: String(format: "$%.2f", Double(truncating: viewModel.dayPnL as NSNumber)),
                    subtitle: String(format: "%.2f%%", Double(truncating: viewModel.dayPnLPercent as NSNumber)),
                    isPositive: viewModel.dayPnL >= 0
                )
                
                MetricBox(
                    title: "Portfolio Value",
                    value: String(format: "$%.2f", Double(truncating: viewModel.totalBalance as NSNumber)),
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
                
                if !viewModel.recentTrades.isEmpty {
                    Text("Last 5")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            if viewModel.isLoadingTrades {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.recentTrades.isEmpty {
                Text("No recent trades. Tap + to log your first trade.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.recentTrades.prefix(5)) { trade in
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
            
            if viewModel.isLoadingTrades {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.assets.isEmpty {
                Text("No assets. Tap + to log a trade.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding()
            } else {
                ForEach(viewModel.assets) { asset in
                    NavigationLink(destination: AssetDetailView(asset: asset, trades: viewModel.recentTrades)) {
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


// MARK: - Calculation Progress View
struct CalculationProgressView: View {
    let progress: Double
    let status: String
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calculating Portfolio")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.caption)
                        .foregroundStyle(AppTheme.coral)
                }
            }
            
            ProgressView(value: progress, total: 1.0)
                .tint(AppTheme.mistBlue)
            
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.coral)
            Text(message)
                .font(.caption)
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
        }
        .padding()
        .background(AppTheme.coral.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Data Source Warning Banner
struct DataSourceWarningBanner: View {
    let dataSource: String
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(dataSource)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .foregroundStyle(color)
                    Text("Not Real-Time")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
