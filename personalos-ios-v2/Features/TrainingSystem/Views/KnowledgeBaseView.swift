import SwiftUI
import SwiftData

struct KnowledgeBaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CodeSnippet.date, order: .reverse) private var allSnippets: [CodeSnippet]
    @State private var selectedCategory: KnowledgeCategory?
    @State private var searchText = ""
    @State private var showAddSnippet = false
    
    private var filteredSnippets: [CodeSnippet] {
        var results = allSnippets
        
        // Filter by category
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText) ||
                $0.code.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return results
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
                            if filteredSnippets.isEmpty {
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
                                ForEach(filteredSnippets) { snippet in
                                    NavigationLink(destination: SnippetDetailView(snippet: snippet)) {
                                        SnippetRowCard(snippet: snippet)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Knowledge Base")
            .searchable(text: $searchText, prompt: "Search snippets, bugs, notes...")
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
