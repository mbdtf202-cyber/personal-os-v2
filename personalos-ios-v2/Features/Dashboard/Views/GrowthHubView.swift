import SwiftUI

struct GrowthHubView: View {
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部切换器
                Picker("Mode", selection: $selectedSegment) {
                    Text("Projects").tag(0)
                    Text("Knowledge").tag(1)
                    Text("Tools").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(AppTheme.background)
                
                // 内容区域
                TabView(selection: $selectedSegment) {
                    ProjectListView()
                        .tag(0)
                    
                    KnowledgeBaseView()
                        .tag(1)
                    
                    ToolsView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .background(AppTheme.background)
        }
    }
    
    private var navigationTitle: String {
        switch selectedSegment {
        case 0: return "Project Hub"
        case 1: return "Knowledge Base"
        case 2: return "Efficiency Tools"
        default: return "Growth"
        }
    }
}

#Preview {
    GrowthHubView()
}
