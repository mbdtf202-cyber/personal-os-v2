import Foundation
import Observation

@Observable
@MainActor
class StockPriceService {
    var quotes: [String: StockQuote] = [:]
    var isLoading = false
    var error: String?
    var lastUpdateTime: Date?
    
    // ✅ P0 Fix: Track data source
    private(set) var isUsingMockData: Bool = true
    
    // ✅ P1 Enhancement: Cache and throttling
    private var priceCache: [String: CachedQuote] = [:]
    private let cacheExpiration: TimeInterval = 60 // 60 seconds
    private var lastFetchTime: Date?
    private let throttleInterval: TimeInterval = 5 // 5 seconds minimum between fetches
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0
    
    func fetchMultipleQuotes(symbols: [String]) async throws -> [String: StockQuote] {
        // Check throttle
        if let lastFetch = lastFetchTime, Date().timeIntervalSince(lastFetch) < throttleInterval {
            Logger.log("Request throttled, using cached data", category: Logger.trading)
            return getCachedQuotes(for: symbols)
        }
        
        // Check cache first
        let cachedQuotes = getCachedQuotes(for: symbols)
        if cachedQuotes.count == symbols.count {
            Logger.log("Using cached quotes for all \(symbols.count) symbols", category: Logger.trading)
            return cachedQuotes
        }
        
        // Determine which symbols need fresh data
        let symbolsToFetch = symbols.filter { symbol in
            guard let cached = priceCache[symbol] else { return true }
            return Date().timeIntervalSince(cached.timestamp) > cacheExpiration
        }
        
        if symbolsToFetch.isEmpty {
            return cachedQuotes
        }
        
        isLoading = true
        error = nil
        
        do {
            let newQuotes = try await fetchWithRetry(symbols: symbolsToFetch)
            
            // Update cache
            for (symbol, quote) in newQuotes {
                priceCache[symbol] = CachedQuote(quote: quote, timestamp: Date())
            }
            
            // Merge with cached quotes
            var allQuotes = cachedQuotes
            allQuotes.merge(newQuotes) { _, new in new }
            
            quotes = allQuotes
            lastFetchTime = Date()
            lastUpdateTime = Date()
            isLoading = false
            
            Logger.log("Fetched quotes for \(symbolsToFetch.count) symbols (source: \(isUsingMockData ? "mock" : "real"))", category: Logger.trading)
            
            return allQuotes
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            throw error
        }
    }
    
    private func fetchWithRetry(symbols: [String]) async throws -> [String: StockQuote] {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await performFetch(symbols: symbols)
            } catch {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    Logger.log("Fetch failed, retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries))", category: Logger.trading)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NSError(domain: "StockPriceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch quotes"])
    }
    
    private func performFetch(symbols: [String]) async throws -> [String: StockQuote] {
        // ✅ P0 Fix: Allow real API in any environment if key is configured
        let hasAPIKey = RemoteConfigService.shared.getAPIKey(for: "stock") != nil
        
        // Use real API if key is configured (regardless of environment)
        if hasAPIKey {
            isUsingMockData = false
            Logger.log("📊 Using REAL price data (API configured)", category: Logger.trading)
            return try await fetchRealPrices(symbols: symbols)
        } else {
            isUsingMockData = true
            Logger.log("⚠️ Using MOCK price data (No API key configured)", category: Logger.trading)
            return try await fetchMockPrices(symbols: symbols)
        }
    }
    
    private func fetchRealPrices(symbols: [String]) async throws -> [String: StockQuote] {
        // ✅ P0 Fix: Implement real API call or explicitly fail
        // TODO: Implement actual stock price API integration (e.g., Alpha Vantage, IEX Cloud, Polygon.io)
        // For now, explicitly mark as unimplemented and use mock data
        
        Logger.warning("⚠️ Real-time stock API not implemented yet. Using demo data.", category: Logger.trading)
        isUsingMockData = true
        error = "⚠️ Real-time price API not yet implemented. Showing demo data for illustration only. Real API integration coming soon."
        
        // Return mock data with clear source labeling
        return try await fetchMockPrices(symbols: symbols)
        
        /* TODO: Implement real API integration like this:
        guard let apiKey = RemoteConfigService.shared.getAPIKey(for: "stock") else {
            throw NSError(domain: "StockPriceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No API key configured"])
        }
        
        var quotes: [String: StockQuote] = [:]
        for symbol in symbols {
            let endpoint = "https://api.example.com/quote/\(symbol)?apikey=\(apiKey)"
            let response: StockAPIResponse = try await NetworkClient.stocks.request(endpoint)
            quotes[symbol] = StockQuote(
                symbol: symbol,
                price: response.price,
                change: response.change,
                changePercent: response.changePercent,
                source: .realtime,
                timestamp: Date()
            )
        }
        return quotes
        */
    }
    
    private func fetchMockPrices(symbols: [String]) async throws -> [String: StockQuote] {
        // Batch fetch - process in chunks of 10
        let batchSize = 10
        var allQuotes: [String: StockQuote] = [:]
        
        for i in stride(from: 0, to: symbols.count, by: batchSize) {
            let endIndex = min(i + batchSize, symbols.count)
            let batch = Array(symbols[i..<endIndex])
            
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延迟模拟网络请求
            
            for symbol in batch {
                // 生成模拟价格
                let basePrice = Double.random(in: 50...500)
                allQuotes[symbol] = StockQuote(
                    symbol: symbol,
                    price: basePrice,
                    change: Double.random(in: -10...10),
                    changePercent: Double.random(in: -5...5),
                    source: .mock,
                    timestamp: Date()
                )
            }
        }
        
        return allQuotes
    }
    
    private func getCachedQuotes(for symbols: [String]) -> [String: StockQuote] {
        var cachedQuotes: [String: StockQuote] = [:]
        
        for symbol in symbols {
            if let cached = priceCache[symbol],
               Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
                cachedQuotes[symbol] = cached.quote
            }
        }
        
        return cachedQuotes
    }
    
    func clearCache() {
        priceCache.removeAll()
        Logger.log("Price cache cleared", category: Logger.trading)
    }
    
    /// Toggle between mock and real data (for testing)
    func setMockDataMode(_ useMock: Bool) {
        isUsingMockData = useMock
        Logger.log("Stock price data source set to: \(useMock ? "mock" : "real")", category: Logger.trading)
    }
}

struct StockQuote {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let source: PriceSource
    let timestamp: Date
    
    init(symbol: String, price: Double, change: Double, changePercent: Double, source: PriceSource = .mock, timestamp: Date = Date()) {
        self.symbol = symbol
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.source = source
        self.timestamp = timestamp
    }
}

/// Cached quote with timestamp
struct CachedQuote {
    let quote: StockQuote
    let timestamp: Date
}

/// Price data source
enum PriceSource: String {
    case realtime = "Real-time"
    case delayed = "Delayed"
    case mock = "Demo"
    
    var icon: String {
        switch self {
        case .realtime:
            return "checkmark.circle.fill"
        case .delayed:
            return "clock.fill"
        case .mock:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .realtime:
            return "green"
        case .delayed:
            return "orange"
        case .mock:
            return "yellow"
        }
    }
}
