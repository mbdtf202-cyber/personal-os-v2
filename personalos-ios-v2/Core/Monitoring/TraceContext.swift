import Foundation

/// 追踪上下文，用于在整个请求链路中传播追踪信息
struct TraceContext: Sendable {
    let traceID: String
    let spanID: String
    let parentSpanID: String?
    let timestamp: Date
    let attributes: [String: String]
    
    init(
        traceID: String = UUID().uuidString,
        spanID: String = UUID().uuidString,
        parentSpanID: String? = nil,
        attributes: [String: String] = [:]
    ) {
        self.traceID = traceID
        self.spanID = spanID
        self.parentSpanID = parentSpanID
        self.timestamp = Date()
        self.attributes = attributes
    }
    
    /// 创建子 span
    func createChildSpan(attributes: [String: String] = [:]) -> TraceContext {
        var mergedAttributes = self.attributes
        mergedAttributes.merge(attributes) { _, new in new }
        
        return TraceContext(
            traceID: traceID,
            spanID: UUID().uuidString,
            parentSpanID: spanID,
            attributes: mergedAttributes
        )
    }
    
    /// 转换为日志上下文
    func toLogContext() -> [String: String] {
        var context = attributes
        context["trace_id"] = traceID
        context["span_id"] = spanID
        if let parentSpanID = parentSpanID {
            context["parent_span_id"] = parentSpanID
        }
        return context
    }
}

/// 追踪上下文管理器
@MainActor
final class TraceContextManager {
    static let shared = TraceContextManager()
    
    private var currentContext: TraceContext?
    private var contextStack: [TraceContext] = []
    
    private init() {}
    
    /// 开始新的追踪
    func startTrace(attributes: [String: String] = [:]) -> TraceContext {
        let context = TraceContext(attributes: attributes)
        currentContext = context
        contextStack.append(context)
        return context
    }
    
    /// 开始子 span
    func startSpan(attributes: [String: String] = [:]) -> TraceContext {
        let context = currentContext?.createChildSpan(attributes: attributes) ?? TraceContext(attributes: attributes)
        currentContext = context
        contextStack.append(context)
        return context
    }
    
    /// 结束当前 span
    func endSpan() {
        guard !contextStack.isEmpty else { return }
        contextStack.removeLast()
        currentContext = contextStack.last
    }
    
    /// 获取当前上下文
    func getCurrentContext() -> TraceContext? {
        return currentContext
    }
    
    /// 清除所有上下文
    func clearAll() {
        currentContext = nil
        contextStack.removeAll()
    }
}
