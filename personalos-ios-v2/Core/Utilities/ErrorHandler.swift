import Foundation
import SwiftUI

@MainActor
@Observable
class ErrorHandler {
    static let shared = ErrorHandler()
    
    // 🔧 P2 Fix: 使用错误队列替代单一错误，避免竞争
    private(set) var errorQueue: [ErrorEntry] = []
    var showError: Bool = false
    
    var currentError: (any Error)? {
        errorQueue.first?.error
    }
    
    private init() {}
    
    func handle(_ error: Error, context: String = "") {
        let entry = ErrorEntry(error: error, context: context)
        errorQueue.append(entry)
        
        if !showError {
            showError = true
        }
        
        // 记录错误日志
        Logger.error("[\(context)] \(error.localizedDescription)", category: Logger.general)
    }
    
    func clearError() {
        if !errorQueue.isEmpty {
            errorQueue.removeFirst()
        }
        
        if errorQueue.isEmpty {
            showError = false
        }
    }
    
    func clearAllErrors() {
        errorQueue.removeAll()
        showError = false
    }
}

struct ErrorEntry: Identifiable {
    let id = UUID()
    let error: any Error
    let context: String
    let timestamp = Date()
}

// MARK: - View Extension
extension View {
    func errorAlert() -> some View {
        @State var errorHandler = ErrorHandler.shared
        
        return self.alert(
            "Error",
            isPresented: Binding(
                get: { errorHandler.showError },
                set: { if !$0 { errorHandler.clearError() } }
            )
        ) {
            Button("OK") {
                errorHandler.clearError()
            }
        } message: {
            if let error = errorHandler.currentError {
                Text(error.localizedDescription)
            }
        }
    }
}
