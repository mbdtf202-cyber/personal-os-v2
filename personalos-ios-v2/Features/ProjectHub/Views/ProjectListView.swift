import SwiftUI

// Models moved to UnifiedSchema.swift

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GitHubService.self) private var githubService
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
                                ProjectRow(project: project)
                            }
                        }
                        
                        // GitHub Sync Button
                        Button(action: { showGitHubSync = true }) {
                            HStack {
                                Image(systemName: githubService.isLoading ? "arrow.triangle.2.circlepath" : "arrow.triangle.2.circlepath")
                                    .symbolEffect(.rotate, isActive: githubService.isLoading)
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
        let defaults = [
            ProjectItem(name: "Personal OS", details: "An all-in-one iOS life operating system.", language: "Swift", stars: 124, status: .active, progress: 0.65),
            ProjectItem(name: "AI Agent API", details: "Python backend for LLM processing.", language: "Python", stars: 45, status: .active, progress: 0.3),
            ProjectItem(name: "Portfolio Site", details: "Next.js static site.", language: "TypeScript", stars: 12, status: .done, progress: 1.0),
            ProjectItem(name: "Smart Home Hub", details: "IoT control center ideas.", language: "C++", stars: 0, status: .idea, progress: 0.0)
        ]
        defaults.forEach { modelContext.insert($0) }
        try? modelContext.save()
    }
}

struct GitHubSyncSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GitHubService.self) private var githubService
    @Environment(\.dismiss) var dismiss
    @State private var username = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("GitHub Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button("Sync Repositories") {
                    Task {
                        await githubService.fetchUserRepos(username: username)
                        syncProjects()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(username.isEmpty || githubService.isLoading)
                
                if githubService.isLoading {
                    LoadingView(message: "Fetching repositories...")
                        .frame(height: 100)
                }
                
                if let error = githubService.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
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
        // Clear existing projects before syncing
        let fetchDescriptor = FetchDescriptor<ProjectItem>()
        if let existingProjects = try? modelContext.fetch(fetchDescriptor) {
            existingProjects.forEach { modelContext.delete($0) }
        }
        
        // Insert new projects from GitHub
        githubService.repos.forEach { repo in
            let project = ProjectItem(
                name: repo.name,
                details: repo.description ?? "No description",
                language: repo.language ?? "Unknown",
                stars: repo.stargazersCount,
                status: .active,
                progress: 0.5
            )
            modelContext.insert(project)
        }
        
        try? modelContext.save()
        HapticsManager.shared.success()
        Logger.log("Synced \(githubService.repos.count) projects from GitHub", category: .general)
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
    ProjectListView()
}
