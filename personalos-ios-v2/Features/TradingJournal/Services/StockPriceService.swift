import Foundation
import Observation

struct StockQuote: Codable {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
}

@MainActor
@Observable
class StockPriceService: StockServiceProtocol {
    var quotes: [String: StockQuote] = [:]
    var isLoading = false
    var error: String?
    
    private let networkClient: NetworkClient
    private let apiKey: String
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
        self.apiKey = AppConfig.API.stockAPIKey
    }
    
    func fetchQuote(symbol: String) async throws -> StockQuote {
        isLoading = true
        defer { isLoading = false }
        
        guard !apiKey.isEmpty else {
            let mockQuote = StockQuote(
                symbol: symbol,
                price: Double.random(in: 100...500),
                change: Double.random(in: -10...10),
                changePercent: Double.random(in: -5...5)
            )
            quotes[symbol] = mockQuote
            return mockQuote
        }
        
        let endpoint = StockEndpoint.quote(symbol: symbol, apiKey: apiKey)
        let quote: StockQuote = try await networkClient.request(endpoint)
        quotes[symbol] = quote
        return quote
    }
    
    func fetchMultipleQuotes(symbols: [String]) async throws -> [StockQuote] {
        var results: [StockQuote] = []
        
        for symbol in symbols {
            do {
                let quote = try await fetchQuote(symbol: symbol)
                results.append(quote)
            } catch {
                Logger.error("Failed to fetch quote for \(symbol): \(error)", category: Logger.network)
            }
        }
        
        return results
    }
    
    func subscribeToRealTimeUpdates(symbols: [String]) async {
        // Implement WebSocket or polling for real-time updates
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                _ = try? await self.fetchMultipleQuotes(symbols: symbols)
            }
        }
    }
}
