import SwiftUI

struct TradeLogForm: View {
    @Environment(\.dismiss) var dismiss
    @State private var symbol: String = ""
    @State private var type: TradeType = .buy
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var emotion: TradeEmotion = .neutral
    @State private var note: String = ""
    
    enum TradeType: String, CaseIterable {
        case buy = "Buy"
        case sell = "Sell"
    }
    
    enum TradeEmotion: String, CaseIterable {
        case excited = "Excited"
        case fearful = "Fearful"
        case neutral = "Neutral"
        case revenge = "Revenge"
        
        var color: Color {
            switch self {
            case .excited: return .orange
            case .fearful: return .purple
            case .neutral: return .blue
            case .revenge: return .red
            }
        }
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
                    Button("Save") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
        }
    }
}

#Preview {
    TradeLogForm()
}
