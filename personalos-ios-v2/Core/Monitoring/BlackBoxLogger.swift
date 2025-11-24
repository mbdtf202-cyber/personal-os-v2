import Foundation
import OSLog

/// ✅ P2 EXTREME OPTIMIZATION: mmap-based crash-safe logger
/// 使用内存映射文件实现"黑匣子"日志，即使应用崩溃也能保留最后的日志
/// 这是真正的"飞行记录器"，用于死后调试 (Post-mortem debugging)

final class BlackBoxLogger {
    static let shared = BlackBoxLogger()
    
    private let fileURL: URL
    private let maxLogSize: Int = 1024 * 1024 // 1MB 环形缓冲区
    private var fileHandle: FileHandle?
    private var mmapPointer: UnsafeMutableRawPointer?
    private var currentOffset: Int = 0
    private let queue = DispatchQueue(label: "com.personalos.blackbox", qos: .utility)
    
    private init() {
        // 使用应用支持目录存储黑匣子日志
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent("BlackBox")
        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        
        fileURL = appSupportDir.appendingPathComponent("crash_log.bin")
        
        setupMemoryMappedFile()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupMemoryMappedFile() {
        queue.sync {
            // 创建或打开文件
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            }
            
            do {
                // 确保文件大小
                let fileHandle = try FileHandle(forUpdating: fileURL)
                try fileHandle.truncate(atOffset: UInt64(maxLogSize))
                fileHandle.closeFile()
                
                // 打开文件用于 mmap
                let fd = open(fileURL.path, O_RDWR)
                guard fd >= 0 else {
                    os_log("Failed to open black box log file", log: .default, type: .error)
                    return
                }
                
                // 内存映射
                let pointer = mmap(nil, maxLogSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
                close(fd) // mmap 后可以关闭 fd
                
                guard pointer != MAP_FAILED else {
                    os_log("Failed to mmap black box log file", log: .default, type: .error)
                    return
                }
                
                mmapPointer = pointer
                
                // 读取当前偏移量（存储在文件开头的 8 字节）
                if let ptr = mmapPointer {
                    currentOffset = ptr.load(as: Int.self)
                    // 验证偏移量合法性
                    if currentOffset < 8 || currentOffset >= maxLogSize {
                        currentOffset = 8 // 重置到数据区起始位置
                    }
                }
                
            } catch {
                os_log("Black box logger setup failed: %{public}@", log: .default, type: .error, error.localizedDescription)
            }
        }
    }
    
    /// 写入关键日志到黑匣子（仅在 Release 模式下保留最关键的信息）
    func log(_ message: String, level: LogLevel = .info, context: [String: String] = [:]) {
        #if !DEBUG
        // Release 模式：仅记录 warning 及以上级别
        guard level.rawValue >= LogLevel.warning.rawValue else { return }
        #endif
        
        queue.async { [weak self] in
            guard let self = self, let pointer = self.mmapPointer else { return }
            
            // 构建紧凑的日志条目
            let timestamp = Date().timeIntervalSince1970
            let entry = BlackBoxEntry(
                timestamp: timestamp,
                level: level,
                message: message,
                context: context
            )
            
            guard let data = try? JSONEncoder().encode(entry) else { return }
            
            // 计算需要的空间（4 字节长度 + 数据）
            let entrySize = 4 + data.count
            
            // 环形缓冲区：如果空间不足，从头开始覆盖
            if self.currentOffset + entrySize > self.maxLogSize {
                self.currentOffset = 8 // 跳过偏移量存储区
            }
            
            // 写入长度
            pointer.advanced(by: self.currentOffset).storeBytes(of: UInt32(data.count), as: UInt32.self)
            self.currentOffset += 4
            
            // 写入数据
            data.withUnsafeBytes { buffer in
                pointer.advanced(by: self.currentOffset).copyMemory(from: buffer.baseAddress!, byteCount: data.count)
            }
            self.currentOffset += data.count
            
            // 更新偏移量到文件头
            pointer.storeBytes(of: self.currentOffset, as: Int.self)
            
            // 强制同步到磁盘（关键操作）
            msync(pointer, self.maxLogSize, MS_SYNC)
        }
    }
    
    /// 读取黑匣子日志（用于崩溃后分析）
    func readLogs() -> [BlackBoxEntry] {
        var entries: [BlackBoxEntry] = []
        
        queue.sync {
            guard let pointer = mmapPointer else { return }
            
            var offset = 8 // 跳过偏移量存储区
            
            while offset < currentOffset {
                // 读取长度
                let length = pointer.advanced(by: offset).load(as: UInt32.self)
                offset += 4
                
                guard length > 0 && length < 10000 else { break } // 防止损坏数据
                
                // 读取数据
                let data = Data(bytes: pointer.advanced(by: offset), count: Int(length))
                offset += Int(length)
                
                if let entry = try? JSONDecoder().decode(BlackBoxEntry.self, from: data) {
                    entries.append(entry)
                }
            }
        }
        
        return entries
    }
    
    /// 导出黑匣子日志为可读文本
    func exportLogs() -> String {
        let entries = readLogs()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        return entries.map { entry in
            let date = Date(timeIntervalSince1970: entry.timestamp)
            let contextStr = entry.context.isEmpty ? "" : " {\(entry.context.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))}"
            return "[\(formatter.string(from: date))] [\(entry.level.rawValue)] \(entry.message)\(contextStr)"
        }.joined(separator: "\n")
    }
    
    /// 清空黑匣子日志
    func clear() {
        queue.sync {
            currentOffset = 8
            if let pointer = mmapPointer {
                pointer.storeBytes(of: currentOffset, as: Int.self)
                msync(pointer, maxLogSize, MS_SYNC)
            }
        }
    }
    
    private func cleanup() {
        queue.sync {
            if let pointer = mmapPointer {
                munmap(pointer, maxLogSize)
                mmapPointer = nil
            }
        }
    }
}

// MARK: - Black Box Entry

enum BlackBoxLogLevel: String, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

struct BlackBoxEntry: Codable {
    let timestamp: TimeInterval
    let level: BlackBoxLogLevel
    let message: String
    let context: [String: String]
}

// MARK: - BlackBoxLogLevel Comparable

extension BlackBoxLogLevel: Comparable {
    static func < (lhs: BlackBoxLogLevel, rhs: BlackBoxLogLevel) -> Bool {
        return lhs.priority < rhs.priority
    }
    
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
}
