import SwiftUI
import SwiftData

struct SocialDashboardView: View {
    @Query(sort: \SocialPost.date, order: .reverse) private var posts: [SocialPost]
    @State private var viewModel: SocialDashboardViewModel?
    @Environment(\.appDependency) private var appDependency
    
    init() {}
    
    private var vm: SocialDashboardViewModel {
        if let viewModel = viewModel {
            return viewModel
        }
        guard let context = appDependency?.modelContext else {
            fatalError("ModelContext not available")
        }
        return SocialDashboardViewModel(socialPostRepository: SocialPostRepository(modelContext: context))
    }

    private var upcomingPosts: [SocialPost] {
        vm.filterPosts(posts, by: .scheduled, date: vm.selectedDate)
    }

    private var drafts: [SocialPost] {
        let ideas = vm.filterPosts(posts, by: .idea, date: vm.selectedDate)
        let drafts = vm.filterPosts(posts, by: .draft, date: vm.selectedDate)
        return ideas + drafts
    }
    
    private var publishedPosts: [SocialPost] {
        vm.filterPosts(posts, by: .published, date: vm.selectedDate).sorted { $0.date > $1.date }
    }
    
    private var stats: (totalViews: String, engagementRate: String) {
        vm.calculateStats(from: posts)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        SocialStatsHeader(
                            totalViews: stats.totalViews,
                            engagementRate: stats.engagementRate,
                            totalPosts: posts.count
                        )
                        
                        // Calendar
                        VStack(alignment: .leading, spacing: 8) {
                            if let viewModel = viewModel {
                                ContentCalendarView(posts: posts, selectedDate: Binding(
                                    get: { viewModel.selectedDate },
                                    set: { viewModel.selectedDate = $0 }
                                ))
                            }
                            
                            if let viewModel = viewModel, viewModel.selectedDate != nil {
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
                                        if let viewModel = viewModel {
                                            viewModel.selectedPost = post
                                        }
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
                                    }
                            }
                        }

                        SocialSectionHeader(title: "Drafts & Ideas", icon: "lightbulb.fill", color: .orange)
                        if drafts.isEmpty && viewModel?.selectedDate != nil {
                            SocialEmptyStateView(message: "No drafts for this date.")
                        } else if drafts.isEmpty {
                            SocialEmptyStateView(message: "No drafts. Tap + to create one.")
                        } else {
                            ForEach(drafts) { post in
                                PostRowView(post: post)
                                    .onTapGesture {
                                        if let viewModel = viewModel {
                                            viewModel.selectedPost = post
                                        }
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
                                    }
                            }
                        }
                        
                        // 5. Published Posts
                        if !publishedPosts.isEmpty {
                            SocialSectionHeader(title: "Published", icon: "checkmark.circle.fill", color: .green)
                            ForEach(publishedPosts.prefix(5)) { post in
                                PublishedPostRow(post: post)
                                    .onTapGesture {
                                        if let viewModel = viewModel {
                                            viewModel.selectedPost = post
                                        }
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
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
                            if let viewModel = viewModel {
                                viewModel.newPost = SocialPost(title: "", platform: .twitter, status: .idea, date: Date(), content: "", views: 0, likes: 0)
                                viewModel.showEditor = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(AppTheme.almond)
                                .clipShape(Circle())
                                .shadow(color: AppTheme.almond.opacity(0.4), radius: 10, y: 5)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Social Command")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(
                get: { viewModel?.showEditor ?? false },
                set: { if let viewModel = viewModel { viewModel.showEditor = $0 } }
            )) {
                if let viewModel = viewModel {
                    MarkdownEditorView(post: Binding(
                        get: { viewModel.newPost },
                        set: { viewModel.newPost = $0 }
                    ), onSave: { post in
                        Task { await viewModel.savePost(post) }
                    })
                }
            }
            .sheet(item: Binding(
                get: { viewModel?.selectedPost },
                set: { if let viewModel = viewModel { viewModel.selectedPost = $0 } }
            )) { post in
                if let viewModel = viewModel {
                    EditPostWrapper(post: post, viewModel: viewModel)
                }
            }
        }
        .onAppear {
            if viewModel == nil, let dependency = appDependency {
                viewModel = SocialDashboardViewModel(socialPostRepository: dependency.repositories.socialPost)
            }
            if let viewModel = viewModel {
                Task {
                    await viewModel.seedDefaultPosts()
                }
            }
        }
    }
    
    @ViewBuilder
    private func statusContextMenu(for post: SocialPost) -> some View {
        Button(action: { 
            if let viewModel = viewModel {
                viewModel.selectedPost = post
            }
        }) {
            Label("Edit", systemImage: "pencil")
        }
        
        Divider()
        
        Menu("Change Status") {
            ForEach([PostStatus.idea, .draft, .scheduled, .published], id: \.self) { status in
                Button(action: {
                    Task {
                        if let viewModel = viewModel {
                            await viewModel.changePostStatus(post, to: status)
                        }
                    }
                }) {
                    Label(status.rawValue, systemImage: status == post.status ? "checkmark" : "circle")
                }
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            Task {
                if let viewModel = viewModel {
                    await viewModel.deletePost(post)
                }
            }
        }) {
            Label("Delete", systemImage: "trash")
        }
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
    SocialDashboardView()
        .modelContainer(for: SocialPost.self, inMemory: true)
}
