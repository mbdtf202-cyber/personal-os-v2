# Requirements Document

## Introduction

本文档定义了PersonalOS iOS应用的P0级别系统架构升级需求。这些是必须在上线前解决的红线问题,涉及安全、数据完整性、线程安全和关键业务逻辑错误。不解决这些问题将导致严重的数据丢失、安全漏洞、崩溃或用户信任危机。

## Glossary

- **PersonalOS**: 个人操作系统iOS应用,集成了仪表盘、健康追踪、交易日志、项目管理、新闻聚合和社交博客等功能
- **SwiftData**: Apple的数据持久化框架,用于管理应用的本地数据存储
- **ModelContext**: SwiftData中的核心对象,用于管理数据模型的生命周期和持久化操作
- **MainActor**: Swift并发模型中的主线程执行器,用于UI相关操作
- **API Key**: 用于访问第三方服务的认证密钥
- **ATT**: App Tracking Transparency,Apple的应用追踪透明度框架
- **GDPR**: 通用数据保护条例,欧盟的数据隐私法规
- **Feature Flag**: 功能开关,用于控制功能的启用/禁用和灰度发布
- **Schema Migration**: 数据库模式迁移,用于在应用版本升级时安全地转换数据结构
- **Keychain**: iOS系统提供的安全存储服务,用于存储敏感信息
- **ATS**: App Transport Security,iOS的网络安全策略
- **Certificate Pinning**: 证书固定,一种防止中间人攻击的安全技术
- **Decimal**: Swift的高精度十进制数类型,用于金融计算
- **Repository**: 数据访问层的抽象,封装数据源的CRUD操作
- **ViewModel**: MVVM架构中的视图模型,负责业务逻辑和状态管理
- **Mock Data**: 模拟数据,用于测试或在真实数据不可用时的占位

## Requirements

### Requirement 1: 配置与环境管理

**User Story:** 作为系统管理员,我希望API密钥和敏感配置能够安全管理并支持多环境部署,以便保护应用安全并支持开发、测试和生产环境的隔离。

#### Acceptance Criteria

1. WHEN the application initializes THEN the PersonalOS SHALL load API keys from secure remote configuration service rather than hardcoded values
2. WHEN an API key needs to be rotated THEN the PersonalOS SHALL support remote key updates without requiring app resubmission
3. WHEN the application builds for different environments THEN the PersonalOS SHALL maintain separate configurations for Development, Staging, and Production environments
4. WHEN a feature needs gradual rollout THEN the PersonalOS SHALL provide a Feature Flag system that supports remote toggling and percentage-based rollout
5. WHEN a feature causes issues in production THEN the PersonalOS SHALL allow immediate rollback through Feature Flag without app update

### Requirement 2: 数据持久化与迁移

**User Story:** 作为用户,我希望我的数据在应用升级时能够安全迁移,并且能够备份和恢复,以便在出现问题时不会丢失重要信息。

#### Acceptance Criteria

1. WHEN the application schema changes THEN the PersonalOS SHALL execute versioned migration scripts that preserve all existing user data
2. WHEN migration fails THEN the PersonalOS SHALL rollback to the previous schema version and notify the user
3. WHEN the application seeds initial data THEN the PersonalOS SHALL only insert sample data in non-production environments
4. WHEN user requests data export THEN the PersonalOS SHALL create a complete backup of all user data in a portable format
5. WHEN user imports a backup THEN the PersonalOS SHALL restore all data to the exact state at backup time
6. WHEN user requests data deletion THEN the PersonalOS SHALL permanently remove all personal data to comply with GDPR and CCPA requirements

### Requirement 3: 线程安全与并发

**User Story:** 作为开发者,我希望数据访问操作是线程安全的,以便避免数据竞争、崩溃和不可预测的行为。

#### Acceptance Criteria

1. WHEN ModelContext performs write operations THEN the PersonalOS SHALL execute them on a dedicated background actor isolated from the main thread
2. WHEN multiple threads access ModelContext THEN the PersonalOS SHALL prevent concurrent access through proper synchronization mechanisms
3. WHEN a Repository performs database operations THEN the PersonalOS SHALL use ModelContext perform closures to ensure thread safety
4. WHEN the application encounters a missing dependency THEN the PersonalOS SHALL handle the error gracefully rather than calling fatalError
5. WHEN background tasks access shared state THEN the PersonalOS SHALL use actor isolation or locks to prevent data races

### Requirement 4: 安全与隐私合规

**User Story:** 作为用户,我希望我的隐私得到保护,敏感数据被加密存储,并且应用符合隐私法规要求,以便我可以安全地使用应用。

#### Acceptance Criteria

1. WHEN the application first launches THEN the PersonalOS SHALL display App Tracking Transparency prompt before any tracking occurs
2. WHEN sensitive data is stored locally THEN the PersonalOS SHALL encrypt it using iOS Data Protection APIs
3. WHEN credentials or tokens are stored THEN the PersonalOS SHALL use Keychain with appropriate access control attributes
4. WHEN the application detects jailbreak THEN the PersonalOS SHALL warn the user about security risks
5. WHEN the application makes network requests THEN the PersonalOS SHALL enforce certificate pinning for critical endpoints
6. WHEN the application submits to App Store THEN the PersonalOS SHALL include complete privacy manifest and data usage declarations

### Requirement 5: Dashboard Focus Timer可靠性

**User Story:** 作为用户,我希望专注计时器在应用进入后台或被终止后仍能保持状态,以便我可以依赖它来管理我的专注时间。

#### Acceptance Criteria

1. WHEN a focus session starts THEN the PersonalOS SHALL persist the session start time and duration to local storage
2. WHEN the application enters background THEN the PersonalOS SHALL schedule local notifications for session completion
3. WHEN the application is terminated during a session THEN the PersonalOS SHALL preserve the session state
4. WHEN the application reopens during an active session THEN the PersonalOS SHALL restore the timer with correct remaining time
5. WHEN a focus session completes in background THEN the PersonalOS SHALL deliver a notification to the user

### Requirement 6: Dashboard错误处理与用户反馈

**User Story:** 作为用户,我希望当数据加载失败时能够看到明确的错误信息和重试选项,以便我知道发生了什么并能采取行动。

#### Acceptance Criteria

1. WHEN data loading fails THEN the PersonalOS SHALL display a user-visible error message explaining what went wrong
2. WHEN a network request fails THEN the PersonalOS SHALL provide a retry button to the user
3. WHEN an error occurs THEN the PersonalOS SHALL log detailed diagnostic information for debugging
4. WHEN the user triggers retry THEN the PersonalOS SHALL attempt to reload the failed data
5. WHEN multiple errors occur THEN the PersonalOS SHALL present them in a non-intrusive manner without blocking the UI

### Requirement 7: GitHub同步数据保护

**User Story:** 作为用户,我希望GitHub项目同步时不会删除我的本地自定义数据,以便我可以安全地同步项目而不丢失我的备注和状态。

#### Acceptance Criteria

1. WHEN GitHub sync starts THEN the PersonalOS SHALL fetch remote projects without deleting existing local projects
2. WHEN a project exists both locally and remotely THEN the PersonalOS SHALL merge the data preserving local custom fields
3. WHEN a project exists only locally THEN the PersonalOS SHALL retain it after sync completes
4. WHEN a project exists only remotely THEN the PersonalOS SHALL add it to local storage
5. WHEN sync completes THEN the PersonalOS SHALL preserve all user-entered progress, notes, and status information

### Requirement 8: 交易模块金融精度

**User Story:** 作为交易者,我希望所有金融计算使用高精度数值类型,以便我的资产、成本和盈亏计算完全准确。

#### Acceptance Criteria

1. WHEN storing financial values THEN the PersonalOS SHALL use Decimal type for all prices, quantities, costs, and amounts
2. WHEN performing financial calculations THEN the PersonalOS SHALL maintain Decimal precision throughout the computation
3. WHEN displaying financial values THEN the PersonalOS SHALL format them with appropriate decimal places without precision loss
4. WHEN converting between types THEN the PersonalOS SHALL avoid Double to Decimal conversions that could introduce rounding errors
5. WHEN persisting to SwiftData THEN the PersonalOS SHALL use appropriate transformers to store Decimal values accurately

### Requirement 9: 交易模块持仓计算完整性

**User Story:** 作为交易者,我希望持仓计算基于完整的交易历史,以便我的成本基础和盈亏统计完全准确。

#### Acceptance Criteria

1. WHEN calculating portfolio positions THEN the PersonalOS SHALL use all historical trades regardless of date
2. WHEN computing average cost THEN the PersonalOS SHALL include all buy transactions for each symbol
3. WHEN computing realized gains THEN the PersonalOS SHALL match sells against the complete cost basis
4. WHEN a user has old positions THEN the PersonalOS SHALL include them in current portfolio calculations
5. WHEN displaying portfolio summary THEN the PersonalOS SHALL reflect accurate positions based on complete trade history

### Requirement 10: 交易模块价格数据标识

**User Story:** 作为用户,我希望能够清楚地区分真实市场数据和模拟数据,以便我不会基于虚假信息做出决策。

#### Acceptance Criteria

1. WHEN displaying mock price data THEN the PersonalOS SHALL show a prominent "Test Data" or "Demo Mode" indicator
2. WHEN real price API is unavailable THEN the PersonalOS SHALL clearly indicate that prices are simulated
3. WHEN switching between mock and real data THEN the PersonalOS SHALL update the indicator accordingly
4. WHEN calculating P&L with mock data THEN the PersonalOS SHALL include a disclaimer that results are not real
5. WHEN the user views statistics THEN the PersonalOS SHALL distinguish between real and simulated data sources

### Requirement 11: 交易模块数据一致性验证

**User Story:** 作为交易者,我希望系统能够验证交易操作的合理性,以便防止出现负持仓或超卖等不合理状态。

#### Acceptance Criteria

1. WHEN processing a sell transaction THEN the PersonalOS SHALL verify that sufficient quantity exists in the position
2. WHEN a sell would result in negative position THEN the PersonalOS SHALL reject the transaction and notify the user
3. WHEN calculating position after trades THEN the PersonalOS SHALL ensure the result is non-negative
4. WHEN a position reaches zero THEN the PersonalOS SHALL properly close the position
5. WHEN detecting data inconsistency THEN the PersonalOS SHALL log the error and prevent further corruption

### Requirement 12: Social模块操作反馈

**User Story:** 作为内容创作者,我希望在保存或删除帖子时能够看到明确的成功或失败反馈,以便我知道操作是否完成。

#### Acceptance Criteria

1. WHEN a post save succeeds THEN the PersonalOS SHALL display a success confirmation message
2. WHEN a post save fails THEN the PersonalOS SHALL display an error message with the reason
3. WHEN a post delete succeeds THEN the PersonalOS SHALL display a confirmation and remove it from the list
4. WHEN a post delete fails THEN the PersonalOS SHALL display an error and keep the post in the list
5. WHEN an operation is in progress THEN the PersonalOS SHALL show a loading indicator

### Requirement 13: Social模块状态管理

**User Story:** 作为开发者,我希望ViewModel的生命周期管理是可靠的,以便避免双实例、未初始化访问和崩溃。

#### Acceptance Criteria

1. WHEN a view initializes THEN the PersonalOS SHALL ensure ViewModel is created before any bindings are established
2. WHEN a view appears THEN the PersonalOS SHALL use a single ViewModel instance throughout its lifecycle
3. WHEN ViewModel is missing THEN the PersonalOS SHALL handle the error gracefully without using fatalError
4. WHEN multiple scenes exist THEN the PersonalOS SHALL maintain separate ViewModel instances per scene
5. WHEN a view disappears THEN the PersonalOS SHALL properly clean up ViewModel resources

### Requirement 14: News模块数据真实性标识

**User Story:** 作为用户,我希望能够清楚地知道哪些新闻是真实的,哪些是模拟数据,以便我可以信任我看到的信息。

#### Acceptance Criteria

1. WHEN displaying mock news THEN the PersonalOS SHALL show a clear "Demo Content" badge on each item
2. WHEN API key is missing THEN the PersonalOS SHALL display a banner explaining that content is simulated
3. WHEN API request fails THEN the PersonalOS SHALL distinguish between cached real data and fallback mock data
4. WHEN real news is available THEN the PersonalOS SHALL remove all mock data indicators
5. WHEN mixing real and mock data THEN the PersonalOS SHALL clearly label each item's source

### Requirement 15: News模块API密钥安全

**User Story:** 作为系统管理员,我希望新闻API密钥不会暴露在客户端,并且有限流保护,以便防止密钥被滥用或被盗。

#### Acceptance Criteria

1. WHEN accessing news API THEN the PersonalOS SHALL route requests through a backend proxy that holds the API key
2. WHEN API requests exceed rate limits THEN the PersonalOS SHALL implement client-side throttling
3. WHEN API returns rate limit errors THEN the PersonalOS SHALL implement exponential backoff
4. WHEN API is unavailable THEN the PersonalOS SHALL implement circuit breaker pattern to prevent request storms
5. WHEN monitoring API usage THEN the PersonalOS SHALL log request counts and error rates

### Requirement 16: News模块数据一致性

**User Story:** 作为用户,我希望收藏功能能够可靠地识别已收藏的文章,以便我不会重复收藏同一篇文章。

#### Acceptance Criteria

1. WHEN an article is fetched from API THEN the PersonalOS SHALL use a stable unique identifier for matching
2. WHEN checking bookmark status THEN the PersonalOS SHALL match articles by their canonical URL or stable ID
3. WHEN an article is bookmarked THEN the PersonalOS SHALL persist the stable identifier
4. WHEN displaying articles THEN the PersonalOS SHALL correctly show bookmark status based on stable ID matching
5. WHEN creating tasks from articles THEN the PersonalOS SHALL use stable identifiers to prevent duplicates

### Requirement 17: 法务与版权合规

**User Story:** 作为法务负责人,我希望应用包含完整的法律文档和依赖声明,以便通过App Store审核并满足法律要求。

#### Acceptance Criteria

1. WHEN the application is built THEN the PersonalOS SHALL include a complete list of third-party dependencies with their licenses
2. WHEN user first launches the application THEN the PersonalOS SHALL provide access to Terms of Service and Privacy Policy
3. WHEN preparing for App Store submission THEN the PersonalOS SHALL have completed privacy questionnaire and data usage declarations
4. WHEN displaying settings THEN the PersonalOS SHALL provide links to legal documents and open source licenses
5. WHEN using third-party services THEN the PersonalOS SHALL comply with their terms of service and attribution requirements

### Requirement 18: 架构状态撕裂修复

**User Story:** 作为开发者,我希望应用使用统一的状态管理框架,以便避免Combine和Observation混用导致的视图刷新问题。

#### Acceptance Criteria

1. WHEN managing observable state THEN the PersonalOS SHALL use @Observable macro exclusively for iOS 17+
2. WHEN a component uses ObservableObject THEN the PersonalOS SHALL migrate it to @Observable
3. WHEN views observe state THEN the PersonalOS SHALL use @Environment for @Observable types consistently
4. WHEN state changes THEN the PersonalOS SHALL trigger view updates reliably without dead loops
5. WHEN the migration completes THEN the PersonalOS SHALL have zero remaining ObservableObject instances

### Requirement 19: 网络请求生命周期管理

**User Story:** 作为开发者,我希望网络请求能够在视图消失时正确取消,以便避免浪费带宽和数据竞争。

#### Acceptance Criteria

1. WHEN a view disappears THEN the PersonalOS SHALL cancel all ongoing network requests initiated by that view
2. WHEN a button triggers a Task THEN the PersonalOS SHALL store the task reference for potential cancellation
3. WHEN a new request starts while previous is pending THEN the PersonalOS SHALL cancel the previous request
4. WHEN a cancelled request completes THEN the PersonalOS SHALL not update UI or write to database
5. WHEN managing async operations THEN the PersonalOS SHALL check for cancellation before performing side effects
