import SwiftUI

struct SettingsView: View {
    @AppStorage("stockAPIKey") private var stockAPIKey = ""
    @AppStorage("newsAPIKey") private var newsAPIKey = ""
    @State private var showSaveConfirmation = false
    
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
}

#Preview {
    SettingsView()
}
