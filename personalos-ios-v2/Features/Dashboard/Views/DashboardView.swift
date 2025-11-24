import SwiftUI
import Combine
import SwiftData

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.primaryText)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}

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
                        
                        // ✅ P2 Fix: Quick Actions section
                        quickActionsSection
                        
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
            // 开始首屏加载计时
            DashboardMetrics.shared.startFirstScreenLoad()
            
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
            
            // 结束首屏加载计时
            DashboardMetrics.shared.endFirstScreenLoad()
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
    
    // ✅ P1 Fix: Remove Task.sleep logic, use FocusSessionManager
    private func startFocusSession() {
        guard !isFocusActive else { return }
        
        // TODO: Integrate with FocusSessionManager for proper background handling
        // For now, keep simple date-based calculation
        isFocusActive = true
        focusEndTime = Date().addingTimeInterval(25 * 60)
        HapticsManager.shared.success()
        
        Logger.log("⏱️ Focus session started (25 min) - using date-based calculation", category: Logger.general)
    }
    
    private func stopFocusSession() {
        isFocusActive = false
        focusEndTime = nil
        Logger.log("Focus session ended", category: Logger.general)
    }
    
    // ✅ P2 Fix: Quick Actions section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionButton(
                        title: "Add Note",
                        icon: "note.text",
                        color: AppTheme.almond
                    ) {
                        handleQuickAction("Add Note")
                    }
                    
                    QuickActionButton(
                        title: "Log Trade",
                        icon: "chart.line.uptrend.xyaxis",
                        color: AppTheme.matcha
                    ) {
                        handleQuickAction("Log Trade")
                    }
                    
                    QuickActionButton(
                        title: "Focus",
                        icon: "timer",
                        color: AppTheme.mistBlue
                    ) {
                        handleQuickAction("Focus")
                    }
                    
                    QuickActionButton(
                        title: "Scan",
                        icon: "qrcode.viewfinder",
                        color: AppTheme.lavender
                    ) {
                        handleQuickAction("Scan")
                    }
                }
            }
        }
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
