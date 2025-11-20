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
    
    // MARK: - AppRouter Tests
    
    @MainActor
    func testAppRouterNavigation() {
        let router = AppRouter()
        
        XCTAssertEqual(router.selectedTab, .dashboard)
        
        router.navigate(to: .trading)
        XCTAssertEqual(router.selectedTab, .trading)
        
        router.navigate(to: .health)
        XCTAssertEqual(router.selectedTab, .health)
    }
    
    @MainActor
    func testAppRouterGlobalSearch() {
        let router = AppRouter()
        
        XCTAssertFalse(router.showGlobalSearch)
        
        router.toggleGlobalSearch()
        XCTAssertTrue(router.showGlobalSearch)
        
        router.toggleGlobalSearch()
        XCTAssertFalse(router.showGlobalSearch)
    }
    
    // MARK: - SocialPost Tests
    
    func testSocialPostCreation() {
        let post = SocialPost(
            title: "Test Post",
            platform: .twitter,
            status: .draft,
            date: Date(),
            content: "Test content",
            views: 0,
            likes: 0
        )
        
        XCTAssertEqual(post.title, "Test Post")
        XCTAssertEqual(post.platform, .twitter)
        XCTAssertEqual(post.status, .draft)
        XCTAssertEqual(post.content, "Test content")
    }
    
    func testSocialPostPersistence() throws {
        let post = SocialPost(
            title: "Persistent Post",
            platform: .blog,
            status: .published,
            date: Date(),
            content: "Content",
            views: 100,
            likes: 10
        )
        
        modelContext.insert(post)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<SocialPost>()
        let posts = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(posts.count, 1)
        XCTAssertEqual(posts.first?.title, "Persistent Post")
        XCTAssertEqual(posts.first?.views, 100)
    }
    
    // MARK: - ProjectItem Tests
    
    func testProjectItemCreation() {
        let project = ProjectItem(
            name: "Test Project",
            details: "Test details",
            language: "Swift",
            stars: 100,
            status: .active,
            progress: 0.5
        )
        
        XCTAssertEqual(project.name, "Test Project")
        XCTAssertEqual(project.language, "Swift")
        XCTAssertEqual(project.stars, 100)
        XCTAssertEqual(project.status, .active)
        XCTAssertEqual(project.progress, 0.5)
    }
    
    // MARK: - NewsItem Tests
    
    func testNewsItemCreation() {
        let news = NewsItem(
            source: "Test Source",
            title: "Test News",
            summary: "Test summary",
            category: "Tech",
            image: "newspaper",
            date: Date()
        )
        
        XCTAssertEqual(news.source, "Test Source")
        XCTAssertEqual(news.title, "Test News")
        XCTAssertEqual(news.category, "Tech")
    }
    
    // MARK: - Enum Tests
    
    func testTradeTypeEnum() {
        XCTAssertEqual(TradeType.buy.rawValue, "Buy")
        XCTAssertEqual(TradeType.sell.rawValue, "Sell")
    }
    
    func testTradeEmotionEnum() {
        XCTAssertEqual(TradeEmotion.excited.rawValue, "Excited")
        XCTAssertEqual(TradeEmotion.fearful.rawValue, "Fearful")
        XCTAssertEqual(TradeEmotion.neutral.rawValue, "Neutral")
        XCTAssertEqual(TradeEmotion.revenge.rawValue, "Revenge")
    }
    
    func testAssetTypeEnum() {
        XCTAssertEqual(AssetType.stock.label, "Stock")
        XCTAssertEqual(AssetType.crypto.label, "Crypto")
        XCTAssertEqual(AssetType.forex.label, "Forex")
        
        XCTAssertEqual(AssetType.stock.icon, "building.columns.fill")
        XCTAssertEqual(AssetType.crypto.icon, "bitcoinsign.circle.fill")
        XCTAssertEqual(AssetType.forex.icon, "dollarsign.arrow.circlepath")
    }
    
    func testProjectStatusEnum() {
        XCTAssertEqual(ProjectStatus.active.rawValue, "Active")
        XCTAssertEqual(ProjectStatus.idea.rawValue, "Idea")
        XCTAssertEqual(ProjectStatus.done.rawValue, "Done")
    }
    
    func testPostStatusEnum() {
        XCTAssertEqual(PostStatus.idea.rawValue, "Idea")
        XCTAssertEqual(PostStatus.draft.rawValue, "Draft")
        XCTAssertEqual(PostStatus.scheduled.rawValue, "Scheduled")
        XCTAssertEqual(PostStatus.published.rawValue, "Published")
    }
    
    func testSocialPlatformEnum() {
        XCTAssertEqual(SocialPlatform.xiaohongshu.rawValue, "RedBook")
        XCTAssertEqual(SocialPlatform.twitter.rawValue, "X")
        XCTAssertEqual(SocialPlatform.wechat.rawValue, "WeChat")
        XCTAssertEqual(SocialPlatform.blog.rawValue, "Blog")
    }
}
