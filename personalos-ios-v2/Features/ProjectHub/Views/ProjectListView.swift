import SwiftUI

struct ProjectItem: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var language: String
    var stars: Int
    var status: ProjectStatus
    var progress: Double
}

enum ProjectStatus: String {
    case active = "Active"
    case idea = "Idea"
    case done = "Done"
    
    var color: Color {
        switch self {
        case .active: return AppTheme.mistBlue
        case .idea: return AppTheme.almond
        case .done: return AppTheme.matcha
        }
    }
}

struct ProjectListView: View {
    let projects = [
        ProjectItem(name: "Personal OS", description: "An all-in-one iOS life operating system.", language: "Swift", stars: 124, status: .active, progress: 0.65),
        ProjectItem(name: "AI Agent API", description: "Python backend for LLM processing.", language: "Python", stars: 45, status: .active, progress: 0.3),
        ProjectItem(name: "Portfolio Site", description: "Next.js static site.", language: "TypeScript", stars: 12, status: .done, progress: 1.0),
        ProjectItem(name: "Smart Home Hub", description: "IoT control center ideas.", language: "C++", stars: 0, status: .idea, progress: 0.0)
    ]
    
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
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
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
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Project Hub")
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
                    Text(project.description)
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
