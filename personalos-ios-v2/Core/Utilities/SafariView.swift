import SwiftUI
import SafariServices

/// Wrapper for SFSafariViewController to use in SwiftUI
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.preferredControlTintColor = UIColor(AppTheme.mistBlue)
        safari.preferredBarTintColor = UIColor(AppTheme.background)
        safari.dismissButtonStyle = .close
        
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

/// Helper struct to make URL identifiable for sheet presentation
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    SafariView(url: URL(string: "https://www.apple.com")!)
}
