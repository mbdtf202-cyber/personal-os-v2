import Foundation
import SwiftUI

enum AppError: LocalizedError {
    case network(String)
    case database(String)
    case validation(String)
    case unauthorized
    case notFound
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .network(let message):
            return "Network Error: \(message)"
        case .database(let message):
            return "Database Error: \(message)"
        case .validation(let message):
            return "Validation Error: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .notFound:
            return "Resource not found"
        case .unknown(let error):
            return "Unknown Error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .network:
            return "Please check your internet connection and try again."
        case .database:
            return "Please restart the app. If the problem persists, contact support."
        case .validation:
            return "Please check your input and try again."
        case .unauthorized:
            return "Please log in again."
        case .notFound:
            return "The requested resource could not be found."
        case .unknown:
            return "Please try again later."
        }
    }
}

@MainActor
@Observable
class ErrorHandler {
    static let shared = ErrorHandler()
    
    var currentError: AppError?
    var showError: Bool = false
    
    private init() {}
    
    func handle(_ error: Error, context: String = "") {
        let appError: AppError
        
        if let err = error as? AppError {
            appError = err
        } else if let urlError = error as? URLError {
            appError = .network(urlError.localizedDescription)
        } else {
            appError = .unknown(error)
        }
        
        currentError = appError
        showError = true
        
        // 记录错误日志
        Logger.error("[\(context)] \(appError.errorDescription ?? "Unknown error")", category: Logger.general)
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
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
            ),
            presenting: errorHandler.currentError
        ) { _ in
            Button("OK") {
                errorHandler.clearError()
            }
        } message: { error in
            VStack(alignment: .leading, spacing: 8) {
                if let description = error.errorDescription {
                    Text(description)
                }
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                }
            }
        }
    }
}
