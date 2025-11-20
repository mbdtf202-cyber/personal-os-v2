import SwiftUI

struct ToolsView: View {
    @State private var showPasswordGenerator = false
    @State private var showUnitConverter = false
    @State private var showColorPicker = false
    
    private let tools: [ToolItem] = [
        .init(title: "二维码生成", subtitle: "文本/链接转二维码", icon: "qrcode.viewfinder", accent: AppTheme.mistBlue, primaryAction: "生成二维码", destination: .qrCode),
        .init(title: "密码生成器", subtitle: "生成安全的随机密码", icon: "key.fill", accent: AppTheme.lavender, primaryAction: "生成密码", destination: .password),
        .init(title: "单位转换", subtitle: "长度、重量、温度转换", icon: "arrow.left.arrow.right", accent: AppTheme.matcha, primaryAction: "开始转换", destination: .unitConverter),
        .init(title: "颜色选择器", subtitle: "HEX/RGB 颜色工具", icon: "paintpalette.fill", accent: AppTheme.coral, primaryAction: "选择颜色", destination: .colorPicker),
        .init(title: "闪念笔记", subtitle: "随时记录瞬时灵感", icon: "lightbulb", accent: AppTheme.almond, primaryAction: "记录灵感", destination: .quickNote),
        .init(title: "时间戳转换", subtitle: "Unix 时间戳工具", icon: "clock.fill", accent: AppTheme.mistBlue, primaryAction: "转换时间", destination: .timestamp)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(tools) { tool in
                        if tool.destination == .qrCode {
                            NavigationLink(destination: QRCodeGeneratorView()) {
                                ToolRowView(tool: tool)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                handleToolTap(tool)
                            } label: {
                                ToolRowView(tool: tool)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(MorandiColors.background)
            .navigationTitle("效率工具")
            .sheet(isPresented: $showPasswordGenerator) {
                PasswordGeneratorView()
            }
            .sheet(isPresented: $showUnitConverter) {
                UnitConverterView()
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerToolView()
            }
        }
    }
    
    private func handleToolTap(_ tool: ToolItem) {
        HapticsManager.shared.light()
        switch tool.destination {
        case .password:
            showPasswordGenerator = true
        case .unitConverter:
            showUnitConverter = true
        case .colorPicker:
            showColorPicker = true
        default:
            break
        }
    }
}

enum ToolDestination {
    case qrCode, password, unitConverter, colorPicker, quickNote, timestamp
}

struct ToolItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let primaryAction: String
    let destination: ToolDestination
    
    static func == (lhs: ToolItem, rhs: ToolItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ToolRowView: View {
    let tool: ToolItem
    
    var body: some View {
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
