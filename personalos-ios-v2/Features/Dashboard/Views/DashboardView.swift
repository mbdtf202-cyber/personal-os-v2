import SwiftUI
import Combine
import SwiftData

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Environment(HealthStoreManager.self) private var healthManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdAt, order: .reverse) private var tasks: [TodoItem]
    @State private var showAddTask = false
    @State private var newTaskTitle = ""
    @State private var quickActionMessage: String?

    init() {}

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        healthSection
                        tasksSection
                        ActivityHeatmap()
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
        .alert("Action Ready", isPresented: Binding(
            get: { quickActionMessage != nil },
            set: { isPresented in
                if !isPresented { quickActionMessage = nil }
            }
        )) {
            Button("OK") {
                quickActionMessage = nil
            }
        } message: {
            if let message = quickActionMessage {
                Text(message)
            }
        }
        .onAppear(perform: seedTasksIfNeeded)
    }
    
    // MARK: - Subviews
    
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ProgressRing(
                    progress: min(Double(healthManager.steps) / 10000.0, 1.0),
                    color: AppTheme.matcha,
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(healthManager.steps)",
                    unit: ""
                )
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
        .task {
            await healthManager.syncHealthData()
        }
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
                    HStack {
                        Button(action: { viewModel.toggleTask(task, context: modelContext) }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isCompleted ? AppTheme.matcha : AppTheme.mistBlue)
                        }
                        Text(task.title)
                            .foregroundStyle(AppTheme.primaryText)
                            .strikethrough(task.isCompleted)
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
            ForEach(viewModel.quickActions, id: \.title) { action in
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
        quickActionMessage = "\(title) 已准备就绪，稍后将在对应模块中执行。"
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
}

#Preview {
    DashboardView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
