import Foundation
import Observation

@Observable
@MainActor
class StockPriceService {
    var quotes: [String: StockQuote] = [:]
    var isLoading = false
    var error: String?
    
    func fetchMultipleQuotes(symbols: [String]) async throws -> [String: StockQuote] {
        isLoading = true
        error = nil
        
        // TODO: 实现真实的股票价格 API 调用
        // 目前返回模拟数据
        
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒延迟模拟网络请求
        
        var newQuotes: [String: StockQuote] = [:]
        for symbol in symbols {
            // 生成模拟价格
            let basePrice = Double.random(in: 50...500)
            newQuotes[symbol] = StockQuote(
                symbol: symbol,
                price: basePrice,
                change: Double.random(in: -10...10),
                changePercent: Double.random(in: -5...5)
            )
        }
        
        quotes = newQuotes
        isLoading = false
        return newQuotes
    }
}

struct StockQuote {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
}
