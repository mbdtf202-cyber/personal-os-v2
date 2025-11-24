# Migration Guide: P0 Architecture Upgrade

This guide helps developers understand and work with the P0 architecture upgrade implemented in Personal OS v2.

## Overview

The P0 upgrade addresses critical production readiness issues across 19 requirement areas:
- Configuration and environment management
- Data persistence and migration
- Thread safety and concurrency
- Security and privacy compliance
- Error handling and user feedback
- Module-specific reliability improvements

## Breaking Changes

### 1. State Management: ObservableObject → @Observable

**Before:**
```swift
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .glass
}

struct MyView: View {
    @EnvironmentObject var themeManager: ThemeManager
}
```

**After:**
```swift
@Observable
final class ThemeManager {
    var currentTheme: Theme = .glass
}

struct MyView: View {
    @Environment(ThemeManager.self) var themeManager
}
```

**Migration Steps:**
1. Replace `ObservableObject` conformance with `@Observable` macro
2. Remove all `@Published` property wrappers
3. Change `@EnvironmentObject` to `@Environment` in views
4. Update `.environmentObject()` to `.environment()` in view hierarchy

### 2. Repository Pattern: MainActor → Actor Isolation

**Before:**
```swift
@MainActor
class TodoRepository {
    func save(_ item: TodoItem) {
        // Direct ModelContext access
    }
}
```

**After:**
```swift
actor TodoRepository: BaseRepository<TodoItem> {
    func save(_ item: TodoItem) async throws {
        try await performWrite { context in
            context.insert(item)
            try context.save()
        }
    }
}
```

**Migration Steps:**
1. Remove `@MainActor` from repository classes
2. Change class to `actor` and inherit from `BaseRepository<T>`
3. Make all methods `async throws`
4. Use `performWrite` or `performRead` for ModelContext operations
5. Update all call sites to use `await`

### 3. Financial Data: Double → Decimal

**Before:**
```swift
@Model
final class TradeRecord {
    var price: Double
    var quantity: Double
}
```

**After:**
```swift
@Model
final class TradeRecord {
    @Attribute(.transformable(by: DecimalTransformer.self))
    var price: Decimal
    
    @Attribute(.transformable(by: DecimalTransformer.self))
    var quantity: Decimal
}
```

**Migration Steps:**
1. Change all financial `Double` properties to `Decimal`
2. Add `@Attribute(.transformable(by: DecimalTransformer.self))` annotation
3. Register `DecimalTransformer` in app initialization
4. Update all calculations to use Decimal arithmetic
5. Run data migration to convert existing Double values

### 4. Error Handling: fatalError → Graceful Errors

**Before:**
```swift
guard let dependency = container.resolve(Service.self) else {
    fatalError("Failed to resolve Service")
}
```

**After:**
```swift
guard let dependency = container.resolve(Service.self) else {
    throw AppError.dependencyResolution(
        type: "Service",
        message: "Failed to resolve Service dependency"
    )
}
```

**Migration Steps:**
1. Search for all `fatalError` calls in codebase
2. Replace with appropriate error throwing or Optional returns
3. Add error handling at call sites
4. Log errors for debugging
5. Show user-friendly error messages

## New Components

### Configuration Management

#### EnvironmentManager
Manages environment-specific configuration:

```swift
// Usage
let baseURL = EnvironmentManager.shared.baseURL(for: "news")
let shouldSeed = EnvironmentManager.shared.shouldSeedMockData()
```

#### RemoteConfigService
Fetches configuration from Firebase:

```swift
// Usage
let configService = RemoteConfigService.shared
await configService.initialize()

if configService.isFeatureEnabled("new_dashboard") {
    // Show new dashboard
}

let apiKey = configService.getAPIKey(for: "news")
```

### Data Layer

#### DataActor
Global actor for thread-safe data operations:

```swift
@DataActor
func performDataOperation() {
    // All code here runs on DataActor
}
```

#### MigrationCoordinator
Handles schema migrations with backup/rollback:

```swift
// Automatic migration on app launch
let coordinator = MigrationCoordinator.shared
if await coordinator.needsMigration() {
    try await coordinator.performMigration()
}
```

#### DataBackupService
Complete data export/import:

```swift
// Export all data
let backupData = try await DataBackupService.shared.exportAllData()

// Import data
try await DataBackupService.shared.importData(backupData)

// GDPR deletion
try await DataBackupService.shared.deleteAllUserData()
```

### Security

#### SecureStorageService
Keychain wrapper for sensitive data:

```swift
let storage = SecureStorageService.shared

// Store
try storage.store(
    key: "api_token",
    value: token,
    accessibility: .afterFirstUnlock
)

// Retrieve
let token = try storage.retrieve(key: "api_token")

// Encrypt data
let encrypted = try storage.encryptData(sensitiveData)
```

#### SecurityValidator
Security checks:

```swift
let validator = SecurityValidator.shared

if validator.isJailbroken() {
    // Show warning
}

if validator.isDebuggerAttached() {
    // Disable sensitive features
}
```

#### PrivacyManager
ATT compliance:

```swift
let privacyManager = PrivacyManager.shared

await privacyManager.requestTrackingAuthorization()

if privacyManager.trackingAuthorizationStatus == .authorized {
    // Enable analytics
}
```

### Network Resilience

#### CircuitBreaker
Prevents cascading failures:

```swift
let breaker = CircuitBreaker(
    failureThreshold: 5,
    timeout: 60
)

try await breaker.execute {
    try await apiCall()
}
```

#### RetryStrategy
Exponential backoff:

```swift
let strategy = ExponentialBackoffStrategy(
    maxAttempts: 3,
    baseDelay: 1.0
)

try await strategy.execute {
    try await networkRequest()
}
```

#### RequestThrottler
Rate limiting:

```swift
let throttler = RequestThrottler(
    maxRequests: 10,
    timeWindow: 60
)

try await throttler.execute {
    try await apiRequest()
}
```

### Error Handling

#### AppError
Comprehensive error types:

```swift
enum AppError: Error {
    case network(NetworkError, retryable: Bool)
    case database(DatabaseError, recoverable: Bool)
    case validation(ValidationError)
    case security(SecurityError)
    
    var userMessage: String { /* ... */ }
    var canRetry: Bool { /* ... */ }
}
```

#### ErrorPresenter
User-friendly error display:

```swift
@Observable
final class ErrorPresenter {
    func present(_ error: AppError) {
        // Shows error to user with retry option
    }
    
    func retry(for error: AppError) async {
        // Executes retry logic
    }
}
```

## Module-Specific Changes

### Dashboard: Focus Timer

The Focus Timer now persists state across app lifecycle:

```swift
// Start a session
await focusSessionManager.startSession(duration: 1500) // 25 minutes

// Session automatically persists
// On app restart:
await focusSessionManager.restoreSession()
```

### Trading Journal: Decimal Precision

All financial calculations now use Decimal:

```swift
// Creating a trade
let trade = TradeRecord(
    symbol: "AAPL",
    type: .buy,
    quantity: Decimal(string: "10")!,
    price: Decimal(string: "150.25")!
)

// Calculations maintain precision
let totalCost = trade.quantity * trade.price
// Result: 1502.50 (exact, no floating point errors)
```

### GitHub Sync: Data Preservation

Sync now preserves local custom fields:

```swift
// Before: Would delete local projects not in GitHub
// After: Merges data preserving local fields

let result = try await githubService.syncProjects(username: "user")
print("Added: \(result.added)")
print("Updated: \(result.updated)")
print("Unchanged: \(result.unchanged)")
```

### News Module: Data Source Indicators

News items now show their data source:

```swift
@Model
final class NewsItem {
    var dataSource: String // "api", "cache", or "mock"
}

// UI shows badges for mock data
if newsItem.dataSource == "mock" {
    // Show "Demo Content" badge
}
```

### Social Module: Operation Feedback

Operations now provide clear feedback:

```swift
@Observable
final class SocialDashboardViewModel {
    var lastOperation: OperationResult?
    
    func savePost(_ post: SocialPost) async throws {
        do {
            try await repository.save(post)
            lastOperation = OperationResult(
                type: .save,
                success: true,
                message: "Post saved successfully"
            )
        } catch {
            lastOperation = OperationResult(
                type: .save,
                success: false,
                message: "Failed to save post: \(error.localizedDescription)"
            )
        }
    }
}
```

## Testing

### Unit Tests

All new components have comprehensive unit tests:

```bash
# Run all tests
xcodebuild test -scheme personalos-ios-v2 -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test suite
xcodebuild test -scheme personalos-ios-v2 -only-testing:personalos-ios-v2Tests/ThreadSafetyTests
```

### Property-Based Tests

Critical components use property-based testing with SwiftCheck:

```swift
// Example: Testing Decimal round-trip
property("Decimal persistence round trip") <- forAll { (value: Decimal) in
    let saved = saveToDatabase(value)
    let retrieved = loadFromDatabase(saved.id)
    return retrieved == value
}
```

### Thread Safety Tests

Use Thread Sanitizer to detect data races:

```bash
# Enable Thread Sanitizer in scheme
# Edit Scheme → Run → Diagnostics → Thread Sanitizer
```

## Best Practices

### 1. Always Use Actors for Data Access

```swift
// ✅ Good
actor MyRepository: BaseRepository<MyModel> {
    func fetchAll() async throws -> [MyModel] {
        try await performRead { context in
            try context.fetch(FetchDescriptor<MyModel>())
        }
    }
}

// ❌ Bad
@MainActor
class MyRepository {
    func fetchAll() -> [MyModel] {
        // Direct ModelContext access - not thread safe!
    }
}
```

### 2. Use Decimal for Financial Data

```swift
// ✅ Good
let price = Decimal(string: "19.99")!
let quantity = Decimal(10)
let total = price * quantity

// ❌ Bad
let price = 19.99 // Double - loses precision!
let quantity = 10.0
let total = price * quantity
```

### 3. Handle Errors Gracefully

```swift
// ✅ Good
do {
    try await operation()
} catch let error as AppError {
    errorPresenter.present(error)
    logger.error("Operation failed: \(error)")
} catch {
    errorPresenter.present(.unknown(error))
}

// ❌ Bad
guard success else {
    fatalError("Operation failed") // Crashes app!
}
```

### 4. Cancel Tasks on View Disappear

```swift
// ✅ Good
struct MyView: View {
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        content
            .onDisappear {
                task?.cancel()
            }
    }
    
    func loadData() {
        task = Task {
            try? await viewModel.loadData()
        }
    }
}

// ❌ Bad
struct MyView: View {
    func loadData() {
        Task {
            try? await viewModel.loadData()
            // Task continues even after view disappears!
        }
    }
}
```

### 5. Use Environment for Dependency Injection

```swift
// ✅ Good
struct MyView: View {
    @Environment(ThemeManager.self) var themeManager
    
    var body: some View {
        Text("Hello")
            .foregroundStyle(themeManager.currentTheme.primaryColor)
    }
}

// ❌ Bad
struct MyView: View {
    let themeManager = ThemeManager.shared // Tight coupling!
}
```

## Troubleshooting

### Issue: "Actor-isolated property cannot be referenced from a non-isolated context"

**Solution:** Add `await` when accessing actor properties:

```swift
// ❌ Error
let items = repository.items

// ✅ Fixed
let items = await repository.items
```

### Issue: "Cannot convert value of type 'Double' to expected argument type 'Decimal'"

**Solution:** Use Decimal initializers:

```swift
// ❌ Error
let price: Decimal = 19.99

// ✅ Fixed
let price = Decimal(string: "19.99")!
// or
let price = Decimal(19.99) // Less precise
```

### Issue: Thread Sanitizer reports data race

**Solution:** Ensure all shared state is protected:

```swift
// ❌ Data race
class MyClass {
    var counter = 0 // Accessed from multiple threads
}

// ✅ Fixed with actor
actor MyClass {
    var counter = 0 // Actor-isolated
}
```

### Issue: App crashes with "fatalError"

**Solution:** Replace fatalError with proper error handling:

```swift
// ❌ Crashes
guard let value = optional else {
    fatalError("Value is nil")
}

// ✅ Handles gracefully
guard let value = optional else {
    throw AppError.missingValue("Expected value is nil")
}
```

## Performance Considerations

### 1. Batch Database Operations

```swift
// ✅ Good - Single transaction
try await repository.performWrite { context in
    for item in items {
        context.insert(item)
    }
    try context.save()
}

// ❌ Bad - Multiple transactions
for item in items {
    try await repository.save(item) // Slow!
}
```

### 2. Use Predicates for Filtering

```swift
// ✅ Good - Database filtering
let predicate = #Predicate<TodoItem> { $0.isCompleted == false }
let items = try await repository.fetch(predicate: predicate)

// ❌ Bad - In-memory filtering
let allItems = try await repository.fetch(predicate: nil)
let items = allItems.filter { !$0.isCompleted } // Loads everything!
```

### 3. Cancel Unnecessary Work

```swift
// ✅ Good
Task {
    for await item in stream {
        try Task.checkCancellation()
        await process(item)
    }
}

// ❌ Bad
Task {
    for await item in stream {
        await process(item) // Continues even if cancelled
    }
}
```

## Additional Resources

- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Observation Framework](https://developer.apple.com/documentation/observation)
- [Security Best Practices](./SECURITY_BEST_PRACTICES.md)
- [API Documentation](./API_DOCUMENTATION.md)

## Support

For questions or issues:
1. Check existing GitHub issues
2. Review the design document: `.kiro/specs/system-architecture-upgrade-p0/design.md`
3. Create a new issue with detailed description and reproduction steps
