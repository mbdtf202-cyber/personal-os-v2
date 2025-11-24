import SwiftUI

/// ✅ P0 Task 19: Legal document viewer
/// Requirement 17.5: Display legal documents in Settings
enum LegalDocumentType {
    case termsOfService
    case privacyPolicy
    case licenses
    
    var title: String {
        switch self {
        case .termsOfService:
            return "Terms of Service"
        case .privacyPolicy:
            return "Privacy Policy"
        case .licenses:
            return "Third-Party Licenses"
        }
    }
    
    var fileName: String {
        switch self {
        case .termsOfService:
            return "TERMS_OF_SERVICE"
        case .privacyPolicy:
            return "PRIVACY_POLICY"
        case .licenses:
            return "THIRD_PARTY_LICENSES"
        }
    }
}

struct LegalDocumentView: View {
    let documentType: LegalDocumentType
    @State private var content: String = ""
    @State private var isLoading = true
    @State private var error: String?
    
    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading document...")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.coral)
                    Text("Failed to load document")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text(content)
                        .font(.system(.body, design: .default))
                        .foregroundStyle(AppTheme.primaryText)
                }
                .padding()
            }
        }
        .background(AppTheme.background)
        .navigationTitle(documentType.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDocument()
        }
    }
    
    private func loadDocument() {
        Task {
            do {
                // Try to load from bundle
                if let fileURL = Bundle.main.url(forResource: documentType.fileName, withExtension: "md") {
                    let documentContent = try String(contentsOf: fileURL, encoding: .utf8)
                    await MainActor.run {
                        content = documentContent
                        isLoading = false
                    }
                } else {
                    // Fallback content if file not found
                    await MainActor.run {
                        content = getFallbackContent()
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
                Logger.error("Failed to load legal document: \(error)", category: Logger.general)
            }
        }
    }
    
    private func getFallbackContent() -> String {
        switch documentType {
        case .termsOfService:
            return """
            # Terms of Service
            
            Last Updated: November 24, 2024
            
            By using Personal OS, you agree to these terms.
            
            ## Key Points
            
            - Use the app responsibly and lawfully
            - You are responsible for your data accuracy
            - Financial features are for informational purposes only
            - Health data should not replace professional medical advice
            
            For the complete Terms of Service, please visit our website or contact support.
            """
            
        case .privacyPolicy:
            return """
            # Privacy Policy
            
            Last Updated: November 24, 2024
            
            ## Your Privacy Matters
            
            Personal OS is designed with privacy as a core principle:
            
            - **No Data Collection**: We do not collect, store, or transmit your personal data to our servers
            - **Local Storage**: All data stays on your device
            - **iCloud Sync**: Optional, uses your personal iCloud account
            - **Third-Party APIs**: You control your own API keys
            - **HealthKit**: Data remains on your device
            
            For the complete Privacy Policy, please visit our website or contact support.
            """
            
        case .licenses:
            return """
            # Third-Party Licenses
            
            Personal OS uses the following third-party components:
            
            ## Apple Frameworks
            
            - SwiftUI, SwiftData, Combine, Foundation, HealthKit, etc.
            - Licensed under Apple SDK License Agreement
            
            ## Open Source
            
            Currently, Personal OS primarily uses Apple's native frameworks and does not include external open-source dependencies.
            
            For the complete list of licenses, please visit our website or contact support.
            """
        }
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(documentType: .privacyPolicy)
    }
}
