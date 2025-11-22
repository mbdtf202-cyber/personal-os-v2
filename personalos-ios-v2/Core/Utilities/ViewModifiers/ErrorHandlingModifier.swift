import SwiftUI

// ✅ 统一错误处理 ViewModifier，避免重复代码
struct ErrorHandlingModifier: ViewModifier {
    @Bindable var viewModel: BaseViewModel
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $viewModel.isError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
    }
}

extension View {
    func handleErrors(from viewModel: BaseViewModel) -> some View {
        modifier(ErrorHandlingModifier(viewModel: viewModel))
    }
}
