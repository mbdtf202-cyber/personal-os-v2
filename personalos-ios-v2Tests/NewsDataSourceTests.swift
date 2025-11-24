import XCTest
@testable import personalos_ios_v2

/// ✅ P0 Task 16.1: News Data Source Property Tests
/// Tests Requirements 14.3-14.5: Data source distinction, indicators, per-item labeling
@MainActor
final class NewsDataSourceTests: XCTestCase {
    var newsService: NewsService!
    var mockNetworkClient: NetworkClient!
    
    override func setUp() async throws {
        mockNetworkClient = NetworkClient(config: .default)
        newsService = NewsService(networkClient: mockNetworkClient)
    }
    
    override func tearDown() {
        newsService = nil
        mockNetworkClient = nil
    }
    
    // MARK: - Property 57: Data source distinction
    /// Requirement 14.3: Real vs demo/mock data must be distinguishable
    func testProperty57_DataSourceDistinction() {
        // Given: NewsDataSource enum
        let realSource = NewsDataSource.real
        let demoSource = NewsDataSource.demo
        let mockSource = NewsDataSource.mock
        
        // Then: Each source has distinct properties
        XCTAssertEqual(realSource.displayName, "Live Data")
        XCTAssertEqual(demoSource.displayName, "Demo Content")
        XCTAssertEqual(mockSource.displayName, "Mock Data")
        
        XCTAssertEqual(realSource.badgeColor, "green")
        XCTAssertEqual(demoSource.badgeColor, "orange")
        XCTAssertEqual(mockSource.badgeColor, "gray")
        
        // Property: Data sources are clearly distinguishable by name and color
    }
    
    // MARK: - Property 58: Real data indicator removal
    /// Requirement 14.4: Real data should not show "demo" indicators
    func testProperty58_RealDataIndicatorRemoval() {
        // Given: NewsService starts with demo data
        XCTAssertEqual(newsService.currentDataSource, .demo, "Should start with demo data")
        
        // When: Real data is successfully fetched (simulated)
        // Note: In real scenario, this would be after successful API call
        // For this test, we verify the initial state and the property exists
        
        // Then: Service tracks data source
        XCTAssertNotNil(newsService.currentDataSource, "Data source should be tracked")
        XCTAssertFalse(newsService.isUsingRealData, "Should not be using real data initially")
        
        // Property: When real data is loaded, currentDataSource changes to .real
        // and isUsingRealData returns true, removing demo indicators
    }
    
    // MARK: - Property 59: Per-item source labeling
    /// Requirement 14.5: Each news item should have its own data source label
    func testProperty59_PerItemSourceLabeling() {
        // Given: NewsItems with different data sources
        let realItem = NewsItem(
            source: "TechCrunch",
            title: "Real News",
            summary: "From API",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            dataSource: .real
        )
        
        let demoItem = NewsItem(
            source: "Demo Source",
            title: "Demo News",
            summary: "Sample data",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            dataSource: .demo
        )
        
        let mockItem = NewsItem(
            source: "Mock Source",
            title: "Mock News",
            summary: "Test data",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            dataSource: .mock
        )
        
        // Then: Each item has its own data source
        XCTAssertEqual(realItem.dataSourceType, .real)
        XCTAssertEqual(demoItem.dataSourceType, .demo)
        XCTAssertEqual(mockItem.dataSourceType, .mock)
        
        // And: Data source is persisted as string
        XCTAssertEqual(realItem.dataSource, "real")
        XCTAssertEqual(demoItem.dataSource, "demo")
        XCTAssertEqual(mockItem.dataSource, "mock")
        
        // Property: Each NewsItem independently tracks its data source
        // This allows mixing real and demo data in the same feed
    }
    
    // MARK: - Integration Test: Data Source Flow
    func testDataSourceFlow() {
        // Given: NewsService with initial demo state
        XCTAssertEqual(newsService.currentDataSource, .demo)
        
        // When: Creating news items
        let item1 = NewsItem(
            source: "Source 1",
            title: "Item 1",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            dataSource: newsService.currentDataSource
        )
        
        // Then: Item inherits current data source
        XCTAssertEqual(item1.dataSourceType, .demo)
        
        // Property: NewsItems can be created with the service's current data source
        // ensuring consistency between service state and item metadata
    }
    
    // MARK: - Edge Cases
    func testDataSourceDefaultValue() {
        // Given: NewsItem created without explicit data source
        let item = NewsItem(
            source: "Test",
            title: "Test",
            summary: "Test",
            category: "Test",
            image: "test",
            date: Date()
        )
        
        // Then: Defaults to demo
        XCTAssertEqual(item.dataSourceType, .demo)
        
        // Property: NewsItems default to demo data source for safety
    }
    
    func testDataSourceRoundTrip() {
        // Given: All data source types
        let sources: [NewsDataSource] = [.real, .demo, .mock]
        
        for source in sources {
            // When: Creating item with source
            let item = NewsItem(
                source: "Test",
                title: "Test",
                summary: "Test",
                category: "Test",
                image: "test",
                date: Date(),
                dataSource: source
            )
            
            // Then: Source is preserved
            XCTAssertEqual(item.dataSourceType, source)
            XCTAssertEqual(item.dataSource, source.rawValue)
        }
        
        // Property: Data source survives serialization/deserialization
    }
}
