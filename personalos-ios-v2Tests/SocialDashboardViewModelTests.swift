import XCTest
import SwiftData
@testable import personalos_ios_v2

@MainActor
final class SocialDashboardViewModelTests: XCTestCase {
    var modelContext: ModelContext!
    var repository: SocialPostRepository!
    var viewModel: SocialDashboardViewModel!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SocialPost.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        repository = SocialPostRepository(modelContext: modelContext)
        viewModel = SocialDashboardViewModel(socialPostRepository: repository)
    }
    
    override func tearDown() {
        modelContext = nil
        repository = nil
        viewModel = nil
    }
    
    // MARK: - calculateStats Tests
    
    func testCalculateStats_EmptyPosts() {
        let stats = viewModel.calculateStats(from: [])
        
        XCTAssertEqual(stats.totalViews, "0")
        XCTAssertEqual(stats.engagementRate, "0%")
    }
    
    func testCalculateStats_WithViews() {
        let posts = [
            SocialPost(title: "Post 1", platform: .twitter, status: .published, date: Date(), content: "", views: 1000, likes: 50),
            SocialPost(title: "Post 2", platform: .twitter, status: .published, date: Date(), content: "", views: 500, likes: 25)
        ]
        
        let stats = viewModel.calculateStats(from: posts)
        
        XCTAssertEqual(stats.totalViews, "1.5K")
        XCTAssertEqual(stats.engagementRate, "5.0%")
    }
    
    func testCalculateStats_LessThan1000Views() {
        let posts = [
            SocialPost(title: "Post 1", platform: .twitter, status: .published, date: Date(), content: "", views: 500, likes: 25)
        ]
        
        let stats = viewModel.calculateStats(from: posts)
        
        XCTAssertEqual(stats.totalViews, "500")
        XCTAssertEqual(stats.engagementRate, "5.0%")
    }
    
    func testCalculateStats_ZeroEngagement() {
        let posts = [
            SocialPost(title: "Post 1", platform: .twitter, status: .published, date: Date(), content: "", views: 1000, likes: 0)
        ]
        
        let stats = viewModel.calculateStats(from: posts)
        
        XCTAssertEqual(stats.totalViews, "1.0K")
        XCTAssertEqual(stats.engagementRate, "0.0%")
    }
    
    // MARK: - filterPosts Tests
    
    func testFilterPosts_ByStatus() {
        let posts = [
            SocialPost(title: "Draft", platform: .twitter, status: .draft, date: Date(), content: "", views: 0, likes: 0),
            SocialPost(title: "Published", platform: .twitter, status: .published, date: Date(), content: "", views: 100, likes: 10),
            SocialPost(title: "Idea", platform: .twitter, status: .idea, date: Date(), content: "", views: 0, likes: 0)
        ]
        
        let drafts = viewModel.filterPosts(posts, by: .draft)
        let published = viewModel.filterPosts(posts, by: .published)
        
        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts.first?.title, "Draft")
        XCTAssertEqual(published.count, 1)
        XCTAssertEqual(published.first?.title, "Published")
    }
    
    func testFilterPosts_ByDate() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let posts = [
            SocialPost(title: "Today", platform: .twitter, status: .published, date: today, content: "", views: 100, likes: 10),
            SocialPost(title: "Yesterday", platform: .twitter, status: .published, date: yesterday, content: "", views: 50, likes: 5)
        ]
        
        let todayPosts = viewModel.filterPosts(posts, by: .published, date: today)
        
        XCTAssertEqual(todayPosts.count, 1)
        XCTAssertEqual(todayPosts.first?.title, "Today")
    }
    
    // MARK: - savePost Tests
    
    func testSavePost_Success() async {
        let post = SocialPost(title: "Test", platform: .twitter, status: .draft, date: Date(), content: "Test content", views: 0, likes: 0)
        
        await viewModel.savePost(post)
        
        let savedPosts = try? await repository.fetch()
        XCTAssertEqual(savedPosts?.count, 1)
        XCTAssertEqual(savedPosts?.first?.title, "Test")
    }
    
    // MARK: - deletePost Tests
    
    func testDeletePost_Success() async {
        let post = SocialPost(title: "Test", platform: .twitter, status: .draft, date: Date(), content: "Test content", views: 0, likes: 0)
        try? await repository.save(post)
        
        await viewModel.deletePost(post)
        
        let remainingPosts = try? await repository.fetch()
        XCTAssertEqual(remainingPosts?.count, 0)
    }
    
    // MARK: - changePostStatus Tests
    
    func testChangePostStatus() async {
        let post = SocialPost(title: "Test", platform: .twitter, status: .draft, date: Date(), content: "Test content", views: 0, likes: 0)
        try? await repository.save(post)
        
        await viewModel.changePostStatus(post, to: .published)
        
        XCTAssertEqual(post.status, .published)
    }
}
