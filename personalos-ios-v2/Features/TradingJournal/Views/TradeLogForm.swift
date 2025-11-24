import SwiftUI
import SwiftData

struct TradeLogForm: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appDependency) private var appDependency

    @State private var symbol: String = ""
    @State private var type: TradeType = .buy
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var note: String = ""
    @State private var assetType: AssetType = .stock
    @State private var emotion: TradeEmotion = .neutral
    @State private var tradeDate: Date = Date()
    @State private var riskAlerts: [RiskAlert] = []
    @State private var showRiskWarning = false
    @State private var overrideRisk = false
    @State private var isSaving = false
    
    @StateObject private var riskManager = RiskManager()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Asset Details")) {
                    TextField("Symbol (e.g. AAPL)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                    
                    Picker("Asset Type", selection: $assetType) {
                        ForEach(AssetType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.icon).tag(type)
                        }
                    }
                    
                    Picker("Type", selection: $type) {
                        ForEach(TradeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        TextField("Price", text: $price)
                            .keyboardType(.decimalPad)
                        Divider()
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Trade Date", selection: $tradeDate, displayedComponents: [.date, .hourAndMinute])
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            hideKeyboard()
                        }
                    }
                }
                
                Section(header: Text("Psychology")) {
                    Picker("Emotion", selection: $emotion) {
                        ForEach(TradeEmotion.allCases, id: \.self) { emotion in
                            HStack {
                                Circle()
                                    .fill(emotion.color)
                                    .frame(width: 12, height: 12)
                                Text(emotion.rawValue)
                            }
                            .tag(emotion)
                        }
                    }
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
                
                if !symbol.isEmpty && !price.isEmpty && !quantity.isEmpty {
                    Section(header: Text("Summary")) {
                        HStack {
                            Text("Total Value")
                            Spacer()
                            Text("$\((Double(price) ?? 0) * (Double(quantity) ?? 0), specifier: "%.2f")")
                                .fontWeight(.bold)
                        }
                    }
                }
                
                // Risk Alerts Section
                if !riskAlerts.isEmpty {
                    Section(header: Text("Risk Warnings")) {
                        ForEach(riskAlerts) { alert in
                            HStack(spacing: 12) {
                                Image(systemName: alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                    .foregroundStyle(alert.severity.color)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(alert.message)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.primaryText)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if riskAlerts.contains(where: { $0.severity == .critical }) {
                            Toggle("Override Risk Limits", isOn: $overrideRisk)
                                .font(.caption)
                                .foregroundStyle(AppTheme.coral)
                        }
                    }
                }
            }
            .navigationTitle("Log Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveTrade()
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryText)
                    .disabled(isSaving)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .onChange(of: price) { _, _ in validateTrade() }
            .onChange(of: quantity) { _, _ in validateTrade() }
            .onChange(of: symbol) { _, _ in validateTrade() }
            .onChange(of: type) { _, _ in validateTrade() }
            .onChange(of: emotion) { _, _ in validateTrade() }
            .alert("Risk Warning", isPresented: $showRiskWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Save Anyway", role: .destructive) {
                    Task {
                        await performSave(overrideRisk: true)
                    }
                }
            } message: {
                Text("This trade violates risk management rules. Are you sure you want to proceed?")
            }
        }
    }

    private func validateTrade() {
        guard !symbol.isEmpty, let p = Double(price), let q = Double(quantity), p > 0, q > 0 else {
            riskAlerts = []
            return
        }
        
        let tempTrade = TradeRecord(
            symbol: symbol.uppercased(),
            type: type,
            price: p,
            quantity: q,
            assetType: assetType,
            emotion: emotion,
            note: note,
            date: tradeDate
        )
        
        // Evaluate risk
        riskAlerts = riskManager.evaluateTrade(tempTrade)
    }
    
    private func saveTrade() async {
        guard !symbol.isEmpty, let p = Double(price), let q = Double(quantity), p > 0, q > 0 else {
            return
        }
        
        // Check for critical risk alerts
        let hasCriticalAlerts = riskAlerts.contains(where: { $0.severity == .critical })
        
        if hasCriticalAlerts && !overrideRisk {
            showRiskWarning = true
            return
        }
        
        await performSave(overrideRisk: overrideRisk)
    }
    
    private func performSave(overrideRisk: Bool) async {
        guard !symbol.isEmpty, let p = Double(price), let q = Double(quantity), p > 0, q > 0 else {
            return
        }
        
        isSaving = true
        
        let newTrade = TradeRecord(
            symbol: symbol.uppercased(),
            type: type,
            price: p,
            quantity: q,
            assetType: assetType,
            emotion: emotion,
            note: note,
            date: tradeDate
        )
        
        do {
            try await appDependency?.repositories.trade.save(newTrade)
            
            // Log risk override if applicable
            if overrideRisk {
                Logger.log("Trade saved with risk override: \(type.rawValue) \(q) \(symbol) @ $\(p)", category: Logger.trading)
                
                // Record override decision
                let overrideNote = "Risk override: \(riskAlerts.map { $0.message }.joined(separator: ", "))"
                Logger.log(overrideNote, category: Logger.trading)
            } else {
                Logger.log("Trade logged: \(type.rawValue) \(q) \(symbol) @ $\(p)", category: Logger.general)
            }
            
            await MainActor.run {
                HapticsManager.shared.success()
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
            }
            ErrorHandler.shared.handle(error, context: "TradeLogForm.saveTrade")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    TradeLogForm()
}
