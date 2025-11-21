import XCTest
@testable import personalos_ios_v2

@MainActor
final class CloudSyncManagerTests: XCTestCase {
    var syncManager: CloudSyncManager!
    
    override func setUp() {
        syncManager = CloudSyncManager.shared
    }
    
    func testInitialState() {
        XCTAssertEqual(syncManager.syncStatus, .idle)
        XCTAssertNil(syncManager.lastSyncDate)
    }
    
    func testSyncStatusEquality() {
        XCTAssertEqual(SyncStatus.idle, SyncStatus.idle)
        XCTAssertEqual(SyncStatus.syncing, SyncStatus.syncing)
        XCTAssertEqual(SyncStatus.synced, SyncStatus.synced)
    }
}
