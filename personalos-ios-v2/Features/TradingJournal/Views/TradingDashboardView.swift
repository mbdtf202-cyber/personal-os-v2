import SwiftUI
import Charts
import SwiftData // ⚠️ 引入

struct TradingDashboardView: View {
    @State private var viewModel = PortfolioViewModel()
    @State private var showLogForm = false

    // ⚠️ 实时查询数据库
    @Query(sort: \SchemaV1.TradeRecord.date, order: .reverse) var trades: [SchemaV1.TradeRecord]

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
            // ⚠️ 数据驱动：当 trades 变化时重新计算
            .onAppear { viewModel.recalculate(trades: trades) }
            .onChange(of: trades) { _, newValue in
                viewModel.recalculate(trades: newValue)
            }
        }
    }

    // MARK: - Components (保持原有 UI 逻辑不变)

    private var balanceCard: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
            Text("$\(viewModel.totalBalance, specifier: "%.2f")")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }

    private var equityChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Equity Curve")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            Chart {
                ForEach(viewModel.equityCurve) { point in
                    LineMark(x: .value("Day", point.day), y: .value("Value", point.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.almond)
                }
            }
            .frame(height: 200)
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
            ForEach(viewModel.assets) { asset in
                HStack {
                    Image(systemName: asset.type.icon)
                        .font(.title2)
                        .foregroundStyle(AppTheme.primaryText)
                    VStack(alignment: .leading) {
                        Text(asset.symbol)
                            .font(.headline)
                        Text("\(asset.quantity, specifier: "%.2f") shares")
                            .font(.caption)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("$\(asset.marketValue, specifier: "%.2f")")
                            .fontWeight(.bold)
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
        .modelContainer(for: SchemaV1.TradeRecord.self, inMemory: true)
}
