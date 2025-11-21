import SwiftUI
import SwiftData

@MainActor
struct DependencyAccessor {
    let appDependency: AppDependency?
    
    init(_ appDependency: AppDependency?) {
        self.appDependency = appDependency
    }
    
    var repositories: AppDependency.Repositories {
        guard let dependency = appDependency else {
            fatalError("AppDependency not initialized. Ensure RootView has set up dependencies.")
        }
        return dependency.repositories
    }
    
    var services: AppDependency.Services {
        guard let dependency = appDependency else {
            fatalError("AppDependency not initialized. Ensure RootView has set up dependencies.")
        }
        return dependency.services
    }
}

extension View {
    @MainActor
    func withDependency<Content: View>(_ action: @escaping (DependencyAccessor) -> Content) -> some View {
        self.modifier(DependencyModifier(action: action))
    }
}

private struct DependencyModifier<ActionContent: View>: ViewModifier {
    @Environment(\.appDependency) private var appDependency
    let action: (DependencyAccessor) -> ActionContent
    
    func body(content: Content) -> some View {
        content
        action(DependencyAccessor(appDependency))
    }
}
