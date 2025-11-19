import SwiftUI
import Observation

struct TradeLogForm: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: PortfolioViewModel
    @State private var symbol: String = ""
    @State private var type: TradeType = .buy
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var emotion: TradeEmotion = .neutral
    @State private var assetType: AssetType = .stock
    @State private var note: String = ""

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

                    Picker("Asset Type", selection: $assetType) {
                        ForEach(AssetType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: type.icon).tag(type)
                        }
                    }
                }

                Section(header: Text("Psychology & Notes")) {
                    Picker("Emotion State", selection: $emotion) {
                        ForEach(TradeEmotion.allCases, id: \.self) { emo in
                            Text(emo.rawValue)
                                .foregroundStyle(emo.color)
                                .tag(emo)
                        }
                    }
                    TextEditor(text: $note)
                        .frame(height: 100)
                        .overlay(
                            Text("Strategy reasoning...")
                                .foregroundStyle(.gray.opacity(0.5))
                                .padding(8)
                                .opacity(note.isEmpty ? 1 : 0),
                            alignment: .topLeading
                        )
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
        }
    }

    private func saveTrade() {
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSymbol.isEmpty,
              let priceValue = Double(price),
              let quantityValue = Double(quantity) else { return }

        viewModel.addTrade(symbol: trimmedSymbol,
                          type: type,
                          price: priceValue,
                          quantity: quantityValue,
                          emotion: emotion,
                          note: note,
                          assetType: assetType)
        dismiss()
    }
}

#Preview {
    TradeLogForm(viewModel: PortfolioViewModel())
}
