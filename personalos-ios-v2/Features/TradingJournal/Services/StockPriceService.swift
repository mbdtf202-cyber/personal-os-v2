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
class StockPriceService {
    var quotes: [String: StockQuote] = [:]
    var isLoading = false
    var error: String?
    
    private var apiKey: String {
        APIConfig.stockAPIKey
    }
    
    func fetchQuote(symbol: String) async {
        isLoading = true
        error = nil
        
        // Use mock data if API key not configured
        guard APIConfig.hasValidStockAPIKey else {
            quotes[symbol] = StockQuote(
                symbol: symbol,
                price: getMockPrice(for: symbol),
                change: Double.random(in: -5...5),
                changePercent: Double.random(in: -2...2)
            )
            Logger.debug("Stock API key not configured, using mock data for \(symbol)", category: .trading)
            isLoading = false
            return
        }
        
        guard let url = URL(string: "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=\(symbol)&apikey=\(apiKey)") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let globalQuote = json["Global Quote"] as? [String: String],
               let priceStr = globalQuote["05. price"],
               let price = Double(priceStr),
               let changeStr = globalQuote["09. change"],
               let change = Double(changeStr),
               let changePercentStr = globalQuote["10. change percent"]?.replacingOccurrences(of: "%", with: ""),
               let changePercent = Double(changePercentStr) {
                
                let quote = StockQuote(symbol: symbol, price: price, change: change, changePercent: changePercent)
                quotes[symbol] = quote
                Logger.log("Successfully fetched quote for \(symbol): $\(price)", category: .trading)
            } else {
                error = "Failed to parse stock data"
                Logger.error("Failed to parse stock data for \(symbol)", category: .trading)
            }
            
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to fetch quote for \(symbol): \(error.localizedDescription)", category: .trading)
            isLoading = false
        }
    }
    
    func fetchMultipleQuotes(symbols: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for symbol in symbols {
                group.addTask {
                    await self.fetchQuote(symbol: symbol)
                }
            }
        }
    }
    
    // Fallback: Use mock data if API key not configured
    func getMockPrice(for symbol: String, fallback: Double? = nil) -> Double {
        let mockPrices: [String: Double] = [
            "AAPL": 175.50,
            "GOOGL": 140.25,
            "MSFT": 380.00,
            "TSLA": 245.80,
            "BTC": 42000.00,
            "ETH": 2200.00
        ]
        return mockPrices[symbol] ?? fallback ?? 100.0
    }
}
