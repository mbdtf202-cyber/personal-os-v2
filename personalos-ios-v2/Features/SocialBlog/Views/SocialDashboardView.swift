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
        return SocialDashboardViewModel(socialPostRepository: SocialPostRepository(modelContext: appDependency?.modelContext))
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
                            ContentCalendarView(posts: posts, selectedDate: $vm.selectedDate)
                            
                            if vm.selectedDate != nil {
                                Button(action: { 
                                    vm.selectedDate = nil
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
                                        vm.selectedPost = post
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
                                    }
                            }
                        }

                        SocialSectionHeader(title: "Drafts & Ideas", icon: "lightbulb.fill", color: .orange)
                        if drafts.isEmpty && vm.selectedDate != nil {
                            SocialEmptyStateView(message: "No drafts for this date.")
                        } else if drafts.isEmpty {
                            SocialEmptyStateView(message: "No drafts. Tap + to create one.")
                        } else {
                            ForEach(drafts) { post in
                                PostRowView(post: post)
                                    .onTapGesture {
                                        vm.selectedPost = post
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
                                    }
                            }
                        }
                        
                        // 5. Published Posts
                        if !publishedPosts.isEmpty {
                            sectionHeader(title: "Published", icon: "checkmark.circle.fill", color: .green)
                            ForEach(publishedPosts.prefix(5)) { post in
                                PublishedPostRow(post: post)
                                    .onTapGesture {
                                        vm.selectedPost = post
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
                            vm.newPost = SocialPost(title: "", platform: .twitter, status: .idea, date: Date(), content: "", views: 0, likes: 0)
                            vm.showEditor = true
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
            .sheet(isPresented: $vm.showEditor) {
                MarkdownEditorView(post: $vm.newPost, onSave: { post in
                    Task { await vm.savePost(post) }
                })
            }
            .sheet(item: $vm.selectedPost) { post in
                EditPostWrapper(post: post, viewModel: viewModel)
            }
        }
        .onAppear {
            if viewModel == nil, let dependency = appDependency {
                viewModel = SocialDashboardViewModel(socialPostRepository: dependency.repositories.socialPost)
            }
            Task {
                await vm.seedDefaultPosts()
            }
        }
    }
    
    @ViewBuilder
    private func statusContextMenu(for: SocialPost) -> some View {
        Button(action: { vm.selectedPost = post }) {
            Label("Edit", systemImage: "pencil")
        }
        
        Divider()
        
        Menu("Change Status") {
            ForEach([PostStatus.idea, .draft, .scheduled, .published], id: \.self) { status in
                Button(action: {
                    Task {
                        await vm.changePostStatus(post, to: status)
                    }
                }) {
                    Label(status.rawValue, systemImage: status == post.status ? "checkmark" : "circle")
                }
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            Task {
                await vm.deletePost(post)
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
                        await vm.savePost(post)
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
