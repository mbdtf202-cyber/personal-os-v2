import SwiftUI
import SwiftData

// Models moved to UnifiedSchema.swift

struct ProjectListView: View {
    @Environment(GitHubService.self) private var githubService
    @Environment(\.appDependency) private var appDependency
    @Query(sort: \ProjectItem.name) private var projects: [ProjectItem]
    @State private var showGitHubSync = false
    @State private var githubUsername = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Stats
                        HStack(spacing: 16) {
                            ProjectStatCard(title: "Active", value: "2", color: AppTheme.mistBlue)
                            ProjectStatCard(title: "Shipped", value: "12", color: AppTheme.matcha)
                            ProjectStatCard(title: "Stars", value: "181", color: AppTheme.almond)
                        }
                        
                        // Projects List
                        LazyVStack(spacing: 16) {
                            ForEach(projects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectRow(project: project)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // GitHub Sync Button
                        Button(action: { showGitHubSync = true }) {
                            HStack {
                                if githubService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text("Sync with GitHub")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(16)
                            .shadow(radius: 5)
                        }
                        .disabled(githubService.isLoading)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Project Hub")
            .sheet(isPresented: $showGitHubSync) {
                GitHubSyncSheet()
            }
            .onAppear {
                seedProjectsIfNeeded()
            }
        }
    }
    
    private func seedProjectsIfNeeded() {
        guard projects.isEmpty else { return }
        Task {
            let defaults = [
                ProjectItem(name: "Personal OS", details: "An all-in-one iOS life operating system.", language: "Swift", stars: 124, status: .active, progress: 0.65),
                ProjectItem(name: "AI Agent API", details: "Python backend for LLM processing.", language: "Python", stars: 45, status: .active, progress: 0.3),
                ProjectItem(name: "Portfolio Site", details: "Next.js static site.", language: "TypeScript", stars: 12, status: .done, progress: 1.0),
                ProjectItem(name: "Smart Home Hub", details: "IoT control center ideas.", language: "C++", stars: 0, status: .idea, progress: 0.0)
            ]
            for project in defaults {
                try? await appDependency?.repositories.project.save(project)
            }
        }
    }
}

struct GitHubSyncSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GitHubService.self) private var githubService
    @Environment(\.dismiss) var dismiss
    @State private var username = ""
    @State private var showSuccessMessage = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if showSuccessMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.matcha)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sync Complete!")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            Text("Synced \(githubService.repos.count) repositories")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.matcha.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                TextField("GitHub Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button("Sync Repositories") {
                    Task {
                        await githubService.fetchUserRepos(username: username)
                        if githubService.syncSuccess {
                            syncProjects()
                            showSuccessMessage = true
                            HapticsManager.shared.success()
                            
                            // Auto dismiss after 1.5 seconds
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(username.isEmpty || githubService.isLoading)
                
                if githubService.isLoading {
                    LoadingView(message: "Fetching repositories...")
                        .frame(height: 100)
                }
                
                if let error = githubService.error {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.coral)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding()
                    .background(AppTheme.coral.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Sync with GitHub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func syncProjects() {
        // Save GitHub username for later use
        UserDefaults.standard.set(username, forKey: "github_username")
        
        Task {
            do {
                // Clear existing projects
                try await appDependency?.repositories.project.deleteAll()
                
                // Insert new projects from GitHub
                for repo in githubService.repos {
                    let project = ProjectItem(
                        name: repo.name,
                        details: repo.description ?? "No description",
                        language: repo.language ?? "Unknown",
                        stars: repo.stargazersCount,
                        status: .active,
                        progress: 0.5
                    )
                    try await appDependency?.repositories.project.save(project)
                }
                
                Logger.log("Synced \(githubService.repos.count) projects from GitHub", category: Logger.general)
            } catch {
                ErrorHandler.shared.handle(error, context: "GitHubSyncSheet.syncProjects")
            }
        }
    }
}

struct ProjectStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.primaryText)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct ProjectRow: View {
    let project: ProjectItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(project.details)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                Spacer()
                StatusBadge(status: project.status)
            }
            
            HStack {
                Label(project.language, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .imageScale(.small)
                Spacer()
                Label("\(project.stars)", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.almond)
            }
            
            // Progress Bar
            if project.status == .active {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                        Capsule()
                            .fill(AppTheme.mistBlue)
                            .frame(width: geo.size.width * project.progress)
                    }
                }
                .frame(height: 4)
            }
        }
        .glassCard()
    }
}

struct StatusBadge: View {
    let status: ProjectStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.15))
            .foregroundStyle(status.color)
            .cornerRadius(8)
    }
}

#Preview {
    let container = try! ModelContainer(for: ProjectItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    ProjectListView()
        .modelContainer(container)
        .environment(GitHubService())
}
