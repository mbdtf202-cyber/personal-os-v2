import SwiftUI

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

struct PresentableError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: ErrorSeverity
    let isRecoverable: Bool
    let retryAction: (() async -> Void)?
    
    init(
        title: String,
        message: String,
        severity: ErrorSeverity = .error,
        isRecoverable: Bool = true,
        retryAction: (() async -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.severity = severity
        self.isRecoverable = isRecoverable
        self.retryAction = retryAction
    }
    
    static func from(_ error: Error, context: String? = nil) -> PresentableError {
        let message: String
        let severity: ErrorSeverity
        let isRecoverable: Bool
        
        switch error {
        case NetworkError.circuitBreakerOpen:
            message = "Service temporarily unavailable. Please try again later."
            severity = .warning
            isRecoverable = true
            
        case NetworkError.rateLimited:
            message = "Too many requests. Please wait a moment."
            severity = .warning
            isRecoverable = true
            
        case NetworkError.timeout:
            message = "Request timed out. Check your connection."
            severity = .warning
            isRecoverable = true
            
        case NetworkError.serverError(let code):
            message = "Server error (\(code)). Please try again."
            severity = .error
            isRecoverable = true
            
        case is ConfigurationError:
            message = error.localizedDescription
            severity = .warning
            isRecoverable = false
            
        default:
            message = error.localizedDescription
            severity = .error
            isRecoverable = true
        }
        
        let title = context ?? "Error"
        
        return PresentableError(
            title: title,
            message: message,
            severity: severity,
            isRecoverable: isRecoverable
        )
    }
}

@MainActor
@Observable
class ErrorPresenter {
    static let shared = ErrorPresenter()
    
    var currentError: PresentableError?
    var toastMessage: String?
    
    private init() {}
    
    func present(_ error: PresentableError) {
        if error.severity == .critical {
            currentError = error
        } else {
            showToast(error.message)
        }
    }
    
    func present(_ error: Error, context: String? = nil) {
        let appError = PresentableError.from(error, context: context)
        present(appError)
    }
    
    func showToast(_ message: String) {
        toastMessage = message
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            toastMessage = nil
        }
    }
    
    func dismiss() {
        currentError = nil
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 10)
    }
}

// MARK: - Error Alert View
struct ErrorAlertView: View {
    let error: PresentableError
    let onDismiss: () -> Void
    let onRetry: (() async -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.severity.icon)
                .font(.system(size: 50))
                .foregroundStyle(error.severity.color)
            
            Text(error.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                if error.isRecoverable, let retry = onRetry {
                    Button("Retry") {
                        Task {
                            await retry()
                            onDismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button(error.isRecoverable ? "Dismiss" : "OK") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding(40)
    }
}
