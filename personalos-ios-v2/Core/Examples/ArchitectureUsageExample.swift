import SwiftUI
import Combine

// MARK: - 使用依赖注入的示例
struct ExampleView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @EnvironmentObject var remoteConfig: RemoteConfigService
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            // 1. 使用远程配置控制特性显示
            if remoteConfig.isFeatureEnabled("experimentalFeature") {
                Text("实验性功能已启用")
            }
            
            // 2. 使用服务容器获取服务
            Button("获取健康数据") {
                Task {
                    let healthService = serviceContainer.resolve(HealthServiceProtocol.self)
                    do {
                        let steps = try await healthService.fetchDailySteps()
                        print("今日步数: \(steps)")
                    } catch {
                        print("获取失败: \(error)")
                    }
                }
            }
            
            // 3. 使用统一组件库
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    Text("示例卡片")
                        .font(.headline)
                    Text("使用统一的 Card 组件")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // 4. 使用状态视图
            StateView(
                state: .loaded("数据"),
                content: { data in
                    Text("加载的数据: \(data)")
                },
                emptyView: {
                    EmptyStateView(
                        icon: "tray",
                        title: "无数据",
                        message: "暂无可显示的内容"
                    )
                }
            )
            
            // 5. 切换主题
            Button("切换主题风格") {
                let styles: [ThemeStyle] = [.glass, .vibrant, .noir]
                let currentIndex = styles.firstIndex(of: themeManager.currentStyle) ?? 0
                let nextIndex = (currentIndex + 1) % styles.count
                themeManager.applyStyle(styles[nextIndex])
            }
        }
        .padding()
    }
}

// MARK: - 使用网络客户端的示例
class ExampleViewModel: ObservableObject {
    private let networkClient: NetworkClient
    
    init() {
        // 为不同服务使用不同的网络配置
        self.networkClient = NetworkClient(config: .news)
    }
    
    func fetchData() async {
        do {
            // 网络请求会自动重试、使用熔断器和离线缓存
            struct ExampleResponse: Codable {
                let message: String
            }
            
            let data: ExampleResponse = try await networkClient.request(
                "https://api.example.com/data",
                cachePolicy: .cacheFirst
            )
            print("数据: \(data.message)")
        } catch {
            print("请求失败: \(error)")
        }
    }
}

// MARK: - 使用风险管理的示例
class TradingExampleViewModel: ObservableObject {
    @Published var riskManager = RiskManager()
    
    func evaluateNewTrade(_ trade: TradeRecord) {
        let alerts = riskManager.evaluateTrade(trade)
        
        for alert in alerts {
            switch alert.severity {
            case .warning:
                print("⚠️ 警告: \(alert.message)")
            case .critical:
                print("🚨 严重: \(alert.message)")
            }
        }
    }
}

// MARK: - 使用深度链接的示例
class DeepLinkExampleViewModel: ObservableObject {
    func handleDeepLink() {
        // 创建深度链接
        let projectLink = DeepLink.project(id: "123")
        if let url = projectLink.url {
            print("项目链接: \(url)")
        }
        
        // 解析深度链接
        if let url = URL(string: "personalos://news?category=tech"),
           let deepLink = DeepLink(url: url) {
            print("解析的链接: \(deepLink)")
        }
    }
}

// MARK: - 使用命令面板的示例
struct CommandPaletteExampleView: View {
    @StateObject private var commandPalette = CommandPaletteViewModel()
    @State private var showCommandPalette = false
    
    var body: some View {
        VStack {
            Button("打开命令面板") {
                showCommandPalette = true
            }
            
            Text("快速访问所有功能")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showCommandPalette) {
            CommandPaletteView()
        }
    }
}
