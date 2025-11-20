import Foundation

// MARK: - 仪表盘相关模型 (使用 Codable 而不是 @Model)

struct DailyOverview: Identifiable, Codable {
    var id: String
    var date: Date
    var todayTasks: Int = 0
    var completedTasks: Int = 0
    var healthCheckIn: Bool = false
    var mood: String = ""
    
    init(date: Date = Date()) {
        self.id = UUID().uuidString
        self.date = date
    }
}

struct HealthCheckIn: Identifiable, Codable {
    var id: String
    var date: Date
    var sleepHours: Double = 0
    var exerciseMinutes: Int = 0
    var moodScore: Int = 5
    var energyLevel: Int = 5
    var stressLevel: Int = 5
    
    init(date: Date = Date()) {
        self.id = UUID().uuidString
        self.date = date
    }
}

// MARK: - Knowledge Base Models

struct CodeSnippet: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let language: String
    let code: String
    let summary: String
    let category: KnowledgeCategory
    let date: Date
}

enum KnowledgeCategory: String, CaseIterable {
    case swift = "Swift"
    case python = "Python"
    case ai = "AI/ML"
    case devops = "DevOps"
    case web = "Web"
    case database = "Database"
    
    var color: Color {
        switch self {
        case .swift: return AppTheme.coral
        case .python: return AppTheme.mistBlue
        case .ai: return AppTheme.lavender
        case .devops: return AppTheme.almond
        case .web: return AppTheme.matcha
        case .database: return .indigo
        }
    }
    
    var icon: String {
        switch self {
        case .swift: return "swift"
        case .python: return "terminal.fill"
        case .ai: return "brain.head.profile"
        case .devops: return "server.rack"
        case .web: return "globe"
        case .database: return "cylinder.fill"
        }
    }
}

import SwiftUI
