import SwiftUI

struct PriceErrorBanner: View {
    let error: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.coral)
            VStack(alignment: .leading, spacing: 4) {
                Text("Price Update Failed")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .padding()
        .background(AppTheme.coral.opacity(0.1))
        .cornerRadius(12)
    }
}
