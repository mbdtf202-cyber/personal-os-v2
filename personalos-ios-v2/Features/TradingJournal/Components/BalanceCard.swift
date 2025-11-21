import SwiftUI

struct BalanceCard: View {
    let totalBalance: Double
    let dayPnL: Double
    let dayPnLPercent: Double
    
    private var isPositive: Bool {
        dayPnL >= 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
            Text("$\(totalBalance, specifier: "%.2f")")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
            HStack {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                Text("\(isPositive ? "+" : "-")$\(abs(dayPnL), specifier: "%.2f") (\(abs(dayPnLPercent), specifier: "%.2f")%)")
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(isPositive ? AppTheme.matcha : AppTheme.coral)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background((isPositive ? AppTheme.matcha : AppTheme.coral).opacity(0.15))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}
