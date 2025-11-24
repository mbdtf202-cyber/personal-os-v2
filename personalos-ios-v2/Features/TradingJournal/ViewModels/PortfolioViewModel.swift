import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
class PortfolioViewModel {
    var totalBalance: Decimal = 0
    var dayPnL: Decimal = 0
    var dayPnLPercent: Decimal = 0
    var assets: [AssetItem] = []
    var equityCurve: [EquityPoint] = []
    var isCalculating = false
    var calculationProgress: Double = 0
    var calculationStatus: String = ""
    var calculationError: String?
    
    // ✅ EXTREME OPTIMIZATION 3: 将数据加载移入 ViewModel，避免 @Query 在 View 层触发
    var recentTrades: [TradeRecord] = []
    var isLoadingTrades = false
    
    var priceService: StockPriceService?
    private let calculator = PortfolioCalculator()
    private var calculationTask: Task<Void, Never>?
    private var modelContext: ModelContext?
    
    /// 设置 ModelContext（从 View 传入）
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// 加载最近 90 天的交易记录（懒加载）
    func loadRecentTrades() async {
        guard let context = modelContext else {
            Logger.error("ModelContext not set in PortfolioViewModel", category: Logger.trading)
            return
        }
        
        isLoadingTrades = true
        
        // 在后台线程执行数据库查询
        let trades = await Task.detached(priority: .userInitiated) {
            let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            
            let descriptor = FetchDescriptor<TradeRecord>(
                predicate: #Predicate { trade in
                    trade.date > ninetyDaysAgo
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            do {
                return try context.fetch(descriptor)
            } catch {
                Logger.error("Failed to fetch trades: \(error)", category: Logger.trading)
                return []
            }
        }.value
        
        await MainActor.run {
            self.recentTrades = trades
            self.isLoadingTrades = false
            Logger.log("Loaded \(trades.count) recent trades", category: Logger.trading)
        }
        
        // 自动触发计算
        await recalculatePortfolio(from: trades)
    }

    func recalculatePortfolio(from trades: [TradeRecord]) async {
        // ✅ FINAL OPTIMIZATION 2: 严密的 Task 取消检查，防止数据竞争
        // Cancel any existing calculation
        calculationTask?.cancel()
        await calculator.resetCancellation()
        
        isCalculating = true
        calculationProgress = 0
        calculationStatus = "Starting calculation..."
        calculationError = nil
        
        calculationTask = Task {
            // ✅ 检查 1: 开始前检查取消状态
            guard !Task.isCancelled else {
                await MainActor.run {
                    self.isCalculating = false
                    self.calculationStatus = "Cancelled before start"
                }
                return
            }
            
            do {
                let result = try await calculator.calculate(with: trades, priceProvider: { [weak self] symbol, fallback in
                    if let price = self?.priceService?.quotes[symbol]?.price {
                        return Decimal(price)
                    }
                    return Decimal(fallback)
                }, progressCallback: { [weak self] progress, status in
                    Task { @MainActor in
                        // ✅ 检查 2: 进度回调中检查取消状态
                        guard !Task.isCancelled else { return }
                        self?.calculationProgress = progress
                        self?.calculationStatus = status
                    }
                })
                
                // ✅ 检查 3: 计算完成后、更新 UI 前检查取消状态
                guard !Task.isCancelled else {
                    await MainActor.run {
                        self.isCalculating = false
                        self.calculationStatus = "Cancelled after calculation"
                        Logger.log("Portfolio calculation cancelled after completion", category: Logger.trading)
                    }
                    return
                }
                
                // Update UI on main thread
                await MainActor.run {
                    // ✅ 检查 4: MainActor 上下文中再次检查（双重保险）
                    guard !Task.isCancelled else {
                        self.isCalculating = false
                        self.calculationStatus = "Cancelled before UI update"
                        return
                    }
                    
                    self.assets = result.assets
                    self.totalBalance = result.totalBalance
                    self.equityCurve = result.equityCurve
                    self.dayPnL = result.dayPnL
                    self.dayPnLPercent = result.dayPnLPercent
                    self.isCalculating = false
                    self.calculationProgress = 1.0
                    self.calculationStatus = "Complete"
                    
                    Logger.log("Portfolio calculation completed successfully", category: Logger.trading)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.isCalculating = false
                    self.calculationStatus = "Cancelled"
                    Logger.log("Portfolio calculation cancelled", category: Logger.trading)
                }
            } catch {
                // ✅ 检查 5: 错误处理中也检查取消状态
                guard !Task.isCancelled else {
                    await MainActor.run {
                        self.isCalculating = false
                        self.calculationStatus = "Cancelled during error handling"
                    }
                    return
                }
                
                await MainActor.run {
                    self.isCalculating = false
                    self.calculationError = error.localizedDescription
                    self.calculationStatus = "Error"
                    ErrorHandler.shared.handle(error, context: "PortfolioViewModel.recalculatePortfolio")
                }
            }
        }
    }
    
    func cancelCalculation() {
        calculationTask?.cancel()
        Task {
            await calculator.cancelCalculation()
        }
    }

    func refreshPrices(for trades: [TradeRecord]) async {
        guard let priceService = priceService else { return }
        let symbols = Array(Set(trades.map { $0.symbol }))
        do {
            _ = try await priceService.fetchMultipleQuotes(symbols: symbols)
            await recalculatePortfolio(from: trades)
        } catch {
            Logger.error("Failed to refresh prices: \(error)", category: Logger.trading)
        }
    }
}


