# Implementation Plan

- [x] 1. 建立配置管理基础设施
  - 创建EnvironmentManager来管理Dev/Staging/Prod环境
  - 增强RemoteConfigService支持Feature Flag和API密钥远程管理
  - 实现配置缓存和本地fallback机制
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 1.1 编写配置管理的属性测试
  - **Property 1: Remote configuration initialization**
  - **Property 2: Configuration update responsiveness**
  - **Property 3: Environment configuration isolation**
  - **Property 4: Feature flag remote control**
  - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**

- [x] 2. 实现线程安全的数据访问层
  - 创建DataActor作为全局actor用于数据操作隔离
  - 重构BaseRepository使用actor隔离和ModelContext perform闭包
  - 更新所有Repository子类使用新的线程安全模式
  - 移除Repository中的@MainActor标记
  - _Requirements: 3.1, 3.2, 3.3, 3.5_

- [x] 2.1 编写线程安全的属性测试
  - **Property 10: Write operation thread isolation**
  - **Property 11: Concurrent access safety**
  - **Property 12: Repository thread safety pattern**
  - **Property 14: Shared state protection**
  - **Validates: Requirements 3.1, 3.2, 3.3, 3.5**

- [x] 3. 建立数据迁移和备份系统
  - 创建MigrationCoordinator actor处理版本化迁移
  - 实现迁移前自动备份机制
  - 实现迁移失败时的回滚逻辑
  - 创建DataBackupService支持完整数据导出/导入
  - 实现GDPR合规的数据删除功能
  - _Requirements: 2.1, 2.2, 2.4, 2.5, 2.6_

- [x] 3.1 编写数据迁移的属性测试
  - **Property 5: Migration data preservation**
  - **Property 6: Migration rollback on failure**
  - **Property 8: Backup-restore round trip**
  - **Property 9: Complete data deletion**
  - **Validates: Requirements 2.1, 2.2, 2.4, 2.5, 2.6**

- [x] 4. 修复环境相关的数据污染问题
  - 更新DataBootstrapper只在非生产环境seed数据
  - 为所有seed操作添加幂等性检查
  - 清理现有的示例数据标识逻辑
  - _Requirements: 2.3_

- [x] 4.1 编写环境数据seeding的属性测试
  - **Property 7: Environment-based seeding**
  - **Validates: Requirements 2.3**

- [x] 5. 实现安全基础设施
  - 创建SecureStorageService封装Keychain操作
  - 实现数据加密/解密功能使用iOS Data Protection
  - 创建SecurityValidator进行越狱和调试检测
  - 增强SSLPinningManager支持证书固定
  - 创建PrivacyManager处理ATT和隐私合规
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 5.1 编写安全功能的属性测试
  - **Property 15: Sensitive data encryption**
  - **Property 16: Credential keychain storage**
  - **Property 17: Certificate pinning enforcement**
  - **Validates: Requirements 4.2, 4.3, 4.5**

- [x] 6. 增强Focus Timer可靠性
  - 创建FocusSession SwiftData模型
  - 创建FocusSessionManager管理会话生命周期
  - 实现会话状态持久化
  - 实现后台通知调度
  - 实现应用重启后的会话恢复逻辑
  - 更新FocusTimerView使用新的FocusSessionManager
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 6.1 编写Focus Timer的属性测试
  - **Property 18: Session state persistence**
  - **Property 19: Background notification scheduling**
  - **Property 20: Session restoration accuracy**
  - **Property 21: Background completion notification**
  - **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5**

- [x] 7. 改进错误处理和用户反馈
  - 增强ErrorPresenter支持错误队列和重试
  - 扩展AppError枚举包含所有错误类型
  - 为每个错误类型添加用户友好的消息
  - 实现ErrorRecoveryStrategy协议和具体策略
  - 更新所有ViewModel使用增强的错误处理
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 7.1 编写错误处理的属性测试
  - **Property 22: Error visibility**
  - **Property 23: Retry availability**
  - **Property 24: Error logging completeness**
  - **Property 25: Retry execution**
  - **Property 26: Non-blocking error presentation**
  - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

- [x] 8. 修复GitHub同步数据删除问题
  - 重构GitHubService的syncProjects方法
  - 实现mergeProject逻辑保留本地字段
  - 实现三向合并:仅本地、仅远程、两者都有
  - 添加SyncResult返回详细的同步统计
  - 更新ProjectListView显示同步结果
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 8.1 编写GitHub同步的属性测试
  - **Property 27: Sync data preservation**
  - **Property 28: Merge field preservation**
  - **Property 29: Local-only project retention**
  - **Property 30: Remote project addition**
  - **Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5**

- [x] 9. 将交易模块迁移到Decimal类型
  - 更新TradeRecord模型使用Decimal类型
  - 更新AssetItem模型使用Decimal类型
  - 注册DecimalTransformer用于SwiftData持久化
  - 更新所有交易计算逻辑使用Decimal
  - 更新UI格式化代码保持Decimal精度
  - 创建数据迁移脚本从Double转换到Decimal
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 9.1 编写金融精度的属性测试
  - **Property 31: Decimal type usage**
  - **Property 32: Calculation precision preservation**
  - **Property 33: Display format round trip**
  - **Property 34: No double conversion**
  - **Property 35: Persistence round trip**
  - **Validates: Requirements 8.1, 8.2, 8.3, 8.4, 8.5**

- [x] 10. 修复持仓计算使用完整交易历史
  - 重构PortfolioViewModel的recalculatePortfolio方法
  - 更新PortfolioCalculator使用所有历史交易
  - 移除90天过滤限制
  - 将计算移到后台actor
  - 添加进度指示器用于长时间计算
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 10.1 编写持仓计算的属性测试
  - **Property 36: Complete trade history usage**
  - **Property 37: Average cost completeness**
  - **Property 38: Realized gains accuracy**
  - **Property 39: Portfolio summary accuracy**
  - **Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5**

- [x] 11. 添加价格数据来源标识
  - 在StockPriceService添加isUsingMockData属性
  - 更新PriceData包含source字段
  - 在TradingDashboardView添加数据来源指示器
  - 在所有统计卡片添加"Demo Mode"标识
  - 添加设置选项切换真实/模拟数据
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 11.1 编写价格数据透明的属性测试
  - **Property 40: Data source indicator consistency**
  - **Property 41: Statistics source labeling**
  - **Validates: Requirements 10.3, 10.5**

- [x] 12. 实现交易验证逻辑
  - 在PortfolioCalculator添加validateTrade方法
  - 实现卖出数量充足性检查
  - 实现负持仓防止逻辑
  - 添加持仓为零时的自动关闭
  - 在TradeLogForm集成验证逻辑
  - 添加用户友好的验证错误消息
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 12.1 编写交易验证的属性测试
  - **Property 42: Sell quantity validation**
  - **Property 43: Negative position prevention**
  - **Property 44: Position non-negativity invariant**
  - **Property 45: Zero position closure**
  - **Property 46: Inconsistency detection**
  - **Validates: Requirements 11.1, 11.2, 11.3, 11.4, 11.5**

- [x] 13. Checkpoint - 确保所有测试通过
  - 运行所有单元测试和属性测试
  - 修复任何失败的测试
  - 确保代码覆盖率达到目标
  - 如有问题请询问用户

- [x] 14. 改进Social模块操作反馈
  - 在SocialDashboardViewModel添加lastOperation状态
  - 实现savePost的成功/失败反馈
  - 实现deletePost的成功/失败反馈
  - 添加loading状态指示器
  - 更新SocialDashboardView显示操作结果
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 14.1 编写Social反馈的属性测试
  - **Property 47: Save success feedback**
  - **Property 48: Save failure feedback**
  - **Property 49: Delete success feedback**
  - **Property 50: Delete failure feedback**
  - **Property 51: Operation loading indicator**
  - **Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5**

- [x] 15. 修复Social模块ViewModel生命周期
  - 重构SocialDashboardView确保ViewModel在init时创建
  - 移除可选的viewModel并使用必需的依赖注入
  - 移除fatalError fallback逻辑
  - 实现proper的ViewModel清理
  - 添加Scene级别的ViewModel隔离
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [x] 15.1 编写ViewModel生命周期的属性测试
  - **Property 52: ViewModel initialization order**
  - **Property 53: ViewModel instance uniqueness**
  - **Property 54: Missing ViewModel handling**
  - **Property 55: Scene ViewModel isolation**
  - **Property 56: ViewModel resource cleanup**
  - **Validates: Requirements 13.1, 13.2, 13.3, 13.4, 13.5**

- [x] 16. 添加News模块数据来源标识
  - 在NewsItem模型添加dataSource字段
  - 更新NewsService返回数据来源信息
  - 在NewsCard添加"Demo Content"徽章
  - 在NewsFeedView添加数据来源横幅
  - 实现真实/模拟数据的视觉区分
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [x] 16.1 编写News数据源的属性测试
  - **Property 57: Data source distinction**
  - **Property 58: Real data indicator removal**
  - **Property 59: Per-item source labeling**
  - **Validates: Requirements 14.3, 14.4, 14.5**

- [x] 17. 实现News API安全架构
  - 创建后端代理服务用于API密钥管理(设计文档)
  - 实现客户端请求限流逻辑
  - 实现指数退避重试策略
  - 实现熔断器模式
  - 添加API使用监控和日志
  - 更新NewsService使用新的安全架构
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [x] 17.1 编写API安全的属性测试
  - **Property 60: Proxy routing**
  - **Property 61: Client-side throttling**
  - **Property 62: Exponential backoff**
  - **Property 63: Circuit breaker pattern**
  - **Property 64: API usage logging**
  - **Validates: Requirements 15.1, 15.2, 15.3, 15.4, 15.5**

- [x] 18. 修复News书签稳定ID问题
  - 在NewsItem添加稳定的canonical ID字段
  - 更新NewsService使用URL作为稳定标识符
  - 重构书签匹配逻辑使用稳定ID
  - 更新任务创建使用稳定ID防止重复
  - 创建数据迁移为现有NewsItem生成稳定ID
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5_

- [x] 18.1 编写News书签的属性测试
  - **Property 65: Stable identifier usage**
  - **Property 66: Bookmark matching consistency**
  - **Property 67: Stable identifier persistence**
  - **Property 68: Bookmark status accuracy**
  - **Property 69: Task duplicate prevention**
  - **Validates: Requirements 16.1, 16.2, 16.3, 16.4, 16.5**

- [x] 19. 实现法务与版权合规
  - 创建第三方依赖清单
  - 收集所有依赖的许可证信息
  - 编写Terms of Service文档
  - 编写Privacy Policy文档
  - 在Settings中添加法律文档入口
  - 准备App Store隐私问卷
  - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_

- [x] 20. 迁移状态管理从Combine到Observation
  - 识别所有使用ObservableObject的类
  - 将ThemeManager迁移到@Observable
  - 将所有ViewModel迁移到@Observable
  - 更新所有View使用@Environment替代@EnvironmentObject
  - 移除所有@Published属性包装器
  - 验证视图更新正常工作
  - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5_

- [x] 20.1 编写状态管理迁移的属性测试
  - **Property 70: Observable macro usage**
  - **Property 71: Migration completeness**
  - **Property 72: Environment access pattern**
  - **Property 73: Update reliability**
  - **Validates: Requirements 18.1, 18.2, 18.3, 18.4, 18.5**

- [x] 21. 实现网络请求生命周期管理
  - 创建TaskManager管理活动的Task引用
  - 更新所有ViewModel存储Task引用
  - 在view disappear时实现Task取消
  - 添加取消检查在所有async操作中
  - 实现请求替换时的自动取消
  - 防止已取消请求的副作用
  - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5_

- [x] 21.1 编写网络请求生命周期的属性测试
  - **Property 74: View disappearance cancellation**
  - **Property 75: Task reference tracking**
  - **Property 76: Request replacement cancellation**
  - **Property 77: Cancelled request side effect prevention**
  - **Property 78: Cancellation check before side effects**
  - **Validates: Requirements 19.1, 19.2, 19.3, 19.4, 19.5**

- [x] 22. 移除所有fatalError和改进错误处理
  - 搜索代码库中所有fatalError调用
  - 将AppDependency的fatalError替换为graceful错误处理
  - 将所有初始化fatalError替换为throws或返回Optional
  - 添加适当的错误日志和用户通知
  - _Requirements: 3.4_

- [x] 22.1 编写graceful错误处理的属性测试
  - **Property 13: Graceful dependency failure**
  - **Validates: Requirements 3.4**

- [x] 23. 最终Checkpoint - 全面测试和验证
  - 运行完整的测试套件(单元测试+属性测试)
  - 使用Thread Sanitizer检测数据竞争
  - 使用Instruments检测内存泄漏
  - 验证所有P0问题已解决
  - 进行手动回归测试
  - 如有问题请询问用户

- [x] 24. 更新文档和代码注释
  - 为所有新组件添加文档注释
  - 更新README说明新的架构
  - 创建迁移指南文档
  - 添加安全最佳实践文档
  - 更新隐私政策模板
