import Foundation
import HealthKit
import Combine
import Observation

// MARK: - Protocol
protocol HealthServiceProtocol {
    func requestAuthorization() async throws
    func fetchDailySteps() async throws -> Double
    func fetchWeeklyActivity() async throws -> [String: Double]
}

enum HealthDataError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case dataUnavailable
    case networkError
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "Health data access was denied. Please enable in Settings."
        case .dataUnavailable:
            return "Health data is currently unavailable"
        case .networkError:
            return "Network error while syncing health data"
        case .timeout:
            return "Health data request timed out"
        }
    }
}

@MainActor
@Observable
class HealthKitService: HealthServiceProtocol {
    private let healthStore = HKHealthStore()
    
    var isAuthorized = false
    var authorizationDenied = false
    var todaySteps: Int = 0
    var lastNightSleep: Double = 0.0
    var heartRate: Int = 0
    var isOffline = false
    var lastSyncDate: Date?
    
    private var retryCount = 0
    private let maxRetries = 3
    
    func requestAuthorization() async throws {
        let traceID = PerformanceMonitor.shared.startTrace(
            name: "health_authorization",
            attributes: ["operation": "request_permission"]
        )
        
        defer {
            PerformanceMonitor.shared.stopTrace(traceID)
        }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthDataError.notAvailable
        }
        
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw HealthDataError.notAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [stepType, sleepType, heartRateType]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            
            // 检查实际授权状态
            let stepStatus = healthStore.authorizationStatus(for: stepType)
            
            if stepStatus == .sharingDenied {
                authorizationDenied = true
                isAuthorized = false
                throw HealthDataError.authorizationDenied
            }
            
            isAuthorized = true
            authorizationDenied = false
            retryCount = 0
            
            await fetchTodaySteps()
            await fetchLastNightSleep()
            await fetchLatestHeartRate()
            
            lastSyncDate = Date()
            
            StructuredLogger.shared.info("HealthKit authorization successful", category: "health")
        } catch let error as HealthDataError {
            authorizationDenied = true
            StructuredLogger.shared.error("HealthKit authorization failed: \(error.localizedDescription)", category: "health")
            throw error
        } catch {
            authorizationDenied = true
            StructuredLogger.shared.error("HealthKit authorization failed: \(error.localizedDescription)", category: "health")
            throw HealthDataError.authorizationDenied
        }
    }
    
    func fetchTodaySteps() async {
        let traceID = PerformanceMonitor.shared.startTrace(
            name: "health_fetch_steps",
            attributes: ["data_type": "steps"]
        )
        
        defer {
            PerformanceMonitor.shared.stopTrace(traceID)
        }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            StructuredLogger.shared.warning("Step count type not available", category: "health")
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // ✅ Task 28: Use weak self in query completion handler
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume()
                return
            }
            
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                if let error = error {
                    StructuredLogger.shared.error("Failed to fetch steps: \(error.localizedDescription)", category: "health")
                    self?.handleHealthDataError(error)
                    continuation.resume()
                    return
                }
                
                Task { @MainActor [weak self] in
                    guard let self = self else {
                        continuation.resume()
                        return
                    }
                    
                    if let result = result, let sum = result.sumQuantity() {
                        self.todaySteps = Int(sum.doubleValue(for: HKUnit.count()))
                        self.isOffline = false
                        PerformanceMonitor.shared.recordCustomMetric(name: "health_steps_fetched", value: Double(self.todaySteps))
                    } else {
                        // 区分真实零值和缺失数据
                        self.todaySteps = 0
                        StructuredLogger.shared.info("No step data available (may be zero or missing)", category: "health")
                    }
                    continuation.resume()
                }
            }
            
            self.healthStore.execute(query)
        }
    }
    
    private func handleHealthDataError(_ error: Error) {
        retryCount += 1
        
        if retryCount >= maxRetries {
            isOffline = true
            StructuredLogger.shared.warning("Health data offline after \(maxRetries) retries", category: "health")
        }
        
        PerformanceMonitor.shared.recordCustomMetric(name: "health_error", value: 1)
    }
    
    func retryFetchWithBackoff() async {
        guard retryCount < maxRetries else {
            StructuredLogger.shared.error("Max retries reached for health data", category: "health")
            return
        }
        
        let delay = pow(2.0, Double(retryCount)) // 指数退避: 1s, 2s, 4s
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        await fetchTodaySteps()
        await fetchLastNightSleep()
        await fetchLatestHeartRate()
    }
    
    func fetchLastNightSleep() async {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let now = Date()
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        
        // ✅ Task 28: Use weak self in query completion handler
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            let sleepHours = samples
                .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }
                .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 3600 }
            
            Task { @MainActor [weak self] in
                self?.lastNightSleep = sleepHours
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchLatestHeartRate() async {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // ✅ Task 28: Use weak self in query completion handler
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            Task { @MainActor [weak self] in
                self?.heartRate = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchSleepHours(from startDate: Date, to endDate: Date) async -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        
        // ✅ Task 28: Use weak self in query completion handler
        return await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: 0)
                return
            }
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let sleepHours = samples
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 3600 }
                
                continuation.resume(returning: sleepHours)
            }
            
            self.healthStore.execute(query)
        }
    }
}

// MARK: - Protocol Conformance
extension HealthKitService {
    func fetchDailySteps() async throws -> Double {
        let traceID = PerformanceMonitor.shared.startTrace(
            name: "health_daily_steps",
            attributes: ["operation": "fetch"]
        )
        
        defer {
            PerformanceMonitor.shared.stopTrace(traceID, metrics: [
                "steps": Double(todaySteps)
            ])
        }
        
        await fetchTodaySteps()
        return Double(todaySteps)
    }
    
    func fetchWeeklyActivity() async throws -> [String: Double] {
        let traceID = PerformanceMonitor.shared.startTrace(
            name: "health_weekly_activity",
            attributes: ["operation": "fetch"]
        )
        
        defer {
            PerformanceMonitor.shared.stopTrace(traceID)
        }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthDataError.notAvailable
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        // ✅ Task 28: Use weak self in query completion handler
        return await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: [:])
                return
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE"
            
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: startOfWeek,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    StructuredLogger.shared.error("Failed to fetch weekly activity: \(error.localizedDescription)", category: "health")
                    continuation.resume(returning: [:])
                    return
                }
                
                var data: [String: Double] = [:]
                results?.enumerateStatistics(from: startOfWeek, to: now) { statistics, _ in
                    let dayName = dateFormatter.string(from: statistics.startDate)
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    data[dayName] = steps
                }
                
                PerformanceMonitor.shared.recordCustomMetric(name: "health_weekly_data_points", value: Double(data.count))
                
                continuation.resume(returning: data)
            }
            
            self.healthStore.execute(query)
        }
    }
}
