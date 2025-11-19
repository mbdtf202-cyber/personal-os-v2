import SwiftUI
import Charts

struct TradingDashboardView: View {
    @State private var viewModel = PortfolioViewModel()
    @State private var showLogForm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
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
    }
    
    // MARK: - Components
    
    private var balanceCard: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
            Text("$\(viewModel.totalBalance, specifier: "%.2f")")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
            HStack {
                Image(systemName: "arrow.up.right")
                Text("+\(viewModel.dayPnL, specifier: "%.2f") (\(viewModel.dayPnLPercent, specifier: "%.2f")%)")
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.matcha)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppTheme.matcha.opacity(0.15))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }
    
    private var equityChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Equity Curve (7D)")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            
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
        .glassCard()
    }
    
    private var holdingsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Holdings")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            
            ForEach(viewModel.assets) { asset in
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: asset.type.icon)
                        .font(.title2)
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(width: 48, height: 48)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: AppTheme.shadow, radius: 4, y: 2)
                    
                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(asset.symbol)
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Text("\(asset.quantity, specifier: "%.2f") shares")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // PnL
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

#Preview {
    TradingDashboardView()
}
