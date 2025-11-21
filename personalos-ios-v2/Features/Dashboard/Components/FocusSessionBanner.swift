import SwiftUI

struct FocusSessionBanner: View {
    let endTime: Date?
    let onStop: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.lavender)
                .frame(width: 44, height: 44)
                .background(AppTheme.lavender.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Mode Active")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                
                if let endTime = endTime {
                    Text(endTime, style: .timer)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .monospacedDigit()
                }
            }
            
            Spacer()
            
            Button(action: onStop) {
                Text("Stop")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.coral)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppTheme.lavender.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.lavender.opacity(0.3), lineWidth: 1)
        )
    }
}
