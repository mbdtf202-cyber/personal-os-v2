import SwiftUI
import Combine
import SwiftData

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel?
    @Environment(HealthStoreManager.self) private var healthManager
    @Environment(AppRouter.self) private var router
    @Environment(\.appDependency) private var appDependency
    @Environment(\.modelContext) private var modelContext
    
    private var tasks: [TodoItem] {
        viewModel?.recentTasks ?? []
    }
    
    private var posts: [SocialPost] {
        viewModel?.recentPosts ?? []
    }
    
    private var trades: [TradeRecord] {
        viewModel?.recentTrades ?? []
    }
    
    private var projects: [ProjectItem] {
        viewModel?.recentProjects ?? []
    }
    @State private var newTaskTitle = ""
    @State private var showQuickNote = false
    @State private var showTradeLog = false
    @State private var showQRScanner = false
    @State private var focusEndTime: Date?
    @State private var isFocusActive = false
    @State private var activityData: [(String, Double)] = []

    init() {}

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        
                        if isFocusActive {
                            FocusSessionBanner(endTime: focusEndTime, onStop: stopFocusSession)
                        }
                        
                        if !APIConfig.hasValidStockAPIKey || !APIConfig.hasValidNewsAPIKey {
                            ConfigurationPrompt()
                        }
                        
                        HealthMetricsSection(healthManager: healthManager)
                        tasksSection
                        ModulesPreviewGrid(trades: trades, projects: projects, posts: posts, router: router)
                        // ActivityHeatmap(data: activityData)
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            .overlay {
                if let vm = viewModel, vm.showGlobalSearch {
                    GlobalSearchView(isPresented: Binding(
                        get: { vm.showGlobalSearch },
                        set: { vm.showGlobalSearch = $0 }
                    ))
                }
            }
        }
        .handleErrors(from: viewModel ?? DashboardViewModel(
            todoRepository: appDependency?.repositories.todo ?? TodoRepository(modelContext: modelContext),
            modelContext: modelContext
        ))
        .sheet(isPresented: $showQuickNote) {
            QuickNoteOverlay(isPresented: $showQuickNote)
        }
        .sheet(isPresented: $showTradeLog) {
            TradeLogForm()
        }
        .task {
            // ✅ P2 Fix: 使用 .task 自动管理 ViewModel 生命周期
            if viewModel == nil, let dependency = appDependency {
                viewModel = DashboardViewModel(
                    todoRepository: dependency.repositories.todo,
                    modelContext: modelContext
                )
            }
            await viewModel?.loadRecentData()
            if let vm = viewModel {
                activityData = await vm.calculateActivityData()
            }
        }
        .sheet(isPresented: $showQRScanner) {
            QRCodeGeneratorView()
        }

    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        DashboardHeader(
            greeting: viewModel?.greeting ?? "Good Day",
            onSearchTap: {
                viewModel?.showGlobalSearch = true
            }
        )
    }
    
    private var tasksSection: some View {
        VStack(spacing: 16) {
            TasksSection(
                tasks: tasks,
                onToggleTask: { task in
                    await viewModel?.toggleTask(task)
                },
                onDeleteTask: { task in
                    await viewModel?.deleteTask(task)
                }
            )
            
            AddTaskSection(
                newTaskTitle: $newTaskTitle,
                onAddTask: addTaskIfNeeded
            )
        }
    }
    
    private func addTaskIfNeeded() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        Task { 
            await viewModel?.addTask(title: trimmedTitle)
            newTaskTitle = ""
        }
    }

    private func handleQuickAction(_ title: String) {
        HapticsManager.shared.light()
        
        switch title {
        case "Add Note":
            showQuickNote = true
            
        case "Log Trade":
            showTradeLog = true
            
        case "Focus":
            startFocusSession()
            
        case "Scan":
            showQRScanner = true
            
        default:
            break
        }
    }
    
    private func startFocusSession() {
        guard !isFocusActive else { return }
        
        isFocusActive = true
        focusEndTime = Date().addingTimeInterval(25 * 60) // 25 minutes from now
        HapticsManager.shared.success()
        
        Logger.log("Focus session started (25 min)", category: Logger.general)
        
        // Schedule notification for when focus ends (optional)
        Task {
            try? await Task.sleep(nanoseconds: 25 * 60 * 1_000_000_000)
            if isFocusActive {
                stopFocusSession()
                HapticsManager.shared.success()
            }
        }
    }
    
    private func stopFocusSession() {
        isFocusActive = false
        focusEndTime = nil
        Logger.log("Focus session ended", category: Logger.general)
    }
    
    private func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 2...: return AppTheme.coral
        case 1: return AppTheme.almond
        default: return AppTheme.mistBlue
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "work": return AppTheme.mistBlue
        case "dev", "development": return AppTheme.lavender
        case "life", "personal": return AppTheme.matcha
        case "health": return AppTheme.matcha
        default: return AppTheme.almond
        }
    }


}

#Preview {
    DashboardView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
