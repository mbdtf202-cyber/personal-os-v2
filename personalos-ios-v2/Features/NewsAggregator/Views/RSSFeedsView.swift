import SwiftUI
import SwiftData

struct RSSFeedsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RSSFeed.name) private var feeds: [RSSFeed]
    @State private var showAddFeed = false
    @State private var newFeedName = ""
    @State private var newFeedURL = ""
    @State private var newFeedCategory = "General"
    
    let categories = ["General", "Tech", "Dev", "Design", "Business", "Science"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Info Card
                        HStack(spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.title2)
                                .foregroundStyle(AppTheme.mistBlue)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.mistBlue.opacity(0.15))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("RSS Feeds")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)
                                Text("Subscribe to your favorite blogs and news sources")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
                        
                        // Feeds List
                        if feeds.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "tray")
                                    .font(.system(size: 48))
                                    .foregroundStyle(AppTheme.tertiaryText)
                                Text("No RSS feeds yet")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.secondaryText)
                                Text("Add your first feed to get started")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.tertiaryText)
                                
                                Button(action: { showAddFeed = true }) {
                                    Text("Add Feed")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(AppTheme.mistBlue)
                                        .cornerRadius(12)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(feeds) { feed in
                                RSSFeedRow(feed: feed, onDelete: {
                                    deleteFeed(feed)
                                })
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("RSS Feeds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddFeed = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFeed) {
                NavigationStack {
                    Form {
                        Section(header: Text("Feed Information")) {
                            TextField("Name", text: $newFeedName)
                            TextField("RSS URL", text: $newFeedURL)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                            
                            Picker("Category", selection: $newFeedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                        }
                        
                        Section {
                            Button("Add Feed") {
                                addFeed()
                            }
                            .disabled(newFeedName.isEmpty || newFeedURL.isEmpty)
                        }
                    }
                    .navigationTitle("Add RSS Feed")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showAddFeed = false
                                resetForm()
                            }
                        }
                    }
                }
            }
            .onAppear {
                seedDefaultFeeds()
            }
        }
    }
    
    private func addFeed() {
        let feed = RSSFeed(
            name: newFeedName,
            url: newFeedURL,
            category: newFeedCategory
        )
        modelContext.insert(feed)
        try? modelContext.save()
        
        HapticsManager.shared.success()
        Logger.log("RSS feed added: \(newFeedName)", category: Logger.general)
        
        showAddFeed = false
        resetForm()
    }
    
    private func deleteFeed(_ feed: RSSFeed) {
        modelContext.delete(feed)
        try? modelContext.save()
        HapticsManager.shared.light()
    }
    
    private func resetForm() {
        newFeedName = ""
        newFeedURL = ""
        newFeedCategory = "General"
    }
    
    private func seedDefaultFeeds() {
        guard feeds.isEmpty else { return }
        RSSFeed.defaultFeeds.forEach { modelContext.insert($0) }
        try? modelContext.save()
    }
}

struct RSSFeedRow: View {
    @Bindable var feed: RSSFeed
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.title3)
                .foregroundStyle(feed.isEnabled ? AppTheme.matcha : AppTheme.secondaryText)
                .frame(width: 40, height: 40)
                .background(feed.isEnabled ? AppTheme.matcha.opacity(0.15) : Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feed.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                
                Text(feed.url)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(feed.category)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.almond.opacity(0.2))
                        .foregroundStyle(AppTheme.almond)
                        .cornerRadius(4)
                    
                    if let lastFetched = feed.lastFetched {
                        Text("Updated \(lastFetched.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $feed.isEnabled)
                .labelsHidden()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    RSSFeedsView()
        .modelContainer(for: RSSFeed.self, inMemory: true)
}
