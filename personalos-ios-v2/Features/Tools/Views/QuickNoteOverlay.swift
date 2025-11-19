import SwiftUI

struct QuickNoteOverlay: View {
    @Binding var isPresented: Bool
    @State private var noteText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { isPresented = false }
                }
            
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Quick Note")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Button("Done") {
                            withAnimation { isPresented = false }
                        }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.mistBlue)
                    }
                    
                    TextEditor(text: $noteText)
                        .frame(height: 120)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(AppTheme.background)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                    
                    HStack(spacing: 20) {
                        Button(action: {}) {
                            Label("Scan", systemImage: "doc.viewfinder")
                        }
                        Button(action: {}) {
                            Label("Image", systemImage: "photo")
                        }
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(radius: 20)
                .padding()
                .padding(.bottom, 20)
            }
        }
        .onAppear { isFocused = true }
    }
}

#Preview {
    QuickNoteOverlay(isPresented: .constant(true))
}
