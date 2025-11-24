import UIKit
import Foundation

/// 内存警告处理器
@MainActor
final class MemoryWarningHandler {
    static let shared = MemoryWarningHandler()
    
    private var observers: [WeakObserver] = []
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        StructuredLogger.shared.warning("Memory warning received, cleaning up resources")
        
        // 清理图片缓存
        Task {
            await ImageCache.shared.clearMemoryCache()
        }
        
        // 通知所有观察者
        observers = observers.filter { $0.observer != nil }
        observers.forEach { $0.observer?.handleMemoryWarning() }
        
        // 记录内存使用情况
        logMemoryUsage()
        
        // 上报到监控系统
        PerformanceMonitor.shared.recordCustomMetric(name: "memory_warning", value: 1)
    }
    
    func addObserver(_ observer: MemoryWarningObserver) {
        observers.append(WeakObserver(observer: observer))
    }
    
    func removeObserver(_ observer: MemoryWarningObserver) {
        observers.removeAll { $0.observer === observer }
    }
    
    private func logMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024 / 1024 // MB
            StructuredLogger.shared.info(
                "Current memory usage: \(String(format: "%.2f", usedMemory)) MB",
                context: ["memory_mb": String(format: "%.2f", usedMemory)]
            )
        }
    }
}

protocol MemoryWarningObserver: AnyObject {
    func handleMemoryWarning()
}

private struct WeakObserver {
    weak var observer: MemoryWarningObserver?
}
