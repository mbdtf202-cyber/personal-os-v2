import SwiftUI
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
    
    var priceService: StockPriceService?
    private let calculator = PortfolioCalculator()
    private var calculationTask: Task<Void, Never>?

    func recalculatePortfolio(from trades: [TradeRecord]) async {
        // Cancel any existing calculation
        calculationTask?.cancel()
        await calculator.resetCancellation()
        
        isCalculating = true
        calculationProgress = 0
        calculationStatus = "Starting calculation..."
        calculationError = nil
        
        calculationTask = Task {
            do {
                let result = try await calculator.calculate(with: trades, priceProvider: { [weak self] symbol, fallback in
                    if let price = self?.priceService?.quotes[symbol]?.price {
                        return Decimal(price)
                    }
                    return Decimal(fallback)
                }, progressCallback: { [weak self] progress, status in
                    Task { @MainActor in
                        self?.calculationProgress = progress
                        self?.calculationStatus = status
                    }
                })
                
                // Update UI on main thread
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    
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


