import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGeneratorView: View {
    @State private var inputText = ""
    @State private var qrCodeImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enter Text or URL")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        
                        TextEditor(text: $inputText)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                        
                        Button(action: generateQRCode) {
                            HStack {
                                Image(systemName: "qrcode")
                                Text("Generate QR Code")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.mistBlue)
                            .cornerRadius(12)
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding()
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(20)
                    
                    // QR Code Display
                    if let qrCodeImage = qrCodeImage {
                        VStack(spacing: 16) {
                            Text("Your QR Code")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            
                            Image(uiImage: qrCodeImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: AppTheme.shadow, radius: 10, y: 5)
                            
                            HStack(spacing: 16) {
                                Button(action: shareQRCode) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.mistBlue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.mistBlue.opacity(0.1))
                                    .cornerRadius(10)
                                }
                                
                                Button(action: saveQRCode) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Save")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.matcha)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.matcha.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(20)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("QR Code Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateQRCode() {
        guard !inputText.isEmpty else { return }
        
        filter.message = Data(inputText.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
                HapticsManager.shared.success()
                Logger.log("QR Code generated successfully", category: .general)
            }
        }
    }
    
    private func shareQRCode() {
        guard let image = qrCodeImage else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [image, inputText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func saveQRCode() {
        guard let image = qrCodeImage else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        HapticsManager.shared.success()
        Logger.log("QR Code saved to Photos", category: .general)
    }
}

#Preview {
    QRCodeGeneratorView()
}
