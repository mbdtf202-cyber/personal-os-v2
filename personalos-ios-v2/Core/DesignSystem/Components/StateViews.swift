import SwiftUI

// Note: LoadingView and EmptyStateView are defined in their own files

// MARK: - Error View
struct ErrorView: View {
    var error: Error
    var retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Skeleton View
struct SkeletonView: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 4
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating.toggle()
                }
            }
    }
}

// MARK: - Badge
struct Badge: View {
    var text: String
    var color: Color = .blue
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

// MARK: - View State Wrapper
enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
    case empty
}

struct StateView<T, Content: View, EmptyContent: View>: View {
    let state: ViewState<T>
    let content: (T) -> Content
    let emptyView: EmptyContent
    let retryAction: (() -> Void)?
    
    init(
        state: ViewState<T>,
        @ViewBuilder content: @escaping (T) -> Content,
        @ViewBuilder emptyView: () -> EmptyContent,
        retryAction: (() -> Void)? = nil
    ) {
        self.state = state
        self.content = content
        self.emptyView = emptyView()
        self.retryAction = retryAction
    }
    
    var body: some View {
        switch state {
        case .idle:
            Color.clear
        case .loading:
            LoadingView()
        case .loaded(let data):
            content(data)
        case .error(let error):
            ErrorView(error: error, retryAction: retryAction)
        case .empty:
            emptyView
        }
    }
}
