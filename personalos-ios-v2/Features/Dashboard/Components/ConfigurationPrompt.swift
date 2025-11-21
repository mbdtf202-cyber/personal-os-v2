import SwiftUI

struct ConfigurationPrompt: View {
    var body: some View {
        NavigationLink(destination: SettingsView()) {
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.almond)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.almond.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Complete Setup")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Configure API keys to enable real-time data")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .padding()
            .background(AppTheme.almond.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.almond.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
