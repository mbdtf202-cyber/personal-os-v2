import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var stockAPIKey = ""
    @State private var newsAPIKey = ""
    @AppStorage("selectedTheme") private var selectedTheme: String = ThemeStyle.glass.rawValue
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("enableNotifications") private var enableNotifications = true
    @State private var showSaveConfirmation = false
    @State private var showClearDataAlert = false
    @Environment(\.modelContext) private var modelContext
    
    private let keychain = KeychainManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                // Theme Section
                Section {
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(ThemeStyle.allCases) { theme in
                            HStack {
                                Text(theme.title)
                                Spacer()
                                Text(theme.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .tag(theme.rawValue)
                        }
                    }
                    .onChange(of: selectedTheme) { _, newValue in
                        if let theme = ThemeStyle(rawValue: newValue) {
                            AppTheme.apply(style: theme)
                            HapticsManager.shared.light()
                        }
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose your preferred visual style")
                        .font(.caption)
                }
                
                // Preferences Section
                Section {
                    Toggle("Haptic Feedback", isOn: $enableHaptics)
                    Toggle("Notifications", isOn: $enableNotifications)
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Customize your app experience")
                        .font(.caption)
                }
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
                    
                    Button(role: .destructive, action: { showClearDataAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Data")
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
            .alert("Clear All Data?", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your data. This action cannot be undone.")
            }
            .onAppear {
                loadAPIKeys()
            }
        }
    }
    
    private func loadAPIKeys() {
        stockAPIKey = keychain.getAPIKey(for: AppConfig.Keys.stockAPIKey) ?? ""
        newsAPIKey = keychain.getAPIKey(for: AppConfig.Keys.newsAPIKey) ?? ""
    }
    
    private func saveAPIKeys() {
        // 保存到 Keychain（安全存储）
        keychain.saveAPIKey(stockAPIKey, for: AppConfig.Keys.stockAPIKey)
        keychain.saveAPIKey(newsAPIKey, for: AppConfig.Keys.newsAPIKey)
        
        withAnimation {
            showSaveConfirmation = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                showSaveConfirmation = false
            }
        }
        
        HapticsManager.shared.success()
        Logger.log("API keys saved securely to Keychain", category: Logger.general)
    }
    
    private func clearAllData() {
        Task {
            // 🔧 P2 Fix: 使用统一的错误处理，确保用户知道哪一步失败
            var errors: [String] = []
            
            do {
                try await RepositoryContainer.shared.todoRepository.deleteAll()
            } catch {
                errors.append("Todos")
                Logger.error("Failed to delete todos: \(error)", category: Logger.general)
            }
            
            do {
                try await RepositoryContainer.shared.tradeRepository.deleteAll()
            } catch {
                errors.append("Trades")
                Logger.error("Failed to delete trades: \(error)", category: Logger.general)
            }
            
            do {
                try await RepositoryContainer.shared.projectRepository.deleteAll()
            } catch {
                errors.append("Projects")
                Logger.error("Failed to delete projects: \(error)", category: Logger.general)
            }
            
            do {
                try await RepositoryContainer.shared.socialPostRepository.deleteAll()
            } catch {
                errors.append("Social Posts")
                Logger.error("Failed to delete social posts: \(error)", category: Logger.general)
            }
            
            do {
                try await RepositoryContainer.shared.codeSnippetRepository.deleteAll()
            } catch {
                errors.append("Code Snippets")
                Logger.error("Failed to delete code snippets: \(error)", category: Logger.general)
            }
            
            if errors.isEmpty {
                HapticsManager.shared.success()
                Logger.log("All data cleared successfully", category: Logger.general)
            } else {
                let errorMessage = "Failed to delete: \(errors.joined(separator: ", "))"
                ErrorHandler.shared.handle(
                    AppError.database(errorMessage),
                    context: "SettingsView.clearAllData"
                )
            }
        }
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
                    Logger.log("Data exported successfully", category: Logger.general)
                }
            } catch {
                Logger.error("Failed to export data: \(error.localizedDescription)", category: Logger.general)
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [TodoItem.self, TradeRecord.self], inMemory: true)
}
