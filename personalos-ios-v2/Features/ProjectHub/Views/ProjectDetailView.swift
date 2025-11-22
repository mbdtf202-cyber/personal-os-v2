import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: ProjectItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appDependency) private var appDependency
    @State private var showEditSheet = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(project.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.primaryText)
                                
                                Text(project.details)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            StatusBadge(status: project.status)
                        }
                        
                        Divider()
                        
                        // Metadata
                        HStack(spacing: 24) {
                            MetadataItem(icon: "circle.fill", label: project.language, color: AppTheme.mistBlue)
                            MetadataItem(icon: "star.fill", label: "\(project.stars)", color: AppTheme.almond)
                            MetadataItem(icon: "chart.bar.fill", label: "\(Int(project.progress * 100))%", color: AppTheme.matcha)
                        }
                    }
                    .glassCard()
                    
                    // Progress Section
                    if project.status == .active {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Progress")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.1))
                                    Capsule()
                                        .fill(AppTheme.mistBlue)
                                        .frame(width: geo.size.width * project.progress)
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(Int(project.progress * 100))% Complete")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .glassCard()
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        
                        VStack(spacing: 12) {
                            ActionButton(icon: "pencil", title: "Edit Details", color: AppTheme.mistBlue) {
                                showEditSheet = true
                            }
                            
                            ActionButton(icon: "arrow.up.right.square", title: "Open in GitHub", color: AppTheme.almond) {
                                openGitHubURL()
                            }
                            
                            ActionButton(icon: "checkmark.circle", title: "Create Task", color: AppTheme.matcha) {
                                createTask()
                            }
                        }
                    }
                    .glassCard()
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showEditSheet = true }) {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            ProjectEditSheet(project: project)
        }
    }
    
    private func createTask() {
        let task = TodoItem(
            title: "Work on \(project.name)",
            category: "Development",
            priority: 2
        )
        Task {
            do {
                try await appDependency?.repositories.todo.save(task)
                HapticsManager.shared.success()
                Logger.log("Task created for project: \(project.name)", category: Logger.general)
            } catch {
                ErrorHandler.shared.handle(error, context: "ProjectDetailView.createTask")
            }
        }
    }
    
    private func openGitHubURL() {
        // Try to construct GitHub URL from project name
        let username = UserDefaults.standard.string(forKey: "github_username") ?? "user"
        let repoName = project.name.lowercased().replacingOccurrences(of: " ", with: "-")
        
        if let url = URL(string: "https://github.com/\(username)/\(repoName)") {
            UIApplication.shared.open(url)
            HapticsManager.shared.light()
            Logger.log("Opening GitHub URL: \(url.absoluteString)", category: Logger.general)
        }
    }
}

struct MetadataItem: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

struct ProjectEditSheet: View {
    @Bindable var project: ProjectItem
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Project Name", text: $project.name)
                    TextField("Description", text: $project.details, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Details") {
                    Picker("Status", selection: $project.status) {
                        ForEach([ProjectStatus.idea, .active, .done], id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    TextField("Language", text: $project.language)
                    
                    Stepper("Stars: \(project.stars)", value: $project.stars, in: 0...10000)
                    
                    if project.status == .active {
                        HStack {
                            Text("Progress")
                            Spacer()
                            Text("\(Int(project.progress * 100))%")
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Slider(value: $project.progress, in: 0...1)
                    }
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task { @MainActor in
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: ProjectItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let project = ProjectItem(name: "Personal OS", details: "An all-in-one iOS life operating system.", language: "Swift", stars: 124, status: .active, progress: 0.65)
    container.mainContext.insert(project)
    
    return NavigationStack {
        ProjectDetailView(project: project)
            .modelContainer(container)
    }
}
