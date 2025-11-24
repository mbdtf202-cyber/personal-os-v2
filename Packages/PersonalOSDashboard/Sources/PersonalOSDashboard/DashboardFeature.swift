import SwiftUI

/// Dashboard Feature Entry Point
/// 提供编译时 Feature Toggle 能力
public struct DashboardFeature {
    public static var isEnabled: Bool {
        #if FEATURE_DASHBOARD
        return true
        #else
        return false
        #endif
    }
    
    public init() {}
}

/// Feature 导出的公共接口
public protocol DashboardFeatureProtocol {
    associatedtype Content: View
    @ViewBuilder func makeView() -> Content
}
