import SwiftUI

struct SocialBlogView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("博客系统")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("全功能 Markdown 编辑器")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                    
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("社媒运营")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("小红书/X/公众号内容日历")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                    
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("数据追踪")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("阅读、点赞、收藏数据分析")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                }
                .padding(16)
            }
            .background(MorandiColors.background)
            .navigationTitle("内容创作与社媒")
        }
    }
}

#Preview {
    SocialBlogView()
}
