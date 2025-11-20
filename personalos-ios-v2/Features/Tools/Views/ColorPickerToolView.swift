import SwiftUI

struct ColorPickerToolView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedColor: Color = .blue
    @State private var hexValue: String = "#0000FF"
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Color Preview
                        VStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedColor)
                                .frame(height: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white, lineWidth: 4)
                                )
                                .shadow(color: selectedColor.opacity(0.5), radius: 20, y: 10)
                            
                            Text(hexValue)
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.primaryText)
                        }
                        .glassCard()
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Color")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            
                            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .onChange(of: selectedColor) { _, newValue in
                                    updateHexValue(from: newValue)
                                }
                        }
                        .glassCard()
                        
                        // Color Values
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Color Values")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            
                            VStack(spacing: 12) {
                                ColorValueRow(label: "HEX", value: hexValue)
                                ColorValueRow(label: "RGB", value: rgbValue)
                                ColorValueRow(label: "HSB", value: hsbValue)
                            }
                        }
                        .glassCard()
                        
                        // Quick Colors
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Colors")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                ForEach(quickColors, id: \.self) { color in
                                    Button {
                                        selectedColor = color
                                        HapticsManager.shared.light()
                                    } label: {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(color)
                                            .frame(height: 60)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                            )
                                    }
                                }
                            }
                        }
                        .glassCard()
                        
                        // Copy Button
                        Button {
                            copyToClipboard()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy HEX Value")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.coral)
                            .cornerRadius(16)
                            .shadow(color: AppTheme.coral.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.horizontal)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Color Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("HEX value copied to clipboard")
            }
            .onAppear {
                updateHexValue(from: selectedColor)
            }
        }
    }
    
    private var quickColors: [Color] {
        [
            .red, .orange, .yellow, .green, .blue, .purple,
            .pink, .brown, .cyan, .indigo, .mint, .teal,
            AppTheme.matcha, AppTheme.mistBlue, AppTheme.coral,
            AppTheme.almond, AppTheme.lavender, .black
        ]
    }
    
    private var rgbValue: String {
        let components = UIColor(selectedColor).cgColor.components ?? [0, 0, 0]
        let r = Int((components[0]) * 255)
        let g = Int((components[1]) * 255)
        let b = Int((components[2]) * 255)
        return "rgb(\(r), \(g), \(b))"
    }
    
    private var hsbValue: String {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        UIColor(selectedColor).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        return "hsb(\(Int(hue * 360))°, \(Int(saturation * 100))%, \(Int(brightness * 100))%)"
    }
    
    private func updateHexValue(from color: Color) {
        let components = UIColor(color).cgColor.components ?? [0, 0, 0]
        let r = Int((components[0]) * 255)
        let g = Int((components[1]) * 255)
        let b = Int((components[2]) * 255)
        hexValue = String(format: "#%02X%02X%02X", r, g, b)
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = hexValue
        showCopiedAlert = true
        HapticsManager.shared.success()
    }
}

struct ColorValueRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(AppTheme.primaryText)
            
            Spacer()
            
            Button {
                UIPasteboard.general.string = value
                HapticsManager.shared.light()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mistBlue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    ColorPickerToolView()
}
