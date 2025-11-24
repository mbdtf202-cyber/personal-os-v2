import SwiftUI

struct TimestampConverterView: View {
    @State private var timestampInput = ""
    @State private var convertedDate: Date?
    @State private var errorMessage: String?
    @State private var selectedFormat: TimestampFormat = .seconds
    @State private var showCopiedFeedback = false
    
    enum TimestampFormat: String, CaseIterable {
        case seconds = "Seconds"
        case milliseconds = "Milliseconds"
        
        var divisor: Double {
            switch self {
            case .seconds: return 1
            case .milliseconds: return 1000
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.mistBlue)
                    Text("Timestamp Converter")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Convert Unix timestamps to readable dates")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.top, 20)
                
                // Format Picker
                Picker("Format", selection: $selectedFormat) {
                    ForEach(TimestampFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedFormat) { _, _ in
                    if !timestampInput.isEmpty {
                        convertTimestamp()
                    }
                }
                
                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unix Timestamp")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryText)
                    
                    HStack {
                        TextField("Enter timestamp", text: $timestampInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: timestampInput) { _, _ in
                                convertTimestamp()
                            }
                        
                        Button(action: pasteFromClipboard) {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundStyle(AppTheme.mistBlue)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppTheme.coral)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(AppTheme.coral)
                        }
                        .padding(.top, 4)
                    }
                }
                .glassCard()
                
                // Current Timestamp
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Timestamp")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryText)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Seconds")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("\(Int(Date().timeIntervalSince1970))")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            copyToClipboard("\(Int(Date().timeIntervalSince1970))")
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(AppTheme.mistBlue)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Milliseconds")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("\(Int(Date().timeIntervalSince1970 * 1000))")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            copyToClipboard("\(Int(Date().timeIntervalSince1970 * 1000))")
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(AppTheme.mistBlue)
                        }
                    }
                }
                .glassCard()
                
                // Converted Result
                if let date = convertedDate {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Converted Date")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.primaryText)
                        
                        VStack(spacing: 12) {
                            ResultRow(
                                title: "Full Date",
                                value: formatDate(date, style: .full),
                                onCopy: { copyToClipboard(formatDate(date, style: .full)) }
                            )
                            
                            Divider()
                            
                            ResultRow(
                                title: "ISO 8601",
                                value: formatISO8601(date),
                                onCopy: { copyToClipboard(formatISO8601(date)) }
                            )
                            
                            Divider()
                            
                            ResultRow(
                                title: "Relative",
                                value: formatRelative(date),
                                onCopy: { copyToClipboard(formatRelative(date)) }
                            )
                        }
                    }
                    .glassCard()
                }
                
                // Copy Feedback
                if showCopiedFeedback {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.matcha)
                        Text("Copied to clipboard")
                            .font(.caption)
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .padding()
                    .background(AppTheme.matcha.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
    
    private func convertTimestamp() {
        errorMessage = nil
        convertedDate = nil
        
        guard !timestampInput.isEmpty else { return }
        
        guard let timestamp = Double(timestampInput) else {
            errorMessage = "Invalid timestamp format"
            return
        }
        
        // Validate timestamp range
        let adjustedTimestamp = timestamp / selectedFormat.divisor
        
        // Check if timestamp is reasonable (between 1970 and 2100)
        let minTimestamp: Double = 0
        let maxTimestamp: Double = 4102444800 // Jan 1, 2100
        
        guard adjustedTimestamp >= minTimestamp && adjustedTimestamp <= maxTimestamp else {
            errorMessage = "Timestamp out of valid range"
            return
        }
        
        convertedDate = Date(timeIntervalSince1970: adjustedTimestamp)
        HapticsManager.shared.light()
    }
    
    private func pasteFromClipboard() {
        if let clipboardString = UIPasteboard.general.string {
            timestampInput = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
            HapticsManager.shared.light()
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        showCopiedFeedback = true
        HapticsManager.shared.success()
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
    
    private func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = style
        return formatter.string(from: date)
    }
    
    private func formatISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    private func formatRelative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    let onCopy: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(AppTheme.primaryText)
            }
            
            Spacer()
            
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(AppTheme.mistBlue)
            }
        }
    }
}

#Preview {
    TimestampConverterView()
}
