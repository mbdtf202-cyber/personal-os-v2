import SwiftUI
import SwiftData

struct KnowledgeBaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appDependency) private var appDependency
    @Query(sort: \CodeSnippet.date, order: .reverse) private var allSnippets: [CodeSnippet]
    @State private var selectedCategory: KnowledgeCategory?
    @State private var searchText = ""
    @State private var showAddSnippet = false
    @State private var searchTask: Task<Void, Never>?
    @State private var filteredSnippets: [CodeSnippet] = []
    @State private var isSearching = false
    @State private var displayedCount = 20
    @State private var isLoadingMore = false
    
    private var sourceSnippets: [CodeSnippet] {
        if isSearching {
            return filteredSnippets
        } else if let category = selectedCategory {
            return allSnippets.filter { $0.category == category }
        } else {
            return allSnippets
        }
    }
    
    private var displaySnippets: [CodeSnippet] {
        Array(sourceSnippets.prefix(displayedCount))
    }
    
    private var hasMore: Bool {
        displayedCount < sourceSnippets.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: "All", isSelected: selectedCategory == nil) {
                                withAnimation { selectedCategory = nil }
                            }
                            ForEach(KnowledgeCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    color: category.color
                                ) {
                                    withAnimation { selectedCategory = category }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    
                    // Content List
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            if displaySnippets.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundStyle(AppTheme.tertiaryText)
                                    Text(searchText.isEmpty ? "No snippets yet" : "No results found")
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.secondaryText)
                                    Button("Add First Snippet") {
                                        showAddSnippet = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            } else {
                                ForEach(displaySnippets) { snippet in
                                    NavigationLink(destination: SnippetDetailView(snippet: snippet)) {
                                        SnippetRowCard(snippet: snippet)
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        if snippet.id == displaySnippets.last?.id {
                                            loadMoreIfNeeded()
                                        }
                                    }
                                }
                                
                                if isLoadingMore {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding()
                                        Spacer()
                                    }
                                } else if !hasMore && !displaySnippets.isEmpty {
                                    Text("No more snippets")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.tertiaryText)
                                        .padding()
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Knowledge Base")
            .searchable(text: $searchText, prompt: "Search snippets, bugs, notes...")
            .onChange(of: searchText) { oldValue, newValue in
                performSearch(query: newValue)
            }
            .onChange(of: selectedCategory) { oldValue, newValue in
                displayedCount = 20
                if isSearching && !searchText.isEmpty {
                    performSearch(query: searchText)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddSnippet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSnippet) {
                AddSnippetView()
            }
            .onAppear {
                seedSnippetsIfNeeded()
            }
        }
    }
    
    private func performSearch(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        // Reset pagination on new search
        displayedCount = 20
        
        // Debounce search
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                if query.isEmpty {
                    isSearching = false
                    filteredSnippets = []
                } else {
                    isSearching = true
                    searchSnippets(query: query)
                }
            }
        }
    }
    
    private func loadMoreIfNeeded() {
        guard !isLoadingMore && hasMore else { return }
        
        isLoadingMore = true
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Simulate loading
            
            await MainActor.run {
                displayedCount += 20
                isLoadingMore = false
            }
        }
    }
    
    private func searchSnippets(query: String) {
        do {
            // Build predicate with category filter if needed
            let predicate: Predicate<CodeSnippet>
            
            if let category = selectedCategory {
                predicate = #Predicate<CodeSnippet> { snippet in
                    snippet.category == category &&
                    (snippet.title.localizedStandardContains(query) ||
                     snippet.summary.localizedStandardContains(query) ||
                     snippet.code.localizedStandardContains(query))
                }
            } else {
                predicate = #Predicate<CodeSnippet> { snippet in
                    snippet.title.localizedStandardContains(query) ||
                    snippet.summary.localizedStandardContains(query) ||
                    snippet.code.localizedStandardContains(query)
                }
            }
            
            var descriptor = FetchDescriptor<CodeSnippet>(predicate: predicate)
            descriptor.sortBy = [SortDescriptor(\CodeSnippet.date, order: .reverse)]
            
            filteredSnippets = try modelContext.fetch(descriptor)
        } catch {
            ErrorHandler.shared.handle(error, context: "KnowledgeBaseView.searchSnippets")
            filteredSnippets = []
        }
    }
    
    private func seedSnippetsIfNeeded() {
        guard allSnippets.isEmpty else { return }
        Task {
            for snippet in CodeSnippet.defaultSnippets {
                try? await appDependency?.repositories.codeSnippet.save(snippet)
            }
        }
    }
}

// MARK: - Subviews

struct FilterChip: View {
    let title: String
    var isSelected: Bool
    var color: Color = AppTheme.primaryText
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.white)
                .foregroundStyle(isSelected ? .white : AppTheme.primaryText)
                .cornerRadius(20)
                .shadow(color: isSelected ? color.opacity(0.3) : AppTheme.shadow, radius: 4, y: 2)
        }
    }
}

struct SnippetRowCard: View {
    let snippet: CodeSnippet
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(snippet.category.color.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: snippet.category.icon)
                    .font(.title3)
                    .foregroundStyle(snippet.category.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(snippet.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(snippet.language)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppTheme.border, lineWidth: 1))
                }
                Text(snippet.summary)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
    }
}

#Preview {
    KnowledgeBaseView()
}
