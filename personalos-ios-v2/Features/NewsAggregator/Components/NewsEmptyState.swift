import SwiftUI

struct NewsEmptyState: View {
    let message: String
    let onRetry: (() async -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.secondaryText)
            
            Text(message)
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
            
            if let onRetry = onRetry {
                Button(L.Common.retry) {
                    Task {
                        await onRetry()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
