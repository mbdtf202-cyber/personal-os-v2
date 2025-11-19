import SwiftUI

struct SocialDashboardView: View {
    @State private var manager = ContentManager()
    @State private var showEditor = false
    @State private var newPost = SocialPost(title: "", platform: .twitter, status: .idea, date: Date(), content: "", views: 0, likes: 0)
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // 1. Stats Header
                        statsHeader
                        
                        // 2. Calendar
                        ContentCalendarView(posts: manager.posts)
                        
                        // 3. Up Next (Scheduled)
                        sectionHeader(title: "Up Next", icon: "clock.fill", color: .blue)
                        if manager.upcomingPosts.isEmpty {
                            SocialEmptyStateView(message: "No scheduled posts.")
                        } else {
                            ForEach(manager.upcomingPosts) { post in
                                PostRowView(post: post)
                            }
                        }

                        // 4. Drafts & Ideas
                        sectionHeader(title: "Drafts & Ideas", icon: "lightbulb.fill", color: .orange)
                        ForEach(manager.drafts) { post in
                            PostRowView(post: post)
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
                    manager.addPost(post)
                })
            }
        }
    }
    
    // MARK: - Components
    
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatBox(title: "Total Views", value: "12.5K", icon: "eye.fill", color: AppTheme.almond)
            StatBox(title: "Engagement", value: "8.2%", icon: "chart.line.uptrend.xyaxis", color: AppTheme.matcha)
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

#Preview {
    SocialDashboardView()
}
