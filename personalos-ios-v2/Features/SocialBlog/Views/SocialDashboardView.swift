import SwiftUI
import SwiftData

struct SocialDashboardView: View {
    // ✅ Task 21: Use database predicate filtering for better performance
    @Query(sort: \SocialPost.date, order: .reverse) private var allPosts: [SocialPost]
    @State private var viewModel: SocialDashboardViewModel
    @State private var currentPage = 0
    @State private var isLoadingMore = false
    private let pageSize = 20
    
    init(viewModel: SocialDashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // ✅ Task 21: Implement pagination for post lists
    private var paginatedPosts: [SocialPost] {
        let endIndex = min((currentPage + 1) * pageSize, allPosts.count)
        return Array(allPosts.prefix(endIndex))
    }
    
    private var upcomingPosts: [SocialPost] {
        viewModel.filterPosts(paginatedPosts, by: .scheduled, date: viewModel.selectedDate)
    }

    private var drafts: [SocialPost] {
        let ideas = viewModel.filterPosts(paginatedPosts, by: .idea, date: viewModel.selectedDate)
        let drafts = viewModel.filterPosts(paginatedPosts, by: .draft, date: viewModel.selectedDate)
        return ideas + drafts
    }
    
    private var publishedPosts: [SocialPost] {
        viewModel.filterPosts(paginatedPosts, by: .published, date: viewModel.selectedDate).sorted { $0.date > $1.date }
    }
    
    private var hasMorePosts: Bool {
        allPosts.count > (currentPage + 1) * pageSize
    }
    
    private var stats: (totalViews: String, engagementRate: String) {
        viewModel.calculateStats(from: posts)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // ✅ Task 22: Display operation feedback
                        if let operation = viewModel.lastOperation {
                            HStack {
                                Image(systemName: operation.icon)
                                    .foregroundStyle(operation.color)
                                Text(operation.message)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                                Spacer()
                            }
                            .padding()
                            .background(operation.color.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        SocialStatsHeader(
                            totalViews: stats.totalViews,
                            engagementRate: stats.engagementRate,
                            totalPosts: allPosts.count
                        )
                        
                        // Calendar
                        VStack(alignment: .leading, spacing: 8) {
                            ContentCalendarView(posts: allPosts, selectedDate: Binding(
                                get: { viewModel.selectedDate },
                                set: { viewModel.selectedDate = $0 }
                            ))
                            
                            if viewModel.selectedDate != nil {
                                Button(action: { 
                                    viewModel.selectedDate = nil
                                    HapticsManager.shared.light()
                                }) {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Clear filter")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.5))
                                    .clipShape(Capsule())
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        SocialSectionHeader(title: "Up Next", icon: "clock.fill", color: .blue)
                        if upcomingPosts.isEmpty {
                            SocialEmptyStateView(message: "No scheduled posts.")
                        } else {
                            ForEach(upcomingPosts) { post in
                                PostRowView(post: post)
                                    .onTapGesture {
                                        viewModel.selectedPost = post
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
                                    }
                                    // ✅ Task 21: Load more on scroll to bottom
                                    .onAppear {
                                        if post == upcomingPosts.last && hasMorePosts && !isLoadingMore {
                                            loadMorePosts()
                                        }
                                    }
                            }
                        }

                        SocialSectionHeader(title: "Drafts & Ideas", icon: "lightbulb.fill", color: .orange)
                        if drafts.isEmpty && viewModel.selectedDate != nil {
                            SocialEmptyStateView(message: "No drafts for this date.")
                        } else if drafts.isEmpty {
                            SocialEmptyStateView(message: "No drafts. Tap + to create one.")
                        } else {
                            ForEach(drafts) { post in
                                PostRowView(post: post)
                                    .onTapGesture {
                                        viewModel.selectedPost = post
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
                                    }
                                    // ✅ Task 21: Load more on scroll to bottom
                                    .onAppear {
                                        if post == drafts.last && hasMorePosts && !isLoadingMore {
                                            loadMorePosts()
                                        }
                                    }
                            }
                        }
                        
                        // 5. Published Posts
                        if !publishedPosts.isEmpty {
                            SocialSectionHeader(title: "Published", icon: "checkmark.circle.fill", color: .green)
                            ForEach(publishedPosts.prefix(5)) { post in
                                PublishedPostRow(post: post)
                                    .onTapGesture {
                                        viewModel.selectedPost = post
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
                                    }
                                    // ✅ Task 21: Load more on scroll to bottom
                                    .onAppear {
                                        if post == publishedPosts.prefix(5).last && hasMorePosts && !isLoadingMore {
                                            loadMorePosts()
                                        }
                                    }
                            }
                            
                            if publishedPosts.count > 5 {
                                Button(action: {
                                    // Navigate to full published posts list
                                }) {
                                    HStack {
                                        Text("View all \(publishedPosts.count) published posts")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.mistBlue)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.mistBlue)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        
                        // ✅ Task 21: Loading indicator and "no more data" message
                        if isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        } else if !hasMorePosts && paginatedPosts.count > pageSize {
                            Text("No more posts")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
                
                // FAB (Floating Action Button)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.newPost = SocialPost(title: "", platform: .twitter, status: .idea, date: Date(), content: "", views: 0, likes: 0)
                            viewModel.showEditor = true
                        }) {
                            // ✅ Task 22: Show loading state on button
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 60, height: 60)
                                    .background(AppTheme.almond.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(color: AppTheme.almond.opacity(0.4), radius: 10, y: 5)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(AppTheme.almond)
                                    .clipShape(Circle())
                                    .shadow(color: AppTheme.almond.opacity(0.4), radius: 10, y: 5)
                            }
                        }
                        .disabled(viewModel.isLoading)
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Social Command")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(
                get: { viewModel.showEditor },
                set: { viewModel.showEditor = $0 }
            )) {
                MarkdownEditorView(post: Binding(
                    get: { viewModel.newPost },
                    set: { viewModel.newPost = $0 }
                ), onSave: { post in
                    Task { await viewModel.savePost(post) }
                })
            }
            .sheet(item: Binding(
                get: { viewModel.selectedPost },
                set: { viewModel.selectedPost = $0 }
            )) { post in
                EditPostWrapper(post: post, viewModel: viewModel)
            }
        }
        .onAppear {
            Task {
                await viewModel.seedDefaultPosts()
            }
        }
        .onDisappear {
            // Clean up any ongoing tasks
            viewModel.cancelOngoingTasks()
        }
    }
    
    // ✅ Task 21: Load more posts helper
    private func loadMorePosts() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Simulate loading
            currentPage += 1
            isLoadingMore = false
        }
    }
    
    @ViewBuilder
    private func statusContextMenu(for post: SocialPost) -> some View {
        Button(action: { 
            viewModel.selectedPost = post
        }) {
            Label("Edit", systemImage: "pencil")
        }
        .disabled(viewModel.isLoading)
        
        Divider()
        
        Menu("Change Status") {
            ForEach([PostStatus.idea, .draft, .scheduled, .published], id: \.self) { status in
                Button(action: {
                    Task {
                        await viewModel.changePostStatus(post, to: status)
                    }
                }) {
                    Label(status.rawValue, systemImage: status == post.status ? "checkmark" : "circle")
                }
                .disabled(viewModel.isLoading)
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            Task {
                await viewModel.deletePost(post)
            }
        }) {
            Label("Delete", systemImage: "trash")
        }
        .disabled(viewModel.isLoading)
    }
    
}


// MARK: - Edit Post Wrapper
struct EditPostWrapper: View {
    @Bindable var post: SocialPost
    @Environment(\.dismiss) var dismiss
    let viewModel: SocialDashboardViewModel
    
    var body: some View {
        NavigationStack {
            MarkdownEditorView(post: Binding(
                get: { post },
                set: { newValue in
                    post.title = newValue.title
                    post.content = newValue.content
                    post.platform = newValue.platform
                    post.status = newValue.status
                    post.date = newValue.date
                    Task {
                        await viewModel.savePost(post)
                    }
                }
            ), onSave: { _ in
                dismiss()
            })
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SocialPost.self, configurations: config)
    let context = ModelContext(container)
    let repository = SocialPostRepository(modelContext: context)
    let viewModel = SocialDashboardViewModel(socialPostRepository: repository)
    
    return SocialDashboardView(viewModel: viewModel)
        .modelContainer(container)
}
