import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            AppContainer()
        }
    }
}

#Preview {
    ContentView()
}
