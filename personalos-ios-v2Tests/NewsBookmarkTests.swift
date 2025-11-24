import XCTest
import SwiftData
@testable import personalos_ios_v2

/// ✅ P0 Task 18.1: News Bookmark Stable ID Property Tests
/// Tests Requirements 16.1-16.5: Stable identifiers, bookmark matching, persistence, accuracy, duplicate prevention
@MainActor
final class NewsBookmarkTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: NewsItem.self, configurations: config)
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - Property 65: Stable identifier usage
    /// Requirement 16.1: NewsItems must have stable canonical IDs
    func testProperty65_StableIdentifierUsage() {
        // Given: NewsItems with URLs
        let item1 = NewsItem(
            source: "TechCrunch",
            title: "Test Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article1")
        )
        
        let item2 = NewsItem(
            source: "TechCrunch",
            title: "Test Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article1")
        )
        
        // Then: Items with same URL have same canonical ID
        XCTAssertEqual(item1.canonicalID, item2.canonicalID, "Same URL should produce same canonical ID")
        XCTAssertEqual(item1.canonicalID, "https://example.com/article1", "Canonical ID should be URL")
        
        // Property: URL serves as stable identifier across app sessions
    }
    
    // MARK: - Property 66: Bookmark matching consistency
    /// Requirement 16.2: Bookmarks should match by canonical ID, not UUID
    func testProperty66_BookmarkMatchingConsistency() {
        // Given: Two NewsItems representing the same article
        let item1 = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article")
        )
        
        let item2 = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article")
        )
        
        // Then: UUIDs are different but canonical IDs match
        XCTAssertNotEqual(item1.id, item2.id, "UUIDs should be different")
        XCTAssertEqual(item1.canonicalID, item2.canonicalID, "Canonical IDs should match")
        XCTAssertTrue(item1.matches(item2), "Items should match by canonical ID")
        
        // Property: Bookmark matching uses canonical ID for consistency
    }
    
    // MARK: - Property 67: Stable identifier persistence
    /// Requirement 16.3: Canonical IDs persist across app restarts
    func testProperty67_StableIdentifierPersistence() throws {
        // Given: A NewsItem with URL
        let originalItem = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article")
        )
        
        let originalCanonicalID = originalItem.canonicalID
        
        // When: Item is saved and retrieved
        modelContext.insert(originalItem)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<NewsItem>()
        let fetchedItems = try modelContext.fetch(fetchDescriptor)
        
        // Then: Canonical ID is preserved
        XCTAssertEqual(fetchedItems.count, 1)
        XCTAssertEqual(fetchedItems.first?.canonicalID, originalCanonicalID)
        
        // Property: Canonical IDs survive persistence round-trip
    }
    
    // MARK: - Property 68: Bookmark status accuracy
    /// Requirement 16.4: Bookmark status reflects actual saved state
    func testProperty68_BookmarkStatusAccuracy() throws {
        // Given: A NewsItem
        let item = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article")
        )
        
        // When: Item is bookmarked
        modelContext.insert(item)
        try modelContext.save()
        
        // Then: Can find bookmark by canonical ID
        let fetchDescriptor = FetchDescriptor<NewsItem>(
            predicate: #Predicate { $0.canonicalID == item.canonicalID }
        )
        let bookmarkedItems = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(bookmarkedItems.count, 1, "Should find bookmarked item")
        XCTAssertEqual(bookmarkedItems.first?.canonicalID, item.canonicalID)
        
        // Property: Bookmark status can be accurately determined using canonical ID
    }
    
    // MARK: - Property 69: Task duplicate prevention
    /// Requirement 16.5: Prevent duplicate tasks for same article
    func testProperty69_TaskDuplicatePrevention() {
        // Given: Multiple NewsItems with same canonical ID
        let item1 = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article")
        )
        
        let item2 = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article")
        )
        
        // Then: Can detect duplicates
        XCTAssertTrue(item1.matches(item2), "Should detect same article")
        
        // Property: Canonical ID enables duplicate detection for task creation
    }
    
    // MARK: - Edge Cases
    func testCanonicalIDWithoutURL() {
        // Given: NewsItem without URL
        let item = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: nil
        )
        
        // Then: Canonical ID is generated from title+source
        XCTAssertNotNil(item.canonicalID)
        XCTAssertFalse(item.canonicalID.isEmpty)
        
        // Property: Items without URLs still get stable canonical IDs
    }
    
    func testCanonicalIDConsistencyWithoutURL() {
        // Given: Two items with same title and source, no URL
        let item1 = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary 1",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: nil
        )
        
        let item2 = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary 2",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: nil
        )
        
        // Then: Canonical IDs match despite different summaries
        XCTAssertEqual(item1.canonicalID, item2.canonicalID)
        
        // Property: Hash-based canonical IDs are consistent for same title+source
    }
    
    func testExplicitCanonicalID() {
        // Given: NewsItem with explicit canonical ID
        let customID = "custom-id-123"
        let item = NewsItem(
            source: "Source",
            title: "Article",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article"),
            canonicalID: customID
        )
        
        // Then: Custom canonical ID is used
        XCTAssertEqual(item.canonicalID, customID)
        
        // Property: Explicit canonical IDs can be provided when needed
    }
    
    func testBookmarkRemovalByCanonicalID() throws {
        // Given: Multiple bookmarks
        let item1 = NewsItem(
            source: "Source1",
            title: "Article1",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article1")
        )
        
        let item2 = NewsItem(
            source: "Source2",
            title: "Article2",
            summary: "Summary",
            category: "Tech",
            image: "newspaper",
            date: Date(),
            url: URL(string: "https://example.com/article2")
        )
        
        modelContext.insert(item1)
        modelContext.insert(item2)
        try modelContext.save()
        
        // When: Removing one bookmark by canonical ID
        let targetCanonicalID = item1.canonicalID
        let fetchDescriptor = FetchDescriptor<NewsItem>(
            predicate: #Predicate { $0.canonicalID == targetCanonicalID }
        )
        let itemsToDelete = try modelContext.fetch(fetchDescriptor)
        
        for item in itemsToDelete {
            modelContext.delete(item)
        }
        try modelContext.save()
        
        // Then: Only targeted bookmark is removed
        let allItems = try modelContext.fetch(FetchDescriptor<NewsItem>())
        XCTAssertEqual(allItems.count, 1)
        XCTAssertEqual(allItems.first?.canonicalID, item2.canonicalID)
        
        // Property: Bookmarks can be precisely removed using canonical ID
    }
}
