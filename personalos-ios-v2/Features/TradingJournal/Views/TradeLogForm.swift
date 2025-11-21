import SwiftUI
import SwiftData

struct TradeLogForm: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext // ⚠️ 数据库上下文

    @State private var symbol: String = ""
    @State private var type: TradeType = .buy
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var note: String = ""
    @State private var assetType: AssetType = .stock
    @State private var emotion: TradeEmotion = .neutral
    @State private var tradeDate: Date = Date()

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
            }
            .navigationTitle("Log Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTrade() }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
    }

    private func saveTrade() {
        guard !symbol.isEmpty, let p = Double(price), let q = Double(quantity), p > 0, q > 0 else {
            return
        }
        
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
        Task {
            do {
                try await appDependency!.repositories.trade.save(newTrade)
                HapticsManager.shared.success()
                Logger.log("Trade logged: \(type.rawValue) \(q) \(symbol) @ $\(p)", category: Logger.general)
            } catch {
                ErrorHandler.shared.handle(error, context: "TradeLogForm.logTrade")
            }
        }
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    TradeLogForm()
}
