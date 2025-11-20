import XCTest
import SwiftData
@testable import personalos_ios_v2

final class personalos_ios_v2Tests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([
            TodoItem.self,
            TradeRecord.self,
            HealthLog.self,
            SocialPost.self,
            ProjectItem.self,
            NewsItem.self,
            AssetItem.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - TodoItem Tests
    
    func testTodoItemCreation() {
        let todo = TodoItem(title: "Test Task", category: "Work", priority: 2)
        
        XCTAssertEqual(todo.title, "Test Task")
        XCTAssertEqual(todo.category, "Work")
        XCTAssertEqual(todo.priority, 2)
        XCTAssertFalse(todo.isCompleted)
    }
    
    func testTodoItemPersistence() throws {
        let todo = TodoItem(title: "Persistent Task")
        modelContext.insert(todo)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<TodoItem>()
        let items = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "Persistent Task")
    }
    
    // MARK: - TradeRecord Tests
    
    func testTradeRecordCreation() {
        let trade = TradeRecord(
            symbol: "AAPL",
            type: .buy,
            price: 150.0,
            quantity: 10.0,
            assetType: .stock,
            emotion: .neutral,
            note: "Test trade"
        )
        
        XCTAssertEqual(trade.symbol, "AAPL")
        XCTAssertEqual(trade.type, .buy)
        XCTAssertEqual(trade.price, 150.0)
        XCTAssertEqual(trade.quantity, 10.0)
    }
    
    func testTradeRecordPersistence() throws {
        let trade = TradeRecord(
            symbol: "GOOGL",
            type: .sell,
            price: 140.0,
            quantity: 5.0,
            assetType: .stock,
            emotion: .excited,
            note: ""
        )
        
        modelContext.insert(trade)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<TradeRecord>()
        let trades = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(trades.count, 1)
        XCTAssertEqual(trades.first?.symbol, "GOOGL")
        XCTAssertEqual(trades.first?.type, .sell)
    }
    
    // MARK: - HealthLog Tests
    
    func testHealthLogCreation() {
        let log = HealthLog(sleepHours: 7.5, moodScore: 8, steps: 10000, energyLevel: 75)
        
        XCTAssertEqual(log.sleepHours, 7.5)
        XCTAssertEqual(log.moodScore, 8)
        XCTAssertEqual(log.steps, 10000)
        XCTAssertEqual(log.energyLevel, 75)
    }
    
    // MARK: - AssetItem Tests
    
    func testAssetItemCalculations() {
        let asset = AssetItem(
            symbol: "AAPL",
            name: "Apple Inc.",
            quantity: 10.0,
            currentPrice: 175.0,
            avgCost: 150.0,
            type: .stock
        )
        
        XCTAssertEqual(asset.marketValue, 1750.0)
        XCTAssertEqual(asset.pnl, 250.0)
        XCTAssertEqual(asset.pnlPercent, 0.1666, accuracy: 0.001)
    }
    
    // MARK: - API Config Tests
    
    func testAPIConfigDefaults() {
        XCTAssertFalse(APIConfig.hasValidStockAPIKey)
        XCTAssertFalse(APIConfig.hasValidNewsAPIKey)
    }
}
