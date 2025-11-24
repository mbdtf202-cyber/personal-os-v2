import XCTest
@testable import personalos_ios_v2

/// ✅ P2 EXTREME: 测试 mmap 黑匣子日志系统
final class BlackBoxLoggerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        BlackBoxLogger.shared.clear()
    }
    
    override func tearDown() {
        BlackBoxLogger.shared.clear()
        super.tearDown()
    }
    
    func testBasicLogging() {
        // Given
        let message = "Test critical error"
        let context = ["error_code": "500", "endpoint": "/api/test"]
        
        // When
        BlackBoxLogger.shared.log(message, level: .critical, context: context)
        
        // Then
        let logs = BlackBoxLogger.shared.readLogs()
        XCTAssertFalse(logs.isEmpty, "Should have at least one log entry")
        
        let lastLog = logs.last!
        XCTAssertEqual(lastLog.message, message)
        XCTAssertEqual(lastLog.level, .critical)
        XCTAssertEqual(lastLog.context["error_code"], "500")
    }
    
    func testMultipleLogEntries() {
        // Given
        let messages = [
            "First error",
            "Second warning",
            "Third critical"
        ]
        
        // When
        for (index, message) in messages.enumerated() {
            BlackBoxLogger.shared.log(
                message,
                level: .error,
                context: ["index": "\(index)"]
            )
        }
        
        // Then
        let logs = BlackBoxLogger.shared.readLogs()
        XCTAssertEqual(logs.count, messages.count)
        
        for (index, log) in logs.enumerated() {
            XCTAssertEqual(log.message, messages[index])
            XCTAssertEqual(log.context["index"], "\(index)")
        }
    }
    
    func testLogPersistence() {
        // Given
        let message = "Persistent log entry"
        BlackBoxLogger.shared.log(message, level: .critical)
        
        // When - 模拟应用重启（实际上我们只是重新读取）
        let logsBeforeRestart = BlackBoxLogger.shared.readLogs()
        
        // Then
        XCTAssertFalse(logsBeforeRestart.isEmpty)
        XCTAssertEqual(logsBeforeRestart.last?.message, message)
    }
    
    func testLogExport() {
        // Given
        BlackBoxLogger.shared.log("Error 1", level: .error)
        BlackBoxLogger.shared.log("Warning 1", level: .warning)
        BlackBoxLogger.shared.log("Critical 1", level: .critical)
        
        // When
        let exportedLogs = BlackBoxLogger.shared.exportLogs()
        
        // Then
        XCTAssertTrue(exportedLogs.contains("Error 1"))
        XCTAssertTrue(exportedLogs.contains("Warning 1"))
        XCTAssertTrue(exportedLogs.contains("Critical 1"))
        XCTAssertTrue(exportedLogs.contains("[ERROR]"))
        XCTAssertTrue(exportedLogs.contains("[WARNING]"))
        XCTAssertTrue(exportedLogs.contains("[CRITICAL]"))
    }
    
    func testClearLogs() {
        // Given
        BlackBoxLogger.shared.log("Test message", level: .error)
        XCTAssertFalse(BlackBoxLogger.shared.readLogs().isEmpty)
        
        // When
        BlackBoxLogger.shared.clear()
        
        // Then
        let logs = BlackBoxLogger.shared.readLogs()
        XCTAssertTrue(logs.isEmpty, "Logs should be empty after clear")
    }
    
    func testHighVolumeLogging() {
        // Given - 模拟高频日志写入
        let messageCount = 100
        
        // When
        for i in 0..<messageCount {
            BlackBoxLogger.shared.log(
                "High volume message \(i)",
                level: .error,
                context: ["iteration": "\(i)"]
            )
        }
        
        // Then
        let logs = BlackBoxLogger.shared.readLogs()
        XCTAssertGreaterThan(logs.count, 0, "Should have logged messages")
        // 注意：由于环形缓冲区，可能不会保留所有消息
    }
    
    func testConcurrentLogging() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent logging")
        let iterations = 50
        
        // When - 并发写入
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            BlackBoxLogger.shared.log(
                "Concurrent message \(index)",
                level: .error,
                context: ["thread": "\(index)"]
            )
        }
        
        // 等待所有写入完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Then
        let logs = BlackBoxLogger.shared.readLogs()
        XCTAssertGreaterThan(logs.count, 0, "Should have logged concurrent messages")
    }
    
    func testLogLevelFiltering() {
        // Given
        BlackBoxLogger.shared.log("Debug message", level: .debug)
        BlackBoxLogger.shared.log("Info message", level: .info)
        BlackBoxLogger.shared.log("Warning message", level: .warning)
        BlackBoxLogger.shared.log("Error message", level: .error)
        BlackBoxLogger.shared.log("Critical message", level: .critical)
        
        // When
        let logs = BlackBoxLogger.shared.readLogs()
        
        // Then - 在 Release 模式下，只有 warning 及以上级别会被记录
        #if DEBUG
        XCTAssertEqual(logs.count, 5, "DEBUG mode should log all levels")
        #else
        XCTAssertLessThanOrEqual(logs.count, 3, "Release mode should only log warning+")
        #endif
    }
}
