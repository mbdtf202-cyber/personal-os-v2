import SwiftUI

/// 带缓存的异步图片加载组件
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var cachedImage: UIImage?
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                content(Image(uiImage: cachedImage))
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        content(image)
                            .onAppear {
                                // Cache the image
                                if let url = url,
                                   let data = try? Data(contentsOf: url),
                                   let uiImage = UIImage(data: data) {
                                    cachedImage = uiImage
                                }
                            }
                    case .failure:
                        placeholder()
                    case .empty:
                        placeholder()
                    @unknown default:
                        placeholder()
                    }
                }
            }
        }
    }
}

#Preview {
    CachedAsyncImage(
        url: URL(string: "https://picsum.photos/400/300")
    ) { image in
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    } placeholder: {
        ProgressView()
    }
    .frame(width: 200, height: 150)
    .cornerRadius(12)
}
