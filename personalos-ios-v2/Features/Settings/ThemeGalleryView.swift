import SwiftUI

struct ThemeGalleryView: View {
    @Binding var themeStyle: ThemeStyle

    var body: some View {
        List {
            Section(header: Text("iOS 灵感主题")) {
                ForEach(ThemeStyle.allCases) { style in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            themeStyle = style
                        }
                    } label: {
                        HStack(spacing: 16) {
                            themePreview(for: style)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(style.title)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(style.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Spacer()
                            if themeStyle == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.matcha)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Themes")
        .background(AppTheme.background)
    }

    private func themePreview(for style: ThemeStyle) -> some View {
        let palette = style.palette
        return ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(palette.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(palette.border, lineWidth: 1)
                )
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Circle().fill(palette.matcha).frame(width: 12)
                    Circle().fill(palette.mistBlue).frame(width: 12)
                    Circle().fill(palette.lavender).frame(width: 12)
                    Circle().fill(palette.almond).frame(width: 12)
                    Circle().fill(palette.coral).frame(width: 12)
                }
                RoundedRectangle(cornerRadius: 6)
                    .fill(palette.secondaryBackground)
                    .frame(width: 60, height: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(palette.mistBlue.opacity(0.8))
                            .frame(width: 32)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
            }
            .padding(10)
        }
        .frame(width: 96, height: 72)
        .shadow(color: palette.shadow, radius: 6, y: 3)
    }
}

#Preview {
    NavigationStack {
        ThemeGalleryView(themeStyle: .constant(.glass))
    }
}
