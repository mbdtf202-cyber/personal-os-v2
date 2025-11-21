import SwiftUI
import SwiftData

struct TradeHistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query(sort: \TradeRecord.date, order: .reverse) private var allTrades: [TradeRecord]
    
    @State private var searchText = ""
    @State private var selectedFilter: TradeFilter = .all
    
    enum TradeFilter: String, CaseIterable {
        case all = "All"
        case buy = "Buy"
        case sell = "Sell"
    }
    
    private var filteredTrades: [TradeRecord] {
        var trades = allTrades
        
        // Filter by type
        if selectedFilter != .all {
            trades = trades.filter { $0.type.rawValue.lowercased() == selectedFilter.rawValue.lowercased() }
        }
        
        // Search filter
        if !searchText.isEmpty {
            trades = trades.filter { 
                $0.symbol.localizedCaseInsensitiveContains(searchText) ||
                $0.note.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return trades
    }
    
    private var totalTrades: Int {
        allTrades.count
    }
    
    private var totalVolume: Double {
        allTrades.reduce(0) { $0 + ($1.quantity * $1.price) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Stats Header
                    HStack(spacing: 16) {
                        StatCard(title: "Total Trades", value: "\(totalTrades)", color: AppTheme.mistBlue)
                        StatCard(title: "Volume", value: "$\(Int(totalVolume/1000))K", color: AppTheme.almond)
                    }
                    .padding()
                    
                    // Filter Picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(TradeFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Trade List
                    if filteredTrades.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 60))
                                .foregroundStyle(AppTheme.tertiaryText)
                            Text(searchText.isEmpty ? "No trades found" : "No results for '\(searchText)'")
                                .font(.headline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(groupedByMonth, id: \.key) { month, trades in
                                Section(header: Text(month).font(.headline)) {
                                    ForEach(trades) { trade in
                                        TradeHistoryRow(trade: trade)
                                            .listRowBackground(Color.clear)
                                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    deleteTrade(trade)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Trade History")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search by symbol or notes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var groupedByMonth: [(key: String, value: [TradeRecord])] {
        let grouped = Dictionary(grouping: filteredTrades) { trade in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: trade.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func deleteTrade(_ trade: TradeRecord) {
        Task {
            do {
                try await RepositoryContainer.shared.tradeRepository.delete(trade)
                HapticsManager.shared.success()
            } catch {
                ErrorHandler.shared.handle(error, context: "TradeHistoryListView.deleteTrade")
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.primaryText)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct TradeHistoryRow: View {
    let trade: TradeRecord
    
    private var tradeValue: Double {
        trade.quantity * trade.price
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Type Indicator
            ZStack {
                Circle()
                    .fill(trade.type == .buy ? AppTheme.matcha.opacity(0.1) : AppTheme.coral.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: trade.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundStyle(trade.type == .buy ? AppTheme.matcha : AppTheme.coral)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.symbol)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                
                HStack(spacing: 8) {
                    Text("\(Int(trade.quantity)) @ $\(String(format: "%.2f", trade.price))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    if !trade.note.isEmpty {
                        Text("•")
                            .foregroundStyle(AppTheme.tertiaryText)
                        Text(trade.note)
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", tradeValue))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                
                Text(trade.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: AppTheme.shadow, radius: 3, y: 1)
    }
}

#Preview {
    let container = try! ModelContainer(for: TradeRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    // Add sample data
    let trades = [
        TradeRecord(symbol: "AAPL", type: .buy, price: 175.50, quantity: 10, assetType: .stock, emotion: .neutral, note: "Strong earnings", date: Date()),
        TradeRecord(symbol: "TSLA", type: .sell, price: 245.30, quantity: 5, assetType: .stock, emotion: .excited, note: "Taking profits", date: Date().addingTimeInterval(-86400 * 30)),
        TradeRecord(symbol: "NVDA", type: .buy, price: 450.00, quantity: 15, assetType: .stock, emotion: .excited, note: "AI boom", date: Date().addingTimeInterval(-86400 * 60)),
    ]
    trades.forEach { container.mainContext.insert($0) }
    
    return TradeHistoryListView()
        .modelContainer(container)
}
