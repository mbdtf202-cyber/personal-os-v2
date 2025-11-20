import SwiftUI
import Combine

struct NewsFeedView: View {
    @StateObject private var newsService = NewsService()
    @State private var selectedCategory = "All"
    @State private var news: [NewsItem] = []
    
    let mockNews: [NewsItem] = [
        NewsItem(
            source: "The Verge",
            title: "Apple announces new AI features for iOS 18",
            summary: "Siri gets a massive upgrade with LLM capabilities...",
            category: "Tech",
            image: "apple.logo",
            date: Date(),
            url: nil
        ),
        NewsItem(
            source: "CoinDesk",
            title: "Bitcoin breaks $70k resistance level",
            summary: "Market sentiment remains high as ETFs see inflow...",
            category: "Crypto",
            image: "bitcoinsign.circle.fill",
            date: Date().addingTimeInterval(-3600),
            url: nil
        ),
        NewsItem(
            source: "HackerNews",
            title: "Show HN: Personal OS built with SwiftUI",
            summary: "A complete operating system for your life...",
            category: "Dev",
            image: "terminal.fill",
            date: Date().addingTimeInterval(-7200),
            url: nil
        )
    ]
    
    let categories = ["All", "Tech", "AI", "Crypto", "Dev", "Design"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: { selectedCategory = cat }) {
                                    Text(cat)
                                        .font(.subheadline)
                                        .fontWeight(selectedCategory == cat ? .bold : .medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == cat ? AppTheme.primaryText : Color.white)
                                        .foregroundStyle(selectedCategory == cat ? .white : AppTheme.primaryText)
                                        .clipShape(Capsule())
                                        .shadow(color: AppTheme.shadow, radius: 4, y: 2)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // News List
                    ScrollView(showsIndicators: false) {
                        if newsService.isLoading {
                            ProgressView("Loading news...")
                                .padding()
                        } else {
                            LazyVStack(spacing: 20) {
                                ForEach(news) { item in
                                    NewsCard(item: item)
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("Briefing")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { Task { await refreshNews() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if news.isEmpty {
                    news = mockNews
                }
            }
        }
    }
    
    private func refreshNews() async {
        await newsService.fetchTopHeadlines(category: selectedCategory.lowercased())
        if !newsService.articles.isEmpty {
            news = newsService.articles.map { article in
                NewsItem(
                    source: article.source.name,
                    title: article.title,
                    summary: article.description ?? "",
                    category: selectedCategory,
                    image: "newspaper.fill",
                    date: Date(),
                    url: URL(string: article.url)
                )
            }
        }
    }
}

struct NewsCard: View {
    let item: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: item.image)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mistBlue)
                    .frame(width: 24, height: 24)
                    .background(AppTheme.mistBlue.opacity(0.1))
                    .clipShape(Circle())
                
                Text(item.source)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.secondaryText)
                
                Spacer()
                
                Text(item.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            
            // Content
            Text(item.title)
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(2)
            
            Text(item.summary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(3)
            
            // Actions
            HStack {
                Label(item.category, systemImage: "tag.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.almond)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .font(.caption)
                        .foregroundStyle(AppTheme.primaryText)
                }
                
                Button(action: {}) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
            .padding(.top, 8)
        }
        .glassCard()
    }
}

#Preview {
    NewsFeedView()
}
