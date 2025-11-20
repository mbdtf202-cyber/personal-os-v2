import SwiftUI
import Combine
import SwiftData

enum SearchResultType {
    case task, project, post, trade, snippet
}

struct SearchResult: Identifiable {
    let id = UUID()
    let type: SearchResultType
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct GlobalSearchView: View {
    @Binding var isPresented: Bool
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var searchResults: [SearchResult] = []
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // 背景点击关闭
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { isPresented = false }
                }
            
            // 搜索面板
            VStack(spacing: 0) {
                // 输入框区域
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    TextField("Search anything...", text: $query)
                        .font(.title3)
                        .focused($isFocused)
                        .submitLabel(.search)
                    
                    if !query.isEmpty {
                        Button(action: { query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                    }
                    
                    Text("ESC")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.tertiaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppTheme.border, lineWidth: 1))
                }
                .padding(20)
                .background(.ultraThinMaterial)
                
                Divider().background(AppTheme.border)
                
                // 结果区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if query.isEmpty {
                            Text("SUGGESTED ACTIONS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.secondaryText)
                            
                            Button(action: {
                                router.navigate(to: .social)
                                isPresented = false
                            }) {
                                ActionRow(icon: "doc.text", title: "Create new note")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                router.navigate(to: .health)
                                isPresented = false
                            }) {
                                ActionRow(icon: "figure.run", title: "Log workout")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                router.navigate(to: .trading)
                                isPresented = false
                            }) {
                                ActionRow(icon: "chart.line.uptrend.xyaxis", title: "Log trade")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("RESULTS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.secondaryText)
                            
                            if searchResults.isEmpty {
                                Text("No results found for '\(query)'")
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .padding(.top, 20)
                            } else {
                                ForEach(searchResults) { result in
                                    SearchResultRow(result: result)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .frame(maxHeight: 300)
                .background(Color.white.opacity(0.8))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .offset(y: -50)
        }
        .onAppear { isFocused = true }
        .transition(.opacity)
        .onChange(of: query) { _, newValue in
            performSearch(newValue)
        }
    }
    
    private func performSearch(_ searchQuery: String) {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        let lowercased = searchQuery.lowercased()
        var results: [SearchResult] = []
        
        // Search Tasks
        let taskDescriptor = FetchDescriptor<TodoItem>()
        if let tasks = try? modelContext.fetch(taskDescriptor) {
            let matchedTasks = tasks.filter { $0.title.lowercased().contains(lowercased) }
            results += matchedTasks.map { task in
                SearchResult(
                    type: .task,
                    title: task.title,
                    subtitle: task.category,
                    icon: "checkmark.circle",
                    color: AppTheme.mistBlue
                )
            }
        }
        
        // Search Projects
        let projectDescriptor = FetchDescriptor<ProjectItem>()
        if let projects = try? modelContext.fetch(projectDescriptor) {
            let matchedProjects = projects.filter { 
                $0.name.lowercased().contains(lowercased) || 
                $0.details.lowercased().contains(lowercased)
            }
            results += matchedProjects.map { project in
                SearchResult(
                    type: .project,
                    title: project.name,
                    subtitle: project.language,
                    icon: "folder",
                    color: AppTheme.almond
                )
            }
        }
        
        // Search Posts
        let postDescriptor = FetchDescriptor<SocialPost>()
        if let posts = try? modelContext.fetch(postDescriptor) {
            let matchedPosts = posts.filter { $0.title.lowercased().contains(lowercased) }
            results += matchedPosts.map { post in
                SearchResult(
                    type: .post,
                    title: post.title,
                    subtitle: post.platform.rawValue,
                    icon: "bubble.left.and.bubble.right",
                    color: AppTheme.lavender
                )
            }
        }
        
        // Search Trades
        let tradeDescriptor = FetchDescriptor<TradeRecord>()
        if let trades = try? modelContext.fetch(tradeDescriptor) {
            let matchedTrades = trades.filter { $0.symbol.lowercased().contains(lowercased) }
            results += matchedTrades.map { trade in
                SearchResult(
                    type: .trade,
                    title: trade.symbol,
                    subtitle: String(format: "%@ - $%.2f", trade.type.rawValue, trade.price),
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppTheme.matcha
                )
            }
        }
        
        searchResults = results
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.icon)
                .foregroundStyle(result.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.primaryText)
                Text(result.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.vertical, 8)
    }
}

struct ActionRow: View {
    var icon: String
    var title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GlobalSearchView(isPresented: .constant(true))
}
