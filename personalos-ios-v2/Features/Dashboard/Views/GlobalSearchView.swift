import SwiftUI
import Combine

struct GlobalSearchView: View {
    @Binding var isPresented: Bool
    @Environment(AppRouter.self) private var router
    @State private var query = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // 背景点击关闭
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { isPresented = false }
                }
            
            // 搜索面板
            VStack(spacing: 0) {
                // 输入框区域
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    TextField("Search anything...", text: $query)
                        .font(.title3)
                        .focused($isFocused)
                        .submitLabel(.search)
                    
                    if !query.isEmpty {
                        Button(action: { query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                    }
                    
                    Text("ESC")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.tertiaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppTheme.border, lineWidth: 1))
                }
                .padding(20)
                .background(.ultraThinMaterial)
                
                Divider().background(AppTheme.border)
                
                // 结果区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if query.isEmpty {
                            Text("SUGGESTED ACTIONS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.secondaryText)
                            
                            Button(action: {
                                router.navigate(to: .social)
                                isPresented = false
                            }) {
                                ActionRow(icon: "doc.text", title: "Create new note")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                router.navigate(to: .health)
                                isPresented = false
                            }) {
                                ActionRow(icon: "figure.run", title: "Log workout")
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                router.navigate(to: .trading)
                                isPresented = false
                            }) {
                                ActionRow(icon: "chart.line.uptrend.xyaxis", title: "Log trade")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("RESULTS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("Searching for '\(query)'...")
                                .foregroundStyle(AppTheme.secondaryText)
                                .padding(.top, 20)
                        }
                    }
                    .padding(20)
                }
                .frame(maxHeight: 300)
                .background(Color.white.opacity(0.8))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .offset(y: -50)
        }
        .onAppear { isFocused = true }
        .transition(.opacity)
    }
}

struct ActionRow: View {
    var icon: String
    var title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GlobalSearchView(isPresented: .constant(true))
}
