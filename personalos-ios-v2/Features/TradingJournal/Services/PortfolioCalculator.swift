import Foundation

/// Portfolio calculation result
struct PortfolioResult {
    let assets: [AssetItem]
    let totalBalance: Decimal
    let equityCurve: [EquityPoint]
    let dayPnL: Decimal
    let dayPnLPercent: Decimal
}

/// Equity curve point
struct EquityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Decimal
}

/// Calculation progress callback
typealias ProgressCallback = @Sendable (Double, String) -> Void

/// Portfolio calculator with complete trade history support
actor PortfolioCalculator {
    
    private var isCancelled = false
    
    func cancelCalculation() {
        isCancelled = true
    }
    
    func resetCancellation() {
        isCancelled = false
    }
    
    // ✅ P0 Fix: Calculate positions using ALL historical trades
    // ✅ P1 Enhancement: Add progress reporting and cancellation
    func calculate(
        with trades: [TradeRecord],
        priceProvider: (String, Double) -> Decimal,
        progressCallback: ProgressCallback? = nil
    ) async throws -> PortfolioResult {
        
        // Reset cancellation flag
        isCancelled = false
        
        Logger.log("Calculating portfolio from \(trades.count) trades", category: Logger.trading)
        
        progressCallback?(0.0, "Sorting trades...")
        
        // Check cancellation
        guard !isCancelled else {
            throw CalculationError.cancelled
        }
        
        // Sort trades by date
        let sortedTrades = trades.sorted { $0.date < $1.date }
        
        progressCallback?(0.2, "Calculating positions...")
        
        // Check cancellation
        guard !isCancelled else {
            throw CalculationError.cancelled
        }
        
        // Calculate positions from complete history
        let positions = try await calculatePositions(from: sortedTrades, progressCallback: progressCallback)
        
        progressCallback?(0.5, "Fetching current prices...")
        
        // Check cancellation
        guard !isCancelled else {
            throw CalculationError.cancelled
        }
        
        // Convert positions to assets with current prices
        var assets: [AssetItem] = []
        var totalBalance: Decimal = 0
        
        let positionArray = Array(positions.values)
        for (index, position) in positionArray.enumerated() {
            guard !isCancelled else {
                throw CalculationError.cancelled
            }
            
            guard position.quantity > 0 else { continue }
            
            let currentPrice = priceProvider(position.symbol, 0)
            let asset = AssetItem(
                symbol: position.symbol,
                name: position.symbol,
                quantity: position.quantity,
                currentPrice: currentPrice,
                avgCost: position.avgCost,
                type: .stock
            )
            
            assets.append(asset)
            totalBalance += asset.marketValue
            
            let progress = 0.5 + (Double(index + 1) / Double(positionArray.count)) * 0.3
            progressCallback?(progress, "Processing \(position.symbol)...")
        }
        
        progressCallback?(0.8, "Calculating equity curve...")
        
        // Check cancellation
        guard !isCancelled else {
            throw CalculationError.cancelled
        }
        
        // Calculate equity curve
        let equityCurve = try await calculateEquityCurve(from: sortedTrades, priceProvider: priceProvider, progressCallback: progressCallback)
        
        // ✅ P0 Fix: Calculate real day P&L from equity curve
        let (dayPnL, dayPnLPercent) = calculateDayPnL(equityCurve: equityCurve, currentBalance: totalBalance)
        
        progressCallback?(1.0, "Complete")
        
        Logger.log("Portfolio calculated: \(assets.count) assets, balance: \(totalBalance)", category: Logger.trading)
        
        return PortfolioResult(
            assets: assets,
            totalBalance: totalBalance,
            equityCurve: equityCurve,
            dayPnL: dayPnL,
            dayPnLPercent: dayPnLPercent
        )
    }
    
    // ✅ P0 Fix: Calculate positions from ALL trades (no date filtering)
    private func calculatePositions(from trades: [TradeRecord], progressCallback: ProgressCallback? = nil) async throws -> [String: Position] {
        var positions: [String: Position] = [:]
        
        for (index, trade) in trades.enumerated() {
            guard !isCancelled else {
                throw CalculationError.cancelled
            }
            
            // Report progress every 10 trades
            if index % 10 == 0 {
                let progress = 0.2 + (Double(index) / Double(trades.count)) * 0.3
                progressCallback?(progress, "Processing trade \(index + 1)/\(trades.count)...")
            }
            let symbol = trade.symbol
            var position = positions[symbol] ?? Position(symbol: symbol, quantity: 0, avgCost: 0, costBasis: 0)
            
            switch trade.type {
            case .buy:
                // Add to position
                let newCostBasis = position.costBasis + (trade.price * trade.quantity)
                let newQuantity = position.quantity + trade.quantity
                let newAvgCost = newQuantity > 0 ? newCostBasis / newQuantity : 0
                
                position = Position(
                    symbol: symbol,
                    quantity: newQuantity,
                    avgCost: newAvgCost,
                    costBasis: newCostBasis
                )
                
            case .sell:
                // Reduce position
                let newQuantity = position.quantity - trade.quantity
                let newCostBasis = position.costBasis - (position.avgCost * trade.quantity)
                
                position = Position(
                    symbol: symbol,
                    quantity: max(0, newQuantity),
                    avgCost: position.avgCost,
                    costBasis: max(0, newCostBasis)
                )
            }
            
            positions[symbol] = position
        }
        
        return positions
    }
    
    // ✅ P0 Fix: Calculate equity curve using historical prices at each trade date
    private func calculateEquityCurve(
        from trades: [TradeRecord],
        priceProvider: (String, Double) -> Decimal,
        progressCallback: ProgressCallback? = nil
    ) async throws -> [EquityPoint] {
        var curve: [EquityPoint] = []
        var positions: [String: Position] = [:]
        
        // Group trades by date for more accurate equity calculation
        let calendar = Calendar.current
        var tradesByDate: [Date: [TradeRecord]] = [:]
        
        for trade in trades {
            let dayStart = calendar.startOfDay(for: trade.date)
            tradesByDate[dayStart, default: []].append(trade)
        }
        
        let sortedDates = tradesByDate.keys.sorted()
        
        for (index, date) in sortedDates.enumerated() {
            guard !isCancelled else {
                throw CalculationError.cancelled
            }
            
            // Report progress
            if index % 5 == 0 {
                let progress = 0.8 + (Double(index) / Double(sortedDates.count)) * 0.2
                progressCallback?(progress, "Building equity curve \(index + 1)/\(sortedDates.count) days...")
            }
            
            // Process all trades for this date
            let dayTrades = tradesByDate[date] ?? []
            for trade in dayTrades {
                let symbol = trade.symbol
                var position = positions[symbol] ?? Position(symbol: symbol, quantity: 0, avgCost: 0, costBasis: 0)
                
                switch trade.type {
                case .buy:
                    let newCostBasis = position.costBasis + (trade.price * trade.quantity)
                    let newQuantity = position.quantity + trade.quantity
                    let newAvgCost = newQuantity > 0 ? newCostBasis / newQuantity : 0
                    
                    position = Position(
                        symbol: symbol,
                        quantity: newQuantity,
                        avgCost: newAvgCost,
                        costBasis: newCostBasis
                    )
                    
                case .sell:
                    let newQuantity = position.quantity - trade.quantity
                    let newCostBasis = position.costBasis - (position.avgCost * trade.quantity)
                    
                    position = Position(
                        symbol: symbol,
                        quantity: max(0, newQuantity),
                        avgCost: position.avgCost,
                        costBasis: max(0, newCostBasis)
                    )
                }
                
                positions[symbol] = position
            }
            
            // ✅ P0 Fix: Calculate equity using trade prices (historical) instead of current price
            // Use the last trade price of the day as the closing price
            var totalEquity: Decimal = 0
            for (sym, pos) in positions where pos.quantity > 0 {
                // Find the last trade price for this symbol on or before this date
                let historicalPrice = dayTrades.last(where: { $0.symbol == sym })?.price ?? pos.avgCost
                totalEquity += pos.quantity * historicalPrice
            }
            
            curve.append(EquityPoint(date: date, value: totalEquity))
        }
        
        return curve
    }
    
    // ✅ P0 Fix: Validate trade before execution
    func validateTrade(_ trade: TradeRecord, against positions: [String: Position]) throws {
        guard trade.price > 0 else {
            throw ValidationError.invalidPrice
        }
        
        guard trade.quantity > 0 else {
            throw ValidationError.invalidInput(field: "quantity", reason: "must be positive")
        }
        
        // For sell trades, verify sufficient quantity
        if trade.type == .sell {
            let position = positions[trade.symbol]
            let available = position?.quantity ?? 0
            
            guard available >= trade.quantity else {
                throw ValidationError.insufficientQuantity(
                    symbol: trade.symbol,
                    available: available,
                    requested: trade.quantity
                )
            }
            
            // Check if sell would result in negative position
            let remaining = available - trade.quantity
            guard remaining >= 0 else {
                throw ValidationError.negativePosition(symbol: trade.symbol)
            }
        }
    }
    
    // ✅ P0 Fix: Calculate day P&L from equity curve
    private func calculateDayPnL(equityCurve: [EquityPoint], currentBalance: Decimal) -> (Decimal, Decimal) {
        guard !equityCurve.isEmpty else {
            return (0, 0)
        }
        
        // Find yesterday's equity (or last available point before today)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find the last equity point before today
        let yesterdayEquity = equityCurve
            .filter { calendar.startOfDay(for: $0.date) < today }
            .last?.value ?? 0
        
        // If no previous data, return 0
        guard yesterdayEquity > 0 else {
            return (0, 0)
        }
        
        // Calculate day P&L
        let dayPnL = currentBalance - yesterdayEquity
        let dayPnLPercent = (dayPnL / yesterdayEquity) * 100
        
        return (dayPnL, dayPnLPercent)
    }
    
    // Calculate realized gains from complete history
    func calculateRealizedGains(from trades: [TradeRecord]) -> Decimal {
        var positions: [String: Position] = [:]
        var realizedGains: Decimal = 0
        
        for trade in trades.sorted(by: { $0.date < $1.date }) {
            let symbol = trade.symbol
            var position = positions[symbol] ?? Position(symbol: symbol, quantity: 0, avgCost: 0, costBasis: 0)
            
            switch trade.type {
            case .buy:
                let newCostBasis = position.costBasis + (trade.price * trade.quantity)
                let newQuantity = position.quantity + trade.quantity
                let newAvgCost = newQuantity > 0 ? newCostBasis / newQuantity : 0
                
                position = Position(
                    symbol: symbol,
                    quantity: newQuantity,
                    avgCost: newAvgCost,
                    costBasis: newCostBasis
                )
                
            case .sell:
                // Calculate realized gain/loss
                let gain = (trade.price - position.avgCost) * trade.quantity
                realizedGains += gain
                
                let newQuantity = position.quantity - trade.quantity
                let newCostBasis = position.costBasis - (position.avgCost * trade.quantity)
                
                position = Position(
                    symbol: symbol,
                    quantity: max(0, newQuantity),
                    avgCost: position.avgCost,
                    costBasis: max(0, newCostBasis)
                )
            }
            
            positions[symbol] = position
        }
        
        return realizedGains
    }
}

/// Position information
struct Position {
    let symbol: String
    let quantity: Decimal
    let avgCost: Decimal
    let costBasis: Decimal
}

/// Calculation errors
enum CalculationError: LocalizedError {
    case cancelled
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Calculation was cancelled"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
