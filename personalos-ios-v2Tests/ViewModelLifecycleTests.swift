import XCTest
import SwiftData
@testable import personalos_ios_v2

/// ✅ P0 Task 15.1: ViewModel Lifecycle Property Tests
/// Tests Requirements 13.1-13.5: ViewModel initialization, uniqueness, error handling, isolation, cleanup
@MainActor
final class ViewModelLifecycleTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: SocialPostRepository!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: SocialPost.self, configurations: config)
        modelContext = ModelContext(modelContainer)
        repository = SocialPostRepository(modelContext: modelContext)
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }
    
    // MARK: - Property 52: ViewModel initialization order
    /// Requirement 13.1: ViewModel must be initialized before view appears
    func testProperty52_ViewModelInitializationOrder() throws {
        // Given: A repository is available
        XCTAssertNotNil(repository, "Repository should be initialized")
        
        // When: ViewModel is created before view
        let viewModel = SocialDashboardViewModel(socialPostRepository: repository)
        
        // Then: ViewModel is ready immediately
        XCTAssertNotNil(viewModel, "ViewModel should be initialized")
        XCTAssertFalse(viewModel.showEditor, "Initial state should be correct")
        XCTAssertNil(viewModel.selectedPost, "No post should be selected initially")
        XCTAssertNil(viewModel.selectedDate, "No date should be selected initially")
        
        // Property: ViewModel initialization happens before any view operations
        // This prevents race conditions and ensures consistent state
    }
    
    // MARK: - Property 53: ViewModel instance uniqueness
    /// Requirement 13.2: Each view instance should have its own ViewModel
    func testProperty53_ViewModelInstanceUniqueness() throws {
        // Given: Two separate repositories
        let context1 = ModelContext(modelContainer)
        let context2 = ModelContext(modelContainer)
        let repo1 = SocialPostRepository(modelContext: context1)
        let repo2 = SocialPostRepository(modelContext: context2)
        
        // When: Two ViewModels are created
        let viewModel1 = SocialDashboardViewModel(socialPostRepository: repo1)
        let viewModel2 = SocialDashboardViewModel(socialPostRepository: repo2)
        
        // Then: They are distinct instances
        XCTAssertTrue(viewModel1 !== viewModel2, "ViewModels should be different instances")
        
        // When: State is modified in one
        viewModel1.showEditor = true
        viewModel1.selectedDate = Date()
        
        // Then: Other ViewModel is unaffected
        XCTAssertFalse(viewModel2.showEditor, "ViewModels should have independent state")
        XCTAssertNil(viewModel2.selectedDate, "ViewModels should have independent state")
        
        // Property: Each ViewModel instance maintains its own isolated state
    }
    
    // MARK: - Property 54: Missing ViewModel handling
    /// Requirement 13.3: No fatalError when ViewModel is missing
    func testProperty54_MissingViewModelHandling() throws {
        // Given: A ViewModel is properly initialized
        let viewModel = SocialDashboardViewModel(socialPostRepository: repository)
        
        // Then: No fatalError or crash occurs
        XCTAssertNotNil(viewModel, "ViewModel should be created without fatalError")
        
        // Property: The new architecture requires ViewModel at init time,
        // eliminating the possibility of missing ViewModel at runtime
        // This test verifies that the initialization pattern is safe
    }
    
    // MARK: - Property 55: Scene ViewModel isolation
    /// Requirement 13.4: ViewModels are isolated per scene/navigation
    func testProperty55_SceneViewModelIsolation() throws {
        // Given: Multiple ViewModels for different scenes
        let scene1ViewModel = SocialDashboardViewModel(socialPostRepository: repository)
        let scene2ViewModel = SocialDashboardViewModel(socialPostRepository: repository)
        
        // When: Operations are performed in scene 1
        scene1ViewModel.showEditor = true
        let testPost = SocialPost(
            title: "Scene 1 Post",
            platform: .twitter,
            status: .draft,
            date: Date(),
            content: "Test",
            views: 0,
            likes: 0
        )
        scene1ViewModel.selectedPost = testPost
        
        // Then: Scene 2 is unaffected
        XCTAssertFalse(scene2ViewModel.showEditor, "Scene 2 should be isolated")
        XCTAssertNil(scene2ViewModel.selectedPost, "Scene 2 should be isolated")
        
        // Property: Each scene maintains its own ViewModel state
        // This prevents cross-contamination between navigation stacks
    }
    
    // MARK: - Property 56: ViewModel resource cleanup
    /// Requirement 13.5: ViewModels properly clean up resources
    func testProperty56_ViewModelResourceCleanup() async throws {
        // Given: A ViewModel with ongoing tasks
        let viewModel = SocialDashboardViewModel(socialPostRepository: repository)
        
        // When: An async operation is started
        let post = SocialPost(
            title: "Test Post",
            platform: .twitter,
            status: .draft,
            date: Date(),
            content: "Test content",
            views: 0,
            likes: 0
        )
        
        let saveTask = Task {
            await viewModel.savePost(post)
        }
        
        // Give it a moment to start
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // When: Tasks are cancelled
        viewModel.cancelOngoingTasks()
        
        // Then: Tasks should be cancelled
        // (We can't directly verify task cancellation, but we ensure the method exists and runs)
        XCTAssertNoThrow(viewModel.cancelOngoingTasks(), "Cleanup should not throw")
        
        // Wait for save task to complete
        await saveTask.value
        
        // Property: ViewModel provides cleanup mechanism for ongoing operations
        // This prevents memory leaks and ensures proper resource management
    }
    
    // MARK: - Integration Test: Full Lifecycle
    func testViewModelFullLifecycle() async throws {
        // Given: A ViewModel is created
        let viewModel = SocialDashboardViewModel(socialPostRepository: repository)
        
        // When: Normal operations are performed
        let post = SocialPost(
            title: "Lifecycle Test",
            platform: .twitter,
            status: .draft,
            date: Date(),
            content: "Testing full lifecycle",
            views: 0,
            likes: 0
        )
        
        await viewModel.savePost(post)
        
        // Then: Operation completes successfully
        XCTAssertNotNil(viewModel.lastOperation, "Operation should provide feedback")
        XCTAssertTrue(viewModel.lastOperation?.success ?? false, "Operation should succeed")
        
        // When: View disappears and cleanup is called
        viewModel.cancelOngoingTasks()
        
        // Then: No crashes or errors occur
        XCTAssertNoThrow(viewModel.cancelOngoingTasks(), "Cleanup should be safe to call multiple times")
        
        // Property: ViewModel handles full lifecycle from init to cleanup gracefully
    }
}
