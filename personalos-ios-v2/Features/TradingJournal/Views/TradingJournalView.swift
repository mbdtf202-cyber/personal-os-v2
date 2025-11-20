import SwiftUI

struct TradingJournalView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("交易复盘")
                            .font(Typography.headlineSmall)
                            .foregroundColor(MorandiColors.textPrimary)
                        Text("记录入场/出场理由、情绪状态")
                            .font(Typography.bodySmall)
                            .foregroundColor(MorandiColors.textSecondary)
                    }
                    .glassCard()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("每日总结")
                            .font(Typography.headlineSmall)
                            .foregroundColor(MorandiColors.textPrimary)
                        Text("盈亏、市场感悟及明日计划")
                            .font(Typography.bodySmall)
                            .foregroundColor(MorandiColors.textSecondary)
                    }
                    .glassCard()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("资产分析")
                            .font(Typography.headlineSmall)
                            .foregroundColor(MorandiColors.textPrimary)
                        Text("A 股、美股、Crypto 等多市场")
                            .font(Typography.bodySmall)
                            .foregroundColor(MorandiColors.textSecondary)
                    }
                    .glassCard()
                }
                .padding(16)
            }
            .background(MorandiColors.background)
            .navigationTitle("交易与投资")
        }
    }
}

#Preview {
    TradingJournalView()
}
