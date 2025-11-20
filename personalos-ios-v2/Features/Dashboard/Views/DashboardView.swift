import SwiftUI
import Combine
import SwiftData

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Environment(HealthStoreManager.self) private var healthManager
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var tasks: [TodoItem]
    @Query(sort: \SocialPost.createdAt, order: .reverse) private var posts: [SocialPost]
    @Query(sort: \TradeRecord.entryDate, order: .reverse) private var trades: [TradeRecord]
    @State private var showAddTask = false
    @State private var newTaskTitle = ""
    @State private var showQuickNote = false
    @State private var showTradeLog = false
    @State private var showQRScanner = false
    @State private var focusTimer: Timer?
    @State private var focusTimeRemaining = 25 * 60
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
                        
                        // Focus Session Indicator
                        if isFocusActive {
                            focusSessionBanner
                        }
                        
                        // Configuration prompt if API keys not set
                        if !APIConfig.hasValidStockAPIKey || !APIConfig.hasValidNewsAPIKey {
                            configurationPrompt
                        }
                        
                        healthSection
                        tasksSection
                        ActivityHeatmap(data: activityData)
                        quickAccessGrid
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            .overlay {
                if viewModel.showGlobalSearch {
                    GlobalSearchView(isPresented: $viewModel.showGlobalSearch)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.isError) {
            Button("OK") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .sheet(isPresented: $showQuickNote) {
            QuickNoteOverlay(isPresented: $showQuickNote)
        }
        .sheet(isPresented: $showTradeLog) {
            TradeLogForm()
        }
        .sheet(isPresented: $showQRScanner) {
            QRCodeGeneratorView()
        }
        .onAppear {
            seedTasksIfNeeded()
            updateActivityData()
        }
        .onChange(of: tasks.count) { _, _ in
            updateActivityData()
        }
        .onChange(of: posts.count) { _, _ in
            updateActivityData()
        }
        .onChange(of: trades.count) { _, _ in
            updateActivityData()
        }
    }
    
    // MARK: - Subviews
    
    private var focusSessionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.lavender)
                .frame(width: 44, height: 44)
                .background(AppTheme.lavender.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Mode Active")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                Text("\(focusTimeRemaining / 60):\(String(format: "%02d", focusTimeRemaining % 60)) remaining")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            Spacer()
            
            Button(action: stopFocusSession) {
                Text("Stop")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.coral)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppTheme.lavender.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.lavender.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var configurationPrompt: some View {
        NavigationLink(destination: SettingsView()) {
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.almond)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.almond.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Complete Setup")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Configure API keys to enable real-time data")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .padding()
            .background(AppTheme.almond.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.almond.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.secondaryText)
                Text("\(viewModel.greeting), Creator")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryText)
            }
            Spacer()
            Button(action: { withAnimation { viewModel.showGlobalSearch = true } }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.white).shadow(color: AppTheme.shadow, radius: 8, y: 4))
            }
            .accessibilityLabel("Search")
        }
    }
    
    private var healthSection: some View {
        HealthMetricsSection(healthManager: healthManager)
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Focus")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("\(tasks.filter { !$0.isCompleted }.count) Pending")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.almond.opacity(0.3))
                    .cornerRadius(8)
                Button(action: { showAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.mistBlue)
                }
                .accessibilityLabel("Add Task")
            }
            
            if tasks.isEmpty {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.matcha)
                    Text("All clear! Time to relax.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(16)
            } else {
                ForEach(tasks.prefix(5)) { task in
                    HStack(spacing: 12) {
                        Button(action: { viewModel.toggleTask(task, context: modelContext) }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(task.isCompleted ? AppTheme.matcha : priorityColor(for: task.priority))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.body)
                                .foregroundStyle(AppTheme.primaryText)
                                .strikethrough(task.isCompleted)
                            
                            HStack(spacing: 8) {
                                if let category = task.category {
                                    Text(category)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(AppTheme.primaryText)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(categoryColor(for: category).opacity(0.2))
                                        .clipShape(Capsule())
                                }
                                
                                if task.priority >= 2 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption2)
                                        Text("High")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundStyle(AppTheme.coral)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { viewModel.deleteTask(task, context: modelContext) }) {
                            Image(systemName: "trash")
                                .foregroundStyle(AppTheme.coral)
                                .font(.caption)
                        }
                        .accessibilityLabel("Delete Task")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.shadow, radius: 5, y: 2)
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            NavigationStack {
                VStack(spacing: 20) {
                    TextField("Task title", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    Spacer()
                }
                .navigationTitle("Add Task")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showAddTask = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addTaskIfNeeded()
                        }
                        .disabled(!isNewTaskValid)
                    }
                }
            }
        }
    }
    
    private var quickAccessGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(viewModel.quickActions) { action in
                Button {
                    handleQuickAction(action.title)
                } label: {
                    HStack {
                        Image(systemName: action.icon)
                            .foregroundStyle(action.color)
                            .font(.title3)
                            .frame(width: 40, height: 40)
                            .background(action.color.opacity(0.1))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.primaryText)
                            Text(action.subtitle)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
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
                .buttonStyle(.plain)
            }
        }
    }

    private var isNewTaskValid: Bool {
        !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addTaskIfNeeded() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        viewModel.addTask(title: trimmedTitle, context: modelContext)
        newTaskTitle = ""
        showAddTask = false
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
        focusTimeRemaining = 25 * 60
        HapticsManager.shared.success()
        
        focusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if focusTimeRemaining > 0 {
                focusTimeRemaining -= 1
            } else {
                stopFocusSession()
                HapticsManager.shared.success()
            }
        }
        
        Logger.log("Focus session started (25 min)", category: Logger.general)
    }
    
    private func stopFocusSession() {
        focusTimer?.invalidate()
        focusTimer = nil
        isFocusActive = false
        focusTimeRemaining = 25 * 60
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

    private func seedTasksIfNeeded() {
        guard tasks.isEmpty else { return }
        let defaults = [
            TodoItem(title: "完成 PersonalOS 开发", category: "Work", priority: 2),
            TodoItem(title: "阅读技术文章", category: "Dev", priority: 1),
            TodoItem(title: "健身打卡", category: "Life", priority: 1)
        ]
        defaults.forEach { modelContext.insert($0) }
        try? modelContext.save()
    }
    
    private func updateActivityData() {
        activityData = viewModel.calculateActivityData(tasks: tasks, posts: posts, trades: trades)
    }
}

// MARK: - Health Metrics Section (Optimized for minimal redraws)
struct HealthMetricsSection: View {
    let healthManager: HealthStoreManager
    @State private var showHealthPermission = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(AppTheme.coral)
                Text("Health Overview")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
            }
            
            if !healthManager.isHealthKitAvailable {
                healthUnavailableCard
            } else if healthManager.steps == 0 && healthManager.sleepHours == 0 {
                connectHealthCard
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        #if !targetEnvironment(macCatalyst)
                        ProgressRing(
                            progress: min(Double(healthManager.steps) / 10000.0, 1.0),
                            color: AppTheme.matcha,
                            icon: "figure.walk",
                            title: "Steps",
                            value: "\(healthManager.steps)",
                            unit: ""
                        )
                        #endif
                        
                        ProgressRing(
                            progress: min(healthManager.sleepHours / 8.0, 1.0),
                            color: AppTheme.mistBlue,
                            icon: "bed.double.fill",
                            title: "Sleep",
                            value: String(format: "%.1f", healthManager.sleepHours),
                            unit: "h"
                        )
                        ProgressRing(
                            progress: healthManager.energyLevel,
                            color: AppTheme.coral,
                            icon: "flame.fill",
                            title: "Energy",
                            value: "\(Int(healthManager.energyLevel * 100))",
                            unit: "%"
                        )
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .task {
            await healthManager.syncHealthData()
        }
    }
    
    private var connectHealthCard: some View {
        Button {
            showHealthPermission = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.coral)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.coral.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect Health Data")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Track your steps, sleep, and energy levels")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
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
        .buttonStyle(.plain)
        .sheet(isPresented: $showHealthPermission) {
            HealthPermissionView()
        }
    }
    
    private var healthUnavailableCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.almond)
            
            Text("Health data not available on this device")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding()
        .background(AppTheme.almond.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HealthPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HealthStoreManager.self) private var healthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.coral)
                
                VStack(spacing: 12) {
                    Text("Connect Health Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Allow PersonalOS to read your health data to provide personalized insights and track your wellness journey.")
                        .font(.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    PermissionRow(icon: "figure.walk", title: "Steps", description: "Track daily activity")
                    PermissionRow(icon: "bed.double.fill", title: "Sleep", description: "Monitor sleep quality")
                    PermissionRow(icon: "heart.fill", title: "Heart Rate", description: "Measure wellness")
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                
                Spacer()
                
                Button {
                    Task {
                        await healthManager.requestHealthKitAuthorization()
                        dismiss()
                    }
                } label: {
                    Text("Allow Access")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.coral)
                        .cornerRadius(12)
                }
                
                Button("Maybe Later") {
                    dismiss()
                }
                .foregroundStyle(AppTheme.secondaryText)
            }
            .padding()
            .navigationTitle("Health Access")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.mistBlue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            Spacer()
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
