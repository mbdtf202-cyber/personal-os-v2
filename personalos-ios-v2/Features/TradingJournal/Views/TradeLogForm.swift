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

    enum TradeType: String, CaseIterable {
        case buy = "Buy"
        case sell = "Sell"
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Asset Details")) {
                    TextField("Symbol (e.g. AAPL)", text: $symbol)
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
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Log Trade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTrade() } // ⚠️ 调用保存
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
        }
    }

    private func saveTrade() {
        let p = Double(price) ?? 0.0
        let q = Double(quantity) ?? 0.0
        let newTrade = SchemaV1.TradeRecord(
            symbol: symbol.uppercased(),
            type: type.rawValue,
            price: p,
            quantity: q,
            note: note
        )
        modelContext.insert(newTrade) // ⚠️ 写入
        dismiss()
    }
}

#Preview {
    TradeLogForm()
}
