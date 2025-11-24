import XCTest
@testable import personalos_ios_v2

// **Feature: system-architecture-upgrade-p0, Property 40: Data source indicator consistency**
// **Feature: system-architecture-upgrade-p0, Property 41: Statistics source labeling**

@MainActor
final class PriceDataTransparencyTests: XCTestCase {
    
    var priceService: StockPriceService!
    
    override func setUp() async throws {
        try await super.setUp()
        priceService = StockPriceService()
    }
    
    override func tearDown() async throws {
        priceService = nil
        try await super.tearDown()
    }
    
    // MARK: - Property 40: Data source indicator consistency
    
    func testDataSourceIndicatorConsistency() async throws {
        // Property: Data source change should update indicator
        
        // Initially using mock data
        XCTAssertTrue(priceService.isUsingMockData, "Should start with mock data")
        
        // Fetch quotes
        let quotes = try await priceService.fetchMultipleQuotes(symbols: ["AAPL"])
        
        // Verify source is consistent
        let quote = quotes["AAPL"]
        XCTAssertEqual(quote?.source, .mock, "Quote source should match service state")
    }
    
    func testMockDataIndicator() async throws {
        // Property: Mock data should be clearly indicated
        
        priceService.setMockDataMode(true)
        let quotes = try await priceService.fetchMultipleQuotes(symbols: ["AAPL", "GOOGL"])
        
        for (_, quote) in quotes {
            XCTAssertEqual(quote.source, .mock, "All quotes should be marked as mock")
        }
    }
    
    func testDataSourceToggle() {
        // Property: Data source can be toggled
        
        priceService.setMockDataMode(true)
        XCTAssertTrue(priceService.isUsingMockData, "Should be using mock data")
        
        priceService.setMockDataMode(false)
        XCTAssertFalse(priceService.isUsingMockData, "Should not be using mock data")
    }
    
    func testPriceSourceHasMetadata() {
        // Property: Price source should have display metadata
        
        let sources: [PriceSource] = [.realtime, .delayed, .mock]
        
        for source in sources {
            XCTAssertFalse(source.icon.isEmpty, "\(source) should have icon")
            XCTAssertFalse(source.color.isEmpty, "\(source) should have color")
            XCTAssertFalse(source.rawValue.isEmpty, "\(source) should have label")
        }
    }
    
    // MARK: - Property 41: Statistics source labeling
    
    func testStatisticsSourceLabeling() async throws {
        // Property: Statistics should indicate data source
        
        let quotes = try await priceService.fetchMultipleQuotes(symbols: ["AAPL"])
        
        guard let quote = quotes["AAPL"] else {
            XCTFail("Should have quote")
            return
        }
        
        // Verify quote has source information
        XCTAssertNotNil(quote.source, "Quote should have source")
        
        if priceService.isUsingMockData {
            XCTAssertEqual(quote.source, .mock, "Mock data should be labeled")
        }
    }
    
    func testAllQuotesHaveSource() async throws {
        // Property: Every quote should have source information
        
        let symbols = ["AAPL", "GOOGL", "MSFT", "TSLA"]
        let quotes = try await priceService.fetchMultipleQuotes(symbols: symbols)
        
        XCTAssertEqual(quotes.count, symbols.count, "Should have all quotes")
        
        for (symbol, quote) in quotes {
            XCTAssertNotNil(quote.source, "\(symbol) quote should have source")
        }
    }
    
    func testMockDataWarning() {
        // Property: Mock data should have warning indicator
        
        let mockSource = PriceSource.mock
        
        XCTAssertEqual(mockSource.icon, "exclamationmark.triangle.fill", "Mock should have warning icon")
        XCTAssertEqual(mockSource.rawValue, "Demo", "Mock should be labeled as Demo")
    }
    
    func testRealtimeDataIndicator() {
        // Property: Real-time data should have positive indicator
        
        let realtimeSource = PriceSource.realtime
        
        XCTAssertEqual(realtimeSource.icon, "checkmark.circle.fill", "Real-time should have checkmark")
        XCTAssertEqual(realtimeSource.color, "green", "Real-time should be green")
    }
    
    func testDelayedDataIndicator() {
        // Property: Delayed data should have clock indicator
        
        let delayedSource = PriceSource.delayed
        
        XCTAssertEqual(delayedSource.icon, "clock.fill", "Delayed should have clock icon")
        XCTAssertEqual(delayedSource.color, "orange", "Delayed should be orange")
    }
    
    // MARK: - Integration Tests
    
    func testDataSourceConsistencyAcrossMultipleFetches() async throws {
        // Test data source remains consistent
        
        priceService.setMockDataMode(true)
        
        let quotes1 = try await priceService.fetchMultipleQuotes(symbols: ["AAPL"])
        let quotes2 = try await priceService.fetchMultipleQuotes(symbols: ["GOOGL"])
        
        XCTAssertEqual(quotes1["AAPL"]?.source, .mock)
        XCTAssertEqual(quotes2["GOOGL"]?.source, .mock)
    }
    
    func testServiceStateMatchesQuoteSource() async throws {
        // Test service state matches quote source
        
        let quotes = try await priceService.fetchMultipleQuotes(symbols: ["AAPL"])
        
        if priceService.isUsingMockData {
            XCTAssertEqual(quotes["AAPL"]?.source, .mock, "Service state should match quote source")
        } else {
            XCTAssertNotEqual(quotes["AAPL"]?.source, .mock, "Service state should match quote source")
        }
    }
}
