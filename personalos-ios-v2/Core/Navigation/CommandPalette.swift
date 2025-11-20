import SwiftUI
import Combine

struct Command: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let keywords: [String]
    let action: () -> Void
    
    func matches(_ query: String) -> Bool {
        let lowercaseQuery = query.lowercased()
        return title.lowercased().contains(lowercaseQuery) ||
               keywords.contains { $0.lowercased().contains(lowercaseQuery) } ||
               (subtitle?.lowercased().contains(lowercaseQuery) ?? false)
    }
}

@MainActor
class CommandPaletteViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var isPresented = false
    @Published var selectedIndex = 0
    
    private var allCommands: [Command] = []
    
    var filteredCommands: [Command] {
        if searchQuery.isEmpty {
            return allCommands
        }
        return allCommands.filter { $0.matches(searchQuery) }
    }
    
    init() {
        setupCommands()
    }
    
    private func setupCommands() {
        allCommands = [
            // Navigation
            Command(
                title: "Go to Dashboard",
                subtitle: "View your overview",
                icon: "square.grid.2x2.fill",
                keywords: ["home", "dashboard", "overview"],
                action: { NotificationCenter.default.post(name: .navigateTo, object: "dashboard") }
            ),
            Command(
                title: "Go to Projects",
                subtitle: "Manage your projects",
                icon: "folder.fill",
                keywords: ["projects", "github", "repos"],
                action: { NotificationCenter.default.post(name: .navigateTo, object: "projects") }
            ),
            Command(
                title: "Go to Trading Journal",
                subtitle: "Track your trades",
                icon: "chart.line.uptrend.xyaxis",
                keywords: ["trading", "stocks", "wealth", "portfolio"],
                action: { NotificationCenter.default.post(name: .navigateTo, object: "trading") }
            ),
            Command(
                title: "Go to News",
                subtitle: "Read latest articles",
                icon: "newspaper.fill",
                keywords: ["news", "articles", "rss"],
                action: { NotificationCenter.default.post(name: .navigateTo, object: "news") }
            ),
            Command(
                title: "Go to Social Blog",
                subtitle: "Manage your content",
                icon: "bubble.left.and.bubble.right.fill",
                keywords: ["social", "blog", "posts", "content"],
                action: { NotificationCenter.default.post(name: .navigateTo, object: "social") }
            ),
            Command(
                title: "Go to Training System",
                subtitle: "Learn and practice",
                icon: "book.fill",
                keywords: ["training", "learning", "snippets", "knowledge"],
                action: { NotificationCenter.default.post(name: .navigateTo, object: "training") }
            ),
            Command(
                title: "Go to Settings",
                subtitle: "Configure your app",
                icon: "gear",
                keywords: ["settings", "preferences", "config"],
                action: { NotificationCenter.default.post(name: .navigateTo, object: "settings") }
            ),
            
            // Actions
            Command(
                title: "New Quick Note",
                subtitle: "Capture a thought",
                icon: "note.text.badge.plus",
                keywords: ["note", "quick", "capture", "write"],
                action: { NotificationCenter.default.post(name: .showQuickNote, object: nil) }
            ),
            Command(
                title: "New Trade",
                subtitle: "Log a new trade",
                icon: "plus.circle.fill",
                keywords: ["trade", "new", "log", "entry"],
                action: { NotificationCenter.default.post(name: .newTrade, object: nil) }
            ),
            Command(
                title: "New Blog Post",
                subtitle: "Start writing",
                icon: "square.and.pencil",
                keywords: ["post", "blog", "write", "article"],
                action: { NotificationCenter.default.post(name: .newPost, object: nil) }
            ),
            Command(
                title: "Add Code Snippet",
                subtitle: "Save a code snippet",
                icon: "chevron.left.forwardslash.chevron.right",
                keywords: ["code", "snippet", "save"],
                action: { NotificationCenter.default.post(name: .newSnippet, object: nil) }
            ),
            
            // Theme
            Command(
                title: "Toggle Theme",
                subtitle: "Switch between light and dark",
                icon: "moon.fill",
                keywords: ["theme", "dark", "light", "appearance"],
                action: { NotificationCenter.default.post(name: .toggleTheme, object: nil) }
            ),
            
            // Search
            Command(
                title: "Global Search",
                subtitle: "Search across all modules",
                icon: "magnifyingglass",
                keywords: ["search", "find", "query"],
                action: { NotificationCenter.default.post(name: .showGlobalSearch, object: nil) }
            )
        ]
    }
    
    func executeSelected() {
        guard !filteredCommands.isEmpty else { return }
        let command = filteredCommands[selectedIndex]
        command.action()
        dismiss()
    }
    
    func moveSelection(by offset: Int) {
        let newIndex = selectedIndex + offset
        selectedIndex = max(0, min(newIndex, filteredCommands.count - 1))
    }
    
    func dismiss() {
        isPresented = false
        searchQuery = ""
        selectedIndex = 0
    }
}

struct CommandPaletteView: View {
    @StateObject private var viewModel = CommandPaletteViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Type a command...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onSubmit {
                        viewModel.executeSelected()
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Commands List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.filteredCommands.enumerated()), id: \.element.id) { index, command in
                        CommandRow(
                            command: command,
                            isSelected: index == viewModel.selectedIndex
                        )
                        .onTapGesture {
                            command.action()
                            viewModel.dismiss()
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
        }
        .frame(width: 600)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 20)
        .onAppear {
            isSearchFocused = true
        }
    }
}

struct CommandRow: View {
    let command: Command
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: command.icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(command.title)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let subtitle = command.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateTo = Notification.Name("navigateTo")
    static let showQuickNote = Notification.Name("showQuickNote")
    static let newTrade = Notification.Name("newTrade")
    static let newPost = Notification.Name("newPost")
    static let newSnippet = Notification.Name("newSnippet")
    static let toggleTheme = Notification.Name("toggleTheme")
    static let showGlobalSearch = Notification.Name("showGlobalSearch")
}
