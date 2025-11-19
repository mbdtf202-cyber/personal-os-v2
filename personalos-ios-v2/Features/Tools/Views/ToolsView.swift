import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("工作流")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("创建自定义自动化任务")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                    
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("书签管理")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("结构化管理网络资源")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                    
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("闪念笔记")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("随时记录瞬时灵感")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                }
                .padding(16)
            }
            .background(MorandiColors.background)
            .navigationTitle("效率工具")
        }
    }
}

#Preview {
    ToolsView()
}
