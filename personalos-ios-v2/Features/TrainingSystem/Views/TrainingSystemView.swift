import SwiftUI

struct TrainingSystemView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("领域管理")
                            .font(Typography.headlineSmall)
                            .foregroundColor(AppTheme.primaryText)
                        Text("产品、前后端、DevOps、AI 等")
                            .font(Typography.bodySmall)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.shadow, radius: 8, y: 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("知识笔记")
                            .font(Typography.headlineSmall)
                            .foregroundColor(AppTheme.primaryText)
                        Text("支持 Markdown 的深度技术笔记")
                            .font(Typography.bodySmall)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.shadow, radius: 8, y: 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("代码片段")
                            .font(Typography.headlineSmall)
                            .foregroundColor(AppTheme.primaryText)
                        Text("收藏和复用常用的代码块")
                            .font(Typography.bodySmall)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: AppTheme.shadow, radius: 8, y: 4)
                }
                .padding(16)
            }
            .background(AppTheme.background)
            .navigationTitle("技能与知识库")
        }
    }
}

#Preview {
    TrainingSystemView()
}
