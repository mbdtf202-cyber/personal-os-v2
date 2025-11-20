import SwiftUI
import SwiftData

struct SocialDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SocialPost.date, order: .reverse) private var posts: [SocialPost]
    @State private var showEditor = false
    @State private var newPost = SocialPost(title: "", platform: .twitter, status: .idea, date: Date(), content: "", views: 0, likes: 0)
    @State private var selectedPost: SocialPost?
    @State private var selectedDate: Date?

    private var upcomingPosts: [SocialPost] {
        let filtered = posts.filter { $0.status == .scheduled }
        if let date = selectedDate {
            return filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.sorted { $0.date < $1.date }
        }
        return filtered.sorted { $0.date < $1.date }
    }

    private var drafts: [SocialPost] {
        let filtered = posts.filter { $0.status == .draft || $0.status == .idea }
        if let date = selectedDate {
            return filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        }
        return filtered
    }
    
    private var publishedPosts: [SocialPost] {
        let filtered = posts.filter { $0.status == .published }
        if let date = selectedDate {
            return filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        }
        return filtered.sorted { $0.date > $1.date }
    }
    
    private var totalViews: String {
        let total = posts.reduce(0) { $0 + $1.views }
        if total >= 1000 {
            return String(format: "%.1fK", Double(total) / 1000.0)
        }
        return "\(total)"
    }
    
    private var engagementRate: String {
        let totalViews = posts.reduce(0) { $0 + $1.views }
        let totalLikes = posts.reduce(0) { $0 + $1.likes }
        guard totalViews > 0 else { return "0%" }
        let rate = (Double(totalLikes) / Double(totalViews)) * 100
        return String(format: "%.1f%%", rate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // 1. Stats Header
                        statsHeader
                        
                        // 2. Calendar
                        VStack(alignment: .leading, spacing: 8) {
                            ContentCalendarView(posts: posts, selectedDate: $selectedDate)
                            
                            if selectedDate != nil {
                                Button(action: { 
                                    selectedDate = nil
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
                        
                        // 3. Up Next (Scheduled)
                        sectionHeader(title: "Up Next", icon: "clock.fill", color: .blue)
                        if upcomingPosts.isEmpty {
                            SocialEmptyStateView(message: "No scheduled posts.")
                        } else {
                            ForEach(upcomingPosts) { post in
                                PostRowView(post: post)
                                    .onTapGesture {
                                        selectedPost = post
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
                                    }
                            }
                        }

                        // 4. Drafts & Ideas
                        sectionHeader(title: "Drafts & Ideas", icon: "lightbulb.fill", color: .orange)
                        if drafts.isEmpty && selectedDate != nil {
                            SocialEmptyStateView(message: "No drafts for this date.")
                        } else if drafts.isEmpty {
                            SocialEmptyStateView(message: "No drafts. Tap + to create one.")
                        } else {
                            ForEach(drafts) { post in
                                PostRowView(post: post)
                                    .onTapGesture {
                                        selectedPost = post
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
                                        selectedPost = post
                                        HapticsManager.shared.light()
                                    }
                                    .contextMenu {
                                        statusContextMenu(for: post)
                                    }
                            }
                            
                            if publishedPosts.count > 5 {
                                Button(action: {
                                    // TODO: Navigate to full published posts list
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
                            newPost = SocialPost(title: "", platform: .twitter, status: .idea, date: Date(), content: "", views: 0, likes: 0)
                            showEditor = true
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
            .sheet(isPresented: $showEditor) {
                MarkdownEditorView(post: $newPost, onSave: { post in
                    savePost(post)
                })
            }
            .sheet(item: $selectedPost) { post in
                EditPostWrapper(post: post)
            }
        }
        .onAppear(perform: seedPostsIfNeeded)
    }
    
    // MARK: - Components
    
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatBox(title: "Total Views", value: totalViews, icon: "eye.fill", color: AppTheme.almond)
            StatBox(title: "Engagement", value: engagementRate, icon: "chart.line.uptrend.xyaxis", color: AppTheme.matcha)
        }
    }
    
    @ViewBuilder
    private func statusContextMenu(for post: SocialPost) -> some View {
        Button(action: { selectedPost = post }) {
            Label("Edit", systemImage: "pencil")
        }
        
        Divider()
        
        Menu("Change Status") {
            ForEach([PostStatus.idea, .draft, .scheduled, .published], id: \.self) { status in
                Button(action: {
                    post.status = status
                    try? modelContext.save()
                    HapticsManager.shared.light()
                }) {
                    Label(status.rawValue, systemImage: status == post.status ? "checkmark" : "circle")
                }
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            modelContext.delete(post)
            try? modelContext.save()
            HapticsManager.shared.light()
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
        }
    }

    private func savePost(_ post: SocialPost) {
        modelContext.insert(post)
        try? modelContext.save()
    }

    private func seedPostsIfNeeded() {
        guard posts.isEmpty else { return }
        SocialPost.defaultPosts.forEach { modelContext.insert($0) }
        try? modelContext.save()
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.primaryText)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
    }
}

struct PostRowView: View {
    let post: SocialPost
    
    var body: some View {
        HStack(spacing: 16) {
            // Platform Icon
            ZStack {
                Circle()
                    .fill(post.platform.color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: post.platform.icon)
                    .foregroundStyle(post.platform.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title.isEmpty ? "Untitled Post" : post.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                HStack {
                    Text(post.status.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(post.status.color.opacity(0.2))
                        .foregroundStyle(post.status.color)
                        .cornerRadius(4)
                    Text("• \(post.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
    }
}

struct PublishedPostRow: View {
    @Bindable var post: SocialPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Platform Icon
                ZStack {
                    Circle()
                        .fill(post.platform.color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: post.platform.icon)
                        .font(.caption)
                        .foregroundStyle(post.platform.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title.isEmpty ? "Untitled Post" : post.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                    Text(post.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            
            // Engagement Stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.mistBlue)
                    TextField("Views", value: $post.views, format: .number)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.coral)
                    TextField("Likes", value: $post.likes, format: .number)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                }
                
                Spacer()
                
                if post.views > 0 {
                    Text("\((Double(post.likes) / Double(post.views) * 100), specifier: "%.1f")% engagement")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.matcha)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
    }
}

struct SocialEmptyStateView: View {
    let message: String
    
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.tertiaryText)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Edit Post Wrapper
struct EditPostWrapper: View {
    @Bindable var post: SocialPost
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
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
                    try? modelContext.save()
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
