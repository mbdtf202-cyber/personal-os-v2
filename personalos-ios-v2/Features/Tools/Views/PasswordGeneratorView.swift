import SwiftUI

struct PasswordGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var length: Double = 16
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Password Display
                        VStack(spacing: 16) {
                            Text(password.isEmpty ? "Tap Generate" : password)
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 100)
                                .background(Color.white)
                                .cornerRadius(16)
                            
                            if !password.isEmpty {
                                HStack(spacing: 12) {
                                    Button {
                                        copyToClipboard()
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(AppTheme.lavender)
                                            .cornerRadius(12)
                                    }
                                    
                                    Button {
                                        generatePassword()
                                    } label: {
                                        Label("Regenerate", systemImage: "arrow.clockwise")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(AppTheme.mistBlue)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .glassCard()
                        
                        // Settings
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Settings")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Length: \(Int(length))")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.secondaryText)
                                    Spacer()
                                }
                                Slider(value: $length, in: 8...32, step: 1)
                                    .tint(AppTheme.lavender)
                                
                                Divider()
                                
                                Toggle("Uppercase (A-Z)", isOn: $includeUppercase)
                                Toggle("Lowercase (a-z)", isOn: $includeLowercase)
                                Toggle("Numbers (0-9)", isOn: $includeNumbers)
                                Toggle("Symbols (!@#$%)", isOn: $includeSymbols)
                            }
                            .font(.subheadline)
                        }
                        .glassCard()
                        
                        // Generate Button
                        Button {
                            generatePassword()
                        } label: {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("Generate Password")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.lavender)
                            .cornerRadius(16)
                            .shadow(color: AppTheme.lavender.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.horizontal)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Password Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Password copied to clipboard")
            }
        }
    }
    
    private func generatePassword() {
        var characters = ""
        if includeUppercase { characters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if includeLowercase { characters += "abcdefghijklmnopqrstuvwxyz" }
        if includeNumbers { characters += "0123456789" }
        if includeSymbols { characters += "!@#$%^&*()_+-=[]{}|;:,.<>?" }
        
        guard !characters.isEmpty else {
            password = "Select at least one option"
            return
        }
        
        password = String((0..<Int(length)).map { _ in characters.randomElement()! })
        HapticsManager.shared.success()
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = password
        showCopiedAlert = true
        HapticsManager.shared.success()
    }
}

#Preview {
    PasswordGeneratorView()
}
