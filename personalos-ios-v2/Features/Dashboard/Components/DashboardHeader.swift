import SwiftUI

struct DashboardHeader: View {
    let greeting: String
    let onSearchTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome Back")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.secondaryText)
                Text("\(greeting), Creator")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryText)
            }
            Spacer()
            Button(action: { 
                withAnimation { 
                    onSearchTap()
                } 
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(AppTheme.primaryText)
            }
        }
        .padding(.horizontal)
    }
}
