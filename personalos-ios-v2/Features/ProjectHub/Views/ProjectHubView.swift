import SwiftUI

struct ProjectHubView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("作品集展示")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("管理个人项目，自动抓取 GitHub 信息")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                    
                    FrostedCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("状态追踪")
                                .font(Typography.headlineSmall)
                                .foregroundColor(MorandiColors.textPrimary)
                            Text("Idea → 进行中 → 已完成")
                                .font(Typography.bodySmall)
                                .foregroundColor(MorandiColors.textSecondary)
                        }
                    }
                }
                .padding(16)
            }
            .background(MorandiColors.background)
            .navigationTitle("项目管理")
        }
    }
}

#Preview {
    ProjectHubView()
}
