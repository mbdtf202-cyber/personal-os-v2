# Design Document

## Overview

本设计文档描述了PersonalOS iOS应用P0级别系统架构升级的技术方案。该升级解决了18个关键领域的红线问题,包括安全、数据完整性、线程安全和关键业务逻辑错误。

设计遵循以下核心原则:
- **安全优先**: 所有敏感数据加密存储,API密钥远程管理
- **数据完整性**: 事务性迁移、完整备份恢复机制
- **线程安全**: Actor隔离、ModelContext正确使用
- **用户体验**: 明确的错误反馈、状态持久化
- **可维护性**: 统一的状态管理、清晰的架构分层

## Architecture

### 整体架构分层

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (SwiftUI Views + @Observable VMs)      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│          Business Logic Layer           │
│  (Services, Calculators, Validators)    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│           Data Access Layer             │
│  (Repositories with Actor Isolation)    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Persistence & Network           │
│  (SwiftData, Keychain, NetworkClient)   │
└─────────────────────────────────────────┘
```

### 配置管理架构

```
┌──────────────┐
│  App Launch  │
└──────┬───────┘
       ↓
┌──────────────────────────┐
│ RemoteConfigService      │
│ - Fetch from Firebase    │
│ - Cache locally          │
│ - Provide Feature Flags  │
└──────┬───────────────────┘
       ↓
┌──────────────────────────┐
│ Environment Manager      │
│ - Dev/Staging/Prod       │
│ - API Endpoints          │
│ - Feature Flag State     │
└──────────────────────────┘
```

### 数据持久化架构

```
┌─────────────────────────────────────┐
│      SwiftData ModelContainer       │
└─────────────────┬───────────────────┘
                  ↓
┌─────────────────────────────────────┐
│     Migration Coordinator           │
│  - Version Detection                │
│  - Backup Before Migration          │
│  - Transactional Migration          │
│  - Rollback on Failure              │
└─────────────────┬───────────────────┘
                  ↓
┌─────────────────────────────────────┐
│    Background Data Actor            │
│  - Isolated ModelContext            │
│  - All Write Operations             │
│  - Thread-Safe Access               │
└─────────────────────────────────────┘
```

### 线程安全架构

```
┌──────────────────┐
│   @MainActor     │
│   ViewModels     │
│  (Read-only)     │
└────────┬─────────┘
         ↓ (async calls)
┌──────────────────────────┐
│  @DataActor              │
│  - ModelContext          │
│  - Write Operations      │
│  - Query Operations      │
└──────────────────────────┘
```

## Components and Interfaces

### 1. Configuration Management

#### RemoteConfigService (Enhanced)

```swift
@Observable
final class RemoteConfigService {
    private(set) var isReady: Bool = false
    private(set) var featureFlags: [String: Bool] = [:]
    private(set) var apiEndpoints: [String: String] = [:]
    
    func initialize() async throws
    func fetchLatestConfig() async throws
    func isFeatureEnabled(_ feature: String) -> Bool
    func getAPIKey(for service: String) -> String?
    func getEndpoint(for service: String) -> String
}
```

#### EnvironmentManager (New)

```swift
enum AppEnvironment {
    case development
    case staging
    case production
}

final class EnvironmentManager {
    static let current: AppEnvironment
    
    func baseURL(for service: String) -> URL
    func shouldSeedMockData() -> Bool
    func isDebugMode() -> Bool
}
```

### 2. Data Migration

#### MigrationCoordinator (New)

```swift
actor MigrationCoordinator {
    func needsMigration(from: SchemaVersion, to: SchemaVersion) -> Bool
    func performMigration(context: ModelContext) async throws
    func createBackup() async throws -> URL
    func restoreFromBackup(url: URL) async throws
    func rollback() async throws
}
```

#### DataBackupService (New)

```swift
actor DataBackupService {
    func exportAllData() async throws -> Data
    func importData(_ data: Data) async throws
    func deleteAllUserData() async throws // GDPR compliance
}
```

### 3. Thread-Safe Data Access

#### DataActor (New)

```swift
@globalActor
actor DataActor {
    static let shared = DataActor()
    
    private let modelContext: ModelContext
    
    func perform<T>(_ block: @DataActor () throws -> T) rethrows -> T
}
```

#### BaseRepository (Enhanced)

```swift
actor BaseRepository<T: PersistentModel> {
    private let modelContext: ModelContext
    
    func fetch(predicate: Predicate<T>?) async throws -> [T]
    func save(_ item: T) async throws
    func delete(_ item: T) async throws
    func count(predicate: Predicate<T>?) async throws -> Int
}
```

### 4. Security Components

#### SecureStorageService (New)

```swift
final class SecureStorageService {
    func store(key: String, value: String, accessibility: KeychainAccessibility) throws
    func retrieve(key: String) throws -> String?
    func delete(key: String) throws
    func encryptData(_ data: Data) throws -> Data
    func decryptData(_ data: Data) throws -> Data
}
```

#### SecurityValidator (New)

```swift
final class SecurityValidator {
    func isJailbroken() -> Bool
    func isDebuggerAttached() -> Bool
    func validateCertificate(_ trust: SecTrust, for host: String) -> Bool
}
```

#### PrivacyManager (New)

```swift
@Observable
final class PrivacyManager {
    var hasRequestedATT: Bool
    var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus
    
    func requestTrackingAuthorization() async
    func generatePrivacyReport() -> PrivacyReport
}
```

### 5. Focus Timer (Enhanced)

#### FocusSessionManager (New)

```swift
@Observable
final class FocusSessionManager {
    private(set) var currentSession: FocusSession?
    private(set) var remainingTime: TimeInterval = 0
    
    func startSession(duration: TimeInterval) async throws
    func pauseSession() async throws
    func resumeSession() async throws
    func endSession() async throws
    func restoreSession() async throws
}
```

#### FocusSession (New Model)

```swift
@Model
final class FocusSession {
    var id: UUID
    var startTime: Date
    var duration: TimeInterval
    var pausedAt: Date?
    var completedAt: Date?
    var isActive: Bool
}
```

### 6. Error Handling

#### ErrorPresenter (Enhanced)

```swift
@Observable
final class ErrorPresenter {
    private(set) var currentError: AppError?
    private(set) var errorQueue: [AppError] = []
    
    func present(_ error: AppError)
    func dismiss()
    func retry(for error: AppError) async
}
```

#### AppError (Enhanced)

```swift
enum AppError: Error, Identifiable {
    case network(NetworkError, retryable: Bool)
    case database(DatabaseError, recoverable: Bool)
    case validation(ValidationError)
    case security(SecurityError)
    
    var id: UUID { UUID() }
    var userMessage: String { }
    var debugDescription: String { }
    var canRetry: Bool { }
}
```

### 7. GitHub Sync (Enhanced)

#### GitHubSyncService (Enhanced)

```swift
actor GitHubSyncService {
    func syncProjects(username: String) async throws -> SyncResult
    func mergeProject(remote: GitHubRepo, local: ProjectItem?) async throws -> ProjectItem
    func preserveLocalFields(from local: ProjectItem, to merged: ProjectItem)
}

struct SyncResult {
    let added: Int
    let updated: Int
    let unchanged: Int
    let conflicts: [ProjectConflict]
}
```

### 8. Trading Module (Enhanced)

#### TradeRecord (Enhanced Model)

```swift
@Model
final class TradeRecord {
    var id: UUID
    var symbol: String
    var type: TradeType
    var quantity: Decimal  // Changed from Double
    var price: Decimal     // Changed from Double
    var date: Date
    var notes: String
}
```

#### AssetItem (Enhanced Model)

```swift
@Model
final class AssetItem {
    var symbol: String
    var quantity: Decimal      // Changed from Double
    var avgCost: Decimal       // Changed from Double
    var currentPrice: Decimal  // Changed from Double
    var lastUpdated: Date
}
```

#### PortfolioCalculator (Enhanced)

```swift
actor PortfolioCalculator {
    func calculatePositions(from allTrades: [TradeRecord]) async throws -> [Position]
    func calculateRealizedGains(from trades: [TradeRecord]) async throws -> Decimal
    func validateTrade(_ trade: TradeRecord, against positions: [Position]) throws
}

struct Position {
    let symbol: String
    let quantity: Decimal
    let avgCost: Decimal
    let costBasis: Decimal
}
```

#### StockPriceService (Enhanced)

```swift
actor StockPriceService {
    var isUsingMockData: Bool { get }
    
    func fetchPrices(for symbols: [String]) async throws -> [String: PriceData]
    func subscribeToPriceUpdates(symbols: [String]) -> AsyncStream<PriceUpdate>
}

struct PriceData {
    let price: Decimal
    let timestamp: Date
    let source: PriceSource
}

enum PriceSource {
    case realtime
    case delayed
    case mock
}
```

### 9. Social Module (Enhanced)

#### SocialDashboardViewModel (Enhanced)

```swift
@Observable
final class SocialDashboardViewModel {
    private(set) var posts: [SocialPost] = []
    private(set) var isLoading: Bool = false
    private(set) var error: AppError?
    private(set) var lastOperation: OperationResult?
    
    private let repository: SocialPostRepository
    
    init(repository: SocialPostRepository) {
        self.repository = repository
    }
    
    func savePost(_ post: SocialPost) async throws
    func deletePost(_ post: SocialPost) async throws
    func loadPosts() async throws
}

struct OperationResult {
    let type: OperationType
    let success: Bool
    let message: String
}
```

### 10. News Module (Enhanced)

#### NewsService (Enhanced)

```swift
actor NewsService {
    var dataSource: NewsDataSource { get }
    
    func fetchNews(category: String) async throws -> [NewsItem]
    func searchNews(query: String) async throws -> [NewsItem]
}

enum NewsDataSource {
    case api
    case cache
    case mock
}
```

#### NewsItem (Enhanced Model)

```swift
@Model
final class NewsItem {
    var id: String           // Stable canonical ID
    var url: String          // Canonical URL for matching
    var title: String
    var summary: String
    var publishedAt: Date
    var source: String
    var isBookmarked: Bool
    var dataSource: String   // "api", "cache", or "mock"
}
```

### 11. Legal and Compliance Components

#### LicenseManager (New)

```swift
final class LicenseManager {
    func generateLicenseDocument() -> String
    func getThirdPartyLicenses() -> [ThirdPartyLicense]
}

struct ThirdPartyLicense {
    let name: String
    let version: String
    let license: String
    let url: URL?
}
```

#### LegalDocumentProvider (New)

```swift
final class LegalDocumentProvider {
    func getTermsOfService() -> URL
    func getPrivacyPolicy() -> URL
    func getOpenSourceLicenses() -> URL
}
```

### 12. State Management Migration

#### Observable Migration Strategy

All `ObservableObject` classes will be migrated to `@Observable`:

**Before:**
```swift
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme
}
```

**After:**
```swift
@Observable
final class ThemeManager {
    var currentTheme: Theme
}
```

### 12. Network Request Management

#### TaskManager (New)

```swift
@Observable
final class TaskManager {
    private var activeTasks: [String: Task<Void, Never>] = [:]
    
    func register(id: String, task: Task<Void, Never>)
    func cancel(id: String)
    func cancelAll()
}
```

## Data Models

### Enhanced Models with Decimal Support

#### DecimalTransformer (Enhanced)

```swift
@objc(DecimalTransformer)
final class DecimalTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let decimal = value as? Decimal else { return nil }
        return try? JSONEncoder().encode(decimal)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode(Decimal.self, from: data)
    }
}
```

### Schema Versioning

```swift
enum SchemaVersion: Int, Codable {
    case v1 = 1
    case v2 = 2
    case v3 = 3
    case v4 = 4  // Current version with all P0 fixes
    
    static var current: SchemaVersion { .v4 }
}

struct SchemaMetadata: Codable {
    let version: SchemaVersion
    let migratedAt: Date
    let backupURL: URL?
}
```

## Error Handling

### Error Hierarchy

```swift
protocol AppErrorProtocol: Error, Identifiable {
    var userMessage: String { get }
    var debugDescription: String { get }
    var canRetry: Bool { get }
    var severity: ErrorSeverity { get }
}

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
}

enum NetworkError: AppErrorProtocol {
    case noConnection
    case timeout
    case serverError(Int)
    case rateLimited
    case invalidResponse
}

enum DatabaseError: AppErrorProtocol {
    case migrationFailed(String)
    case corruptedData
    case constraintViolation
    case concurrencyConflict
}

enum ValidationError: AppErrorProtocol {
    case insufficientQuantity(symbol: String, available: Decimal, requested: Decimal)
    case negativePosition(symbol: String)
    case invalidPrice
    case invalidDate
}

enum SecurityError: AppErrorProtocol {
    case jailbroken
    case certificateValidationFailed
    case keychainAccessDenied
    case encryptionFailed
}
```

### Error Recovery Strategies

```swift
protocol ErrorRecoveryStrategy {
    func canRecover(from error: AppError) -> Bool
    func recover(from error: AppError) async throws
}

final class NetworkErrorRecovery: ErrorRecoveryStrategy {
    func canRecover(from error: AppError) -> Bool {
        guard case .network(_, let retryable) = error else { return false }
        return retryable
    }
    
    func recover(from error: AppError) async throws {
        // Implement exponential backoff retry logic
    }
}
```

## Testing Strategy

### Unit Testing

本项目将使用XCTest框架进行单元测试,重点覆盖:

1. **Configuration Management**: 测试环境切换、Feature Flag读取
2. **Data Migration**: 测试各版本迁移路径、回滚机制
3. **Repository Operations**: 测试CRUD操作的线程安全性
4. **Financial Calculations**: 测试Decimal精度、持仓计算准确性
5. **Validation Logic**: 测试交易验证、数据一致性检查
6. **Error Handling**: 测试错误分类、恢复策略

### Property-Based Testing

本项目将使用**SwiftCheck**库进行属性测试,配置每个测试运行最少100次迭代。

属性测试将验证以下通用规则:
- 数据迁移的可逆性
- 金融计算的精度保持
- 并发操作的数据一致性
- 状态转换的合法性

每个属性测试必须使用以下格式标注:
```swift
// **Feature: system-architecture-upgrade-p0, Property X: [property description]**
```

### Integration Testing

集成测试将验证:
- ModelContext在多线程环境下的行为
- 网络层与Repository层的集成
- ViewModel与Repository的交互
- 错误在各层之间的传播

### Performance Testing

使用XCTestMetrics测量:
- 数据迁移耗时
- 大量交易记录的计算性能
- 并发Repository操作的吞吐量


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Configuration Management Properties

**Property 1: Remote configuration initialization**
*For any* application initialization, the system should load API keys from the remote configuration service and not use any hardcoded values.
**Validates: Requirements 1.1**

**Property 2: Configuration update responsiveness**
*For any* API key rotation in the remote configuration, the system should use the updated key on the next fetch without requiring app resubmission.
**Validates: Requirements 1.2**

**Property 3: Environment configuration isolation**
*For any* environment (Development, Staging, Production), the system should maintain completely separate configurations with no cross-contamination.
**Validates: Requirements 1.3**

**Property 4: Feature flag remote control**
*For any* feature flag, the system should correctly evaluate its enabled/disabled state based on the current remote configuration.
**Validates: Requirements 1.4, 1.5**

### Data Migration Properties

**Property 5: Migration data preservation**
*For any* set of user data in schema version N, migrating to version N+1 should preserve all data without loss.
**Validates: Requirements 2.1**

**Property 6: Migration rollback on failure**
*For any* migration failure, the system should rollback to the previous schema version and notify the user.
**Validates: Requirements 2.2**

**Property 7: Environment-based seeding**
*For any* production environment initialization, the system should not insert any sample data, while non-production environments may seed data.
**Validates: Requirements 2.3**

**Property 8: Backup-restore round trip**
*For any* set of user data, exporting to backup then importing should yield identical data (export-import identity).
**Validates: Requirements 2.4, 2.5**

**Property 9: Complete data deletion**
*For any* user data deletion request, the system should permanently remove all personal data such that subsequent queries return empty results.
**Validates: Requirements 2.6**

### Thread Safety Properties

**Property 10: Write operation thread isolation**
*For any* ModelContext write operation, the system should execute it on a background actor, never on MainActor.
**Validates: Requirements 3.1**

**Property 11: Concurrent access safety**
*For any* set of concurrent ModelContext operations, the system should prevent data races through proper synchronization.
**Validates: Requirements 3.2**

**Property 12: Repository thread safety pattern**
*For any* Repository database operation, the system should use ModelContext perform closures to ensure thread safety.
**Validates: Requirements 3.3**

**Property 13: Graceful dependency failure**
*For any* missing dependency scenario, the system should return an error rather than calling fatalError and crashing.
**Validates: Requirements 3.4**

**Property 14: Shared state protection**
*For any* background task accessing shared state, the system should use actor isolation or locks to prevent data races.
**Validates: Requirements 3.5**

### Security Properties

**Property 15: Sensitive data encryption**
*For any* sensitive data stored locally, the system should encrypt it using iOS Data Protection APIs before persistence.
**Validates: Requirements 4.2**

**Property 16: Credential keychain storage**
*For any* credential or token, the system should store it in Keychain with appropriate access control, never in UserDefaults or files.
**Validates: Requirements 4.3**

**Property 17: Certificate pinning enforcement**
*For any* network request to critical endpoints, the system should enforce certificate pinning and reject invalid certificates.
**Validates: Requirements 4.5**

### Focus Timer Properties

**Property 18: Session state persistence**
*For any* focus session start, the system should persist the session data such that it can be retrieved after app restart.
**Validates: Requirements 5.1, 5.3**

**Property 19: Background notification scheduling**
*For any* active focus session when app enters background, the system should schedule a local notification for session completion.
**Validates: Requirements 5.2**

**Property 20: Session restoration accuracy**
*For any* active focus session, reopening the app should restore the timer with remaining time calculated correctly based on elapsed time.
**Validates: Requirements 5.4**

**Property 21: Background completion notification**
*For any* focus session that completes while app is in background, the system should deliver a notification to the user.
**Validates: Requirements 5.5**

### Error Handling Properties

**Property 22: Error visibility**
*For any* data loading failure, the system should display a user-visible error message explaining the failure.
**Validates: Requirements 6.1**

**Property 23: Retry availability**
*For any* network request failure, the system should provide a retry mechanism to the user.
**Validates: Requirements 6.2**

**Property 24: Error logging completeness**
*For any* error occurrence, the system should log detailed diagnostic information for debugging.
**Validates: Requirements 6.3**

**Property 25: Retry execution**
*For any* user-triggered retry action, the system should attempt to reload the failed data.
**Validates: Requirements 6.4**

**Property 26: Non-blocking error presentation**
*For any* set of multiple errors, the system should present them in a non-intrusive manner without blocking the UI.
**Validates: Requirements 6.5**

### GitHub Sync Properties

**Property 27: Sync data preservation**
*For any* set of local projects, starting GitHub sync should not delete any existing local projects.
**Validates: Requirements 7.1**

**Property 28: Merge field preservation**
*For any* project existing both locally and remotely, merging should preserve all local custom fields (progress, notes, status).
**Validates: Requirements 7.2, 7.5**

**Property 29: Local-only project retention**
*For any* project existing only locally, it should remain in local storage after sync completes.
**Validates: Requirements 7.3**

**Property 30: Remote project addition**
*For any* project existing only remotely, it should be added to local storage after sync completes.
**Validates: Requirements 7.4**

### Financial Precision Properties

**Property 31: Decimal type usage**
*For any* financial value (price, quantity, cost, amount), the system should use Decimal type, never Double.
**Validates: Requirements 8.1**

**Property 32: Calculation precision preservation**
*For any* financial calculation, the system should maintain full Decimal precision throughout the computation without rounding errors.
**Validates: Requirements 8.2**

**Property 33: Display format round trip**
*For any* Decimal financial value, formatting to string then parsing back should yield the identical Decimal value.
**Validates: Requirements 8.3**

**Property 34: No double conversion**
*For any* financial calculation path, the system should not perform Double to Decimal conversions that could introduce rounding errors.
**Validates: Requirements 8.4**

**Property 35: Persistence round trip**
*For any* Decimal value, saving to SwiftData then retrieving should yield the identical Decimal value.
**Validates: Requirements 8.5**

### Portfolio Calculation Properties

**Property 36: Complete trade history usage**
*For any* portfolio position calculation, the system should include all historical trades regardless of their date.
**Validates: Requirements 9.1, 9.4**

**Property 37: Average cost completeness**
*For any* symbol, computing average cost should include all buy transactions for that symbol from complete history.
**Validates: Requirements 9.2**

**Property 38: Realized gains accuracy**
*For any* set of trades, computing realized gains should match sells against the complete cost basis from all historical buys.
**Validates: Requirements 9.3**

**Property 39: Portfolio summary accuracy**
*For any* complete trade history, the displayed portfolio summary should exactly match the calculated positions.
**Validates: Requirements 9.5**

### Price Data Transparency Properties

**Property 40: Data source indicator consistency**
*For any* data source change (mock to real or vice versa), the system should update the data source indicator accordingly.
**Validates: Requirements 10.3**

**Property 41: Statistics source labeling**
*For any* displayed statistic, the system should clearly indicate whether the data source is real or simulated.
**Validates: Requirements 10.5**

### Trade Validation Properties

**Property 42: Sell quantity validation**
*For any* sell transaction, the system should verify sufficient quantity exists in the position and reject if insufficient.
**Validates: Requirements 11.1**

**Property 43: Negative position prevention**
*For any* sell transaction that would result in negative position, the system should reject it and notify the user.
**Validates: Requirements 11.2**

**Property 44: Position non-negativity invariant**
*For any* sequence of valid trades, all resulting positions should have non-negative quantities.
**Validates: Requirements 11.3**

**Property 45: Zero position closure**
*For any* position that reaches exactly zero quantity, the system should properly mark it as closed.
**Validates: Requirements 11.4**

**Property 46: Inconsistency detection**
*For any* detected data inconsistency, the system should log the error and prevent further data corruption.
**Validates: Requirements 11.5**

### Social Module Feedback Properties

**Property 47: Save success feedback**
*For any* successful post save operation, the system should display a success confirmation message.
**Validates: Requirements 12.1**

**Property 48: Save failure feedback**
*For any* failed post save operation, the system should display an error message with the failure reason.
**Validates: Requirements 12.2**

**Property 49: Delete success feedback**
*For any* successful post delete operation, the system should display confirmation and remove the post from the list.
**Validates: Requirements 12.3**

**Property 50: Delete failure feedback**
*For any* failed post delete operation, the system should display an error and keep the post in the list.
**Validates: Requirements 12.4**

**Property 51: Operation loading indicator**
*For any* async operation in progress, the system should display a loading indicator.
**Validates: Requirements 12.5**

### ViewModel Lifecycle Properties

**Property 52: ViewModel initialization order**
*For any* view initialization, the system should create the ViewModel before establishing any bindings.
**Validates: Requirements 13.1**

**Property 53: ViewModel instance uniqueness**
*For any* view lifecycle, the system should use exactly one ViewModel instance from appearance to disappearance.
**Validates: Requirements 13.2**

**Property 54: Missing ViewModel handling**
*For any* scenario where ViewModel is missing, the system should handle it gracefully without calling fatalError.
**Validates: Requirements 13.3**

**Property 55: Scene ViewModel isolation**
*For any* set of multiple scenes, each scene should maintain its own separate ViewModel instance.
**Validates: Requirements 13.4**

**Property 56: ViewModel resource cleanup**
*For any* view disappearance, the system should properly clean up ViewModel resources.
**Validates: Requirements 13.5**

### News Data Source Properties

**Property 57: Data source distinction**
*For any* API request failure, the system should clearly distinguish between cached real data and fallback mock data.
**Validates: Requirements 14.3**

**Property 58: Real data indicator removal**
*For any* real news data availability, the system should remove all mock data indicators.
**Validates: Requirements 14.4**

**Property 59: Per-item source labeling**
*For any* news item displayed, the system should clearly label its source (API, cache, or mock).
**Validates: Requirements 14.5**

### API Security Properties

**Property 60: Proxy routing**
*For any* news API request, the system should route it through a backend proxy rather than directly from the client.
**Validates: Requirements 15.1**

**Property 61: Client-side throttling**
*For any* sequence of API requests exceeding rate limits, the system should implement client-side throttling.
**Validates: Requirements 15.2**

**Property 62: Exponential backoff**
*For any* rate limit error from API, the system should implement exponential backoff for subsequent requests.
**Validates: Requirements 15.3**

**Property 63: Circuit breaker pattern**
*For any* API unavailability scenario, the system should implement circuit breaker to prevent request storms.
**Validates: Requirements 15.4**

**Property 64: API usage logging**
*For any* API request, the system should log request counts and error rates for monitoring.
**Validates: Requirements 15.5**

### News Bookmark Properties

**Property 65: Stable identifier usage**
*For any* article fetched from API, the system should assign and use a stable unique identifier for matching.
**Validates: Requirements 16.1**

**Property 66: Bookmark matching consistency**
*For any* bookmark status check, the system should match articles by their canonical URL or stable ID consistently.
**Validates: Requirements 16.2**

**Property 67: Stable identifier persistence**
*For any* article bookmark operation, the system should persist the stable identifier.
**Validates: Requirements 16.3**

**Property 68: Bookmark status accuracy**
*For any* displayed article, the system should correctly show bookmark status based on stable ID matching.
**Validates: Requirements 16.4**

**Property 69: Task duplicate prevention**
*For any* task creation from article, the system should use stable identifiers to prevent duplicate tasks.
**Validates: Requirements 16.5**

### State Management Migration Properties

**Property 70: Observable macro usage**
*For any* state management component, the system should use @Observable macro exclusively, not ObservableObject.
**Validates: Requirements 17.1**

**Property 71: Migration completeness**
*For any* codebase scan after migration, the system should have zero remaining ObservableObject instances.
**Validates: Requirements 17.2, 17.5**

**Property 72: Environment access pattern**
*For any* view observing @Observable types, the system should use @Environment consistently.
**Validates: Requirements 17.3**

**Property 73: Update reliability**
*For any* state change, the system should trigger exactly one view update without dead loops.
**Validates: Requirements 17.4**

### Network Request Lifecycle Properties

**Property 74: View disappearance cancellation**
*For any* view disappearance, the system should cancel all ongoing network requests initiated by that view.
**Validates: Requirements 18.1**

**Property 75: Task reference tracking**
*For any* button-triggered Task, the system should store the task reference for potential cancellation.
**Validates: Requirements 18.2**

**Property 76: Request replacement cancellation**
*For any* new request starting while a previous request is pending, the system should cancel the previous request.
**Validates: Requirements 18.3**

**Property 77: Cancelled request side effect prevention**
*For any* cancelled request that completes, the system should not update UI or write to database.
**Validates: Requirements 18.4**

**Property 78: Cancellation check before side effects**
*For any* async operation, the system should check for cancellation before performing side effects.
**Validates: Requirements 18.5**
