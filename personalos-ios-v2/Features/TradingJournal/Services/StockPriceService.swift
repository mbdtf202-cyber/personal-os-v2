import Foundation

struct StockQuote: Codable {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
}

@MainActor
class StockPriceService: ObservableObject {
    @Published var quotes: [String: StockQuote] = [:]
    @Published var isLoading = false
    
    // Using Alpha Vantage API - Get free key at https://www.alphavantage.co/support/#api-key
    private let apiKey = "YOUR_API_KEY_HERE" // TODO: Replace with real key
    
    func fetchQuote(symbol: String) async {
        isLoading = true
        
        guard let url = URL(string: "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=\(symbol)&apikey=\(apiKey)") else {
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
            }
            
            isLoading = false
        } catch {
            print("Failed to fetch quote for \(symbol): \(error)")
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
