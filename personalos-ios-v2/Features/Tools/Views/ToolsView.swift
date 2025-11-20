import SwiftUI

struct ToolsView: View {
    private let tools: [ToolItem] = [
        .init(title: "工作流", subtitle: "创建可重复的自动化任务", icon: "bolt.badge.clock", accent: AppTheme.lavender, primaryAction: "创建新的自动化"),
        .init(title: "书签管理", subtitle: "结构化管理网络资源", icon: "bookmark.circle", accent: AppTheme.mistBlue, primaryAction: "添加书签"),
        .init(title: "闪念笔记", subtitle: "随时记录瞬时灵感", icon: "lightbulb", accent: AppTheme.almond, primaryAction: "记录灵感"),
        .init(title: "数据同步", subtitle: "跨设备保持资料一致", icon: "arrow.triangle.2.circlepath", accent: AppTheme.matcha, primaryAction: "立即同步")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(tools) { tool in
                        NavigationLink {
                            ToolDetailView(tool: tool)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: tool.icon)
                                        .font(.title2)
                                        .foregroundStyle(tool.accent)
                                        .frame(width: 44, height: 44)
                                        .background(tool.accent.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(tool.title)
                                            .font(Typography.headlineSmall)
                                            .foregroundColor(MorandiColors.textPrimary)
                                        Text(tool.subtitle)
                                            .font(Typography.bodySmall)
                                            .foregroundColor(MorandiColors.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.footnote)
                                        .foregroundStyle(MorandiColors.textSecondary)
                                }
                            }
                            .glassCard()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("打开 \(tool.title) 工具")
                    }
                }
                .padding(16)
            }
            .background(MorandiColors.background)
            .navigationTitle("效率工具")
        }
    }
}

struct ToolItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let primaryAction: String
}

struct ToolDetailView: View {
    let tool: ToolItem
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: tool.icon)
                        .font(.title2)
                        .foregroundStyle(tool.accent)
                        .frame(width: 48, height: 48)
                        .background(tool.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tool.title)
                            .font(Typography.headlineLarge)
                            .foregroundColor(MorandiColors.textPrimary)
                        Text(tool.subtitle)
                            .font(Typography.bodyMedium)
                            .foregroundColor(MorandiColors.textSecondary)
                    }
                }

                // OCR 工具
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title2)
                            .foregroundColor(MorandiColors.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(MorandiColors.textSecondary)
                    }
                    
                    Text("OCR 扫描")
                        .font(Typography.headlineSmall)
                        .foregroundColor(MorandiColors.textPrimary)
                    
                    Text("提取图片中的文字")
                        .font(Typography.bodySmall)
                        .foregroundColor(MorandiColors.textSecondary)
                }
                .glassCard()
                
                // PDF 工具
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.title2)
                            .foregroundColor(MorandiColors.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(MorandiColors.textSecondary)
                    }
                    
                    Text("PDF 合并")
                        .font(Typography.headlineSmall)
                        .foregroundColor(MorandiColors.textPrimary)
                    
                    Text("多文件快速合并")
                        .font(Typography.bodySmall)
                        .foregroundColor(MorandiColors.textSecondary)
                }
                .glassCard()
                
                // 二维码工具
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.title2)
                            .foregroundColor(MorandiColors.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(MorandiColors.textSecondary)
                    }
                    
                    Text("二维码生成")
                        .font(Typography.headlineSmall)
                        .foregroundColor(MorandiColors.textPrimary)
                    
                    Text("文本/链接转二维码")
                        .font(Typography.bodySmall)
                        .foregroundColor(MorandiColors.textSecondary)
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("快捷操作")
                        .font(Typography.titleSmall)
                        .foregroundColor(MorandiColors.textPrimary)
                    Text("通过快捷操作快速启动或记录你的工作，所有操作都会记录到历史活动中，避免遗漏。")
                        .font(Typography.bodySmall)
                        .foregroundColor(MorandiColors.textSecondary)

                    Button {
                        showConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text(tool.primaryAction)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(tool.accent.opacity(0.2))
                        .foregroundColor(MorandiColors.textPrimary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("执行 \(tool.primaryAction)")
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("使用建议")
                        .font(Typography.titleSmall)
                        .foregroundColor(MorandiColors.textPrimary)
                    Text("为每个工具设置每周目标和提醒时间，确保定期复盘。你也可以在仪表盘添加对应的快捷入口。")
                        .font(Typography.bodySmall)
                        .foregroundColor(MorandiColors.textSecondary)
                }
                .glassCard()
            }
            .padding(16)
        }
        .background(MorandiColors.background)
        .navigationTitle(tool.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("操作已排队", isPresented: $showConfirmation) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("\(tool.primaryAction) 已加入执行队列，稍后会在后台运行。")
        }
    }
}

#Preview {
    ToolsView()
}
