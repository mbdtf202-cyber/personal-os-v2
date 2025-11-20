import SwiftUI

struct SettingsView: View {
    @AppStorage("stockAPIKey") private var stockAPIKey = ""
    @AppStorage("newsAPIKey") private var newsAPIKey = ""
    @State private var showSaveConfirmation = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Configure your API keys to enable real-time data")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                } header: {
                    Text("API Configuration")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stock API Key")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        SecureField("Enter Alpha Vantage API Key", text: $stockAPIKey)
                            .textFieldStyle(.roundedBorder)
                        Link("Get free API key →", destination: URL(string: "https://www.alphavantage.co/support/#api-key")!)
                            .font(.caption)
                            .foregroundStyle(AppTheme.mistBlue)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("News API Key")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        SecureField("Enter NewsAPI.org API Key", text: $newsAPIKey)
                            .textFieldStyle(.roundedBorder)
                        Link("Get free API key →", destination: URL(string: "https://newsapi.org/register")!)
                            .font(.caption)
                            .foregroundStyle(AppTheme.mistBlue)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("API Keys")
                } footer: {
                    Text("Your API keys are stored securely on your device")
                        .font(.caption)
                }
                
                Section {
                    Button(action: {
                        saveAPIKeys()
                    }) {
                        HStack {
                            Spacer()
                            Text("Save Configuration")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundStyle(AppTheme.mistBlue)
                } footer: {
                    if showSaveConfirmation {
                        Text("✓ Configuration saved successfully")
                            .font(.caption)
                            .foregroundStyle(AppTheme.matcha)
                    }
                }
                
                Section {
                    Button(action: exportData) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(AppTheme.mistBlue)
                            Text("Export All Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Export your data as JSON for backup or migration")
                        .font(.caption)
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0.0")
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func saveAPIKeys() {
        // Keys are automatically saved via @AppStorage
        // Update APIConfig to use these values
        withAnimation {
            showSaveConfirmation = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                showSaveConfirmation = false
            }
        }
        
        Logger.log("API keys updated", category: .general)
    }
    
    private func exportData() {
        Task {
            do {
                // Fetch all data
                let todos = try modelContext.fetch(FetchDescriptor<TodoItem>())
                let trades = try modelContext.fetch(FetchDescriptor<TradeRecord>())
                let projects = try modelContext.fetch(FetchDescriptor<ProjectItem>())
                let posts = try modelContext.fetch(FetchDescriptor<SocialPost>())
                
                // Create export data structure
                let exportData: [String: Any] = [
                    "exportDate": ISO8601DateFormatter().string(from: Date()),
                    "version": "2.0.0",
                    "todos": todos.map { ["title": $0.title, "completed": $0.isCompleted, "category": $0.category] },
                    "trades": trades.map { ["symbol": $0.symbol, "type": $0.type.rawValue, "price": $0.price, "quantity": $0.quantity] },
                    "projects": projects.map { ["name": $0.name, "language": $0.language, "stars": $0.stars] },
                    "posts": posts.map { ["title": $0.title, "platform": $0.platform.rawValue, "status": $0.status.rawValue] }
                ]
                
                // Convert to JSON
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                
                // Create temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("PersonalOS_Export_\(Date().timeIntervalSince1970).json")
                try jsonData.write(to: tempURL)
                
                // Share
                await MainActor.run {
                    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootVC = window.rootViewController {
                        activityVC.popoverPresentationController?.sourceView = window
                        rootVC.present(activityVC, animated: true)
                    }
                    
                    HapticsManager.shared.success()
                    Logger.log("Data exported successfully", category: .general)
                }
            } catch {
                Logger.error("Failed to export data: \(error.localizedDescription)", category: .general)
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [TodoItem.self, TradeRecord.self], inMemory: true)
}
