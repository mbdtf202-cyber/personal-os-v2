import XCTest
@testable import personalos_ios_v2

@MainActor
final class HealthStoreManagerTests: XCTestCase {
    var healthManager: HealthStoreManager!
    
    override func setUp() {
        healthManager = HealthStoreManager()
    }
    
    override func tearDown() {
        healthManager = nil
    }
    
    func testInitialState() {
        XCTAssertEqual(healthManager.steps, 0)
        XCTAssertEqual(healthManager.sleepHours, 0.0)
        XCTAssertEqual(healthManager.heartRate, 0)
    }
    
    func testHealthKitAvailability() {
        // HealthKit 在模拟器上可能不可用
        // 这个测试只验证属性存在
        _ = healthManager.isHealthKitAvailable
    }
}
