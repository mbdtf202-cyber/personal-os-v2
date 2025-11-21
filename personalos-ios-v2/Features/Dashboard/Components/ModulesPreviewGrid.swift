import SwiftUI

struct ModulesPreviewGrid: View {
    let trades: [TradeRecord]
    let projects: [ProjectItem]
    let posts: [SocialPost]
    let router: AppRouter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                PreviewCard(
                    title: "Wealth",
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppTheme.almond,
                    mainText: trades.first.map { "\($0.symbol)" } ?? "No trades",
                    subText: trades.first.map { "$\(NSDecimalNumber(decimal: $0.price).doubleValue.formatted(.number.precision(.fractionLength(2))))" } ?? "Start investing"
                )
                .onTapGesture {
                    router.navigate(to: .wealth)
                }
                
                PreviewCard(
                    title: "Active Project",
                    icon: "hammer.fill",
                    color: AppTheme.mistBlue,
                    mainText: projects.first?.name ?? "No Projects",
                    subText: projects.first.map { "Progress: \(Int($0.progress * 100))%" } ?? "Start building"
                )
                .onTapGesture {
                    router.navigate(to: .growth)
                }
                
                PreviewCard(
                    title: "Social",
                    icon: "bubble.left.fill",
                    color: AppTheme.lavender,
                    mainText: posts.first?.title ?? "No Posts",
                    subText: posts.first?.status.rawValue ?? "Create content"
                )
                .onTapGesture {
                    router.navigate(to: .social)
                }
                
                NavigationLink(destination: SettingsView()) {
                    PreviewCard(
                        title: "System",
                        icon: "gearshape.fill",
                        color: .gray,
                        mainText: "Settings",
                        subText: "Config & Data"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PreviewCard: View {
    let title: String
    let icon: String
    let color: Color
    let mainText: String
    let subText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mainText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                
                Text(subText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
    }
}
