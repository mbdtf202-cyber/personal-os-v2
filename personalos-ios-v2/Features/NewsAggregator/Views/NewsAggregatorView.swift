import SwiftUI

struct NewsAggregatorView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("多源订阅")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("RSS 和 API 抓取")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                    
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("智能阅读")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("自动提取摘要，稍后阅读")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                    
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("链接预览")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("自动抓取元数据")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                }
                .padding(16)
            }
            .background(MorandiColors.background)
            .navigationTitle("资讯聚合")
        }
    }
}

#Preview {
    NewsAggregatorView()
}
