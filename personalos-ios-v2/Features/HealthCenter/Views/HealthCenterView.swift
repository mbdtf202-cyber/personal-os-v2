import SwiftUI

struct HealthCenterView: View {
    @State private var viewModel = HealthCenterViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("今日日志")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            
                            Text("睡眠、运动、心情等数据记录")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                    
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("习惯养成")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            
                            Text("追踪每日/每周/每月习惯")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                    
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("趋势分析")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            
                            Text("发现生活习惯与身心状态的关联")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                }
                .padding(16)
            }
            .background(MorandiColors.background)
            .navigationTitle("健康管理")
        }
    }
}

#Preview {
    HealthCenterView()
}
