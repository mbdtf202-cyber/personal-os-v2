import SwiftUI
import Charts
import SwiftData

struct TradingDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StockPriceService.self) private var stockPriceService
    @Query(sort: \TradeRecord.date, order: .reverse) private var trades: [TradeRecord]
    @State private var viewModel = PortfolioViewModel()
    @State private var showLogForm = false
    @State private var showPriceError = false

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
                        equityChart
                        holdingsList
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
                            await viewModel.refreshPrices(for: trades)
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
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showLogForm = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.almond)
                    }
                }
            }
            .sheet(isPresented: $showLogForm) {
                TradeLogForm()
            }
        }
        .onChange(of: trades) { _, newTrades in
            viewModel.recalculatePortfolio(from: newTrades)
        }
        .onAppear {
            viewModel.priceService = stockPriceService
            viewModel.recalculatePortfolio(from: trades)
            Task {
                await viewModel.refreshPrices(for: trades)
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
    
    private var holdingsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Holdings")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            
            if viewModel.assets.isEmpty {
                Text("No assets. Tap + to log a trade.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding()
            } else {
                ForEach(viewModel.assets) { asset in
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
            }
        }
    }
}

#Preview {
    TradingDashboardView()
        .modelContainer(for: TradeRecord.self, inMemory: true)
}
