import SwiftUI

enum UnitCategory: String, CaseIterable {
    case length = "Length"
    case weight = "Weight"
    case temperature = "Temperature"
    case volume = "Volume"
    
    var units: [String] {
        switch self {
        case .length: return ["Meters", "Kilometers", "Miles", "Feet", "Inches"]
        case .weight: return ["Kilograms", "Grams", "Pounds", "Ounces"]
        case .temperature: return ["Celsius", "Fahrenheit", "Kelvin"]
        case .volume: return ["Liters", "Milliliters", "Gallons", "Cups"]
        }
    }
    
    var icon: String {
        switch self {
        case .length: return "ruler"
        case .weight: return "scalemass"
        case .temperature: return "thermometer"
        case .volume: return "drop"
        }
    }
}

struct UnitConverterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var category: UnitCategory = .length
    @State private var inputValue: String = ""
    @State private var fromUnit: String = "Meters"
    @State private var toUnit: String = "Kilometers"
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Category Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(UnitCategory.allCases, id: \.self) { cat in
                                    Button {
                                        category = cat
                                        fromUnit = cat.units[0]
                                        toUnit = cat.units[1]
                                        HapticsManager.shared.light()
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: cat.icon)
                                                .font(.title2)
                                            Text(cat.rawValue)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundStyle(category == cat ? .white : AppTheme.primaryText)
                                        .frame(width: 80, height: 80)
                                        .background(category == cat ? AppTheme.mistBlue : Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: AppTheme.shadow, radius: 4, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("From")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            
                            HStack {
                                TextField("Enter value", text: $inputValue)
                                    .keyboardType(.decimalPad)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Picker("", selection: $fromUnit) {
                                    ForEach(category.units, id: \.self) { unit in
                                        Text(unit).tag(unit)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .glassCard()
                        
                        // Swap Button
                        Button {
                            swap(fromUnit, toUnit)
                            HapticsManager.shared.medium()
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.title2)
                                .foregroundStyle(AppTheme.mistBlue)
                                .frame(width: 50, height: 50)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: AppTheme.shadow, radius: 4, y: 2)
                        }
                        
                        // Output
                        VStack(alignment: .leading, spacing: 12) {
                            Text("To")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            
                            HStack {
                                Text(convertedValue)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.primaryText)
                                
                                Spacer()
                                
                                Picker("", selection: $toUnit) {
                                    ForEach(category.units, id: \.self) { unit in
                                        Text(unit).tag(unit)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding()
                            .background(AppTheme.mistBlue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .glassCard()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Unit Converter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var convertedValue: String {
        guard let value = Double(inputValue) else { return "0" }
        let result = convert(value, from: fromUnit, to: toUnit, category: category)
        return String(format: "%.2f", result)
    }
    
    private func swap(_ from: String, _ to: String) {
        let temp = fromUnit
        fromUnit = toUnit
        toUnit = temp
    }
    
    private func convert(_ value: Double, from: String, to: String, category: UnitCategory) -> Double {
        // Simplified conversion - in production, use proper unit conversion
        switch category {
        case .length:
            let meters = convertToMeters(value, from: from)
            return convertFromMeters(meters, to: to)
        case .weight:
            let kg = convertToKg(value, from: from)
            return convertFromKg(kg, to: to)
        case .temperature:
            return convertTemperature(value, from: from, to: to)
        case .volume:
            let liters = convertToLiters(value, from: from)
            return convertFromLiters(liters, to: to)
        }
    }
    
    private func convertToMeters(_ value: Double, from: String) -> Double {
        switch from {
        case "Meters": return value
        case "Kilometers": return value * 1000
        case "Miles": return value * 1609.34
        case "Feet": return value * 0.3048
        case "Inches": return value * 0.0254
        default: return value
        }
    }
    
    private func convertFromMeters(_ value: Double, to: String) -> Double {
        switch to {
        case "Meters": return value
        case "Kilometers": return value / 1000
        case "Miles": return value / 1609.34
        case "Feet": return value / 0.3048
        case "Inches": return value / 0.0254
        default: return value
        }
    }
    
    private func convertToKg(_ value: Double, from: String) -> Double {
        switch from {
        case "Kilograms": return value
        case "Grams": return value / 1000
        case "Pounds": return value * 0.453592
        case "Ounces": return value * 0.0283495
        default: return value
        }
    }
    
    private func convertFromKg(_ value: Double, to: String) -> Double {
        switch to {
        case "Kilograms": return value
        case "Grams": return value * 1000
        case "Pounds": return value / 0.453592
        case "Ounces": return value / 0.0283495
        default: return value
        }
    }
    
    private func convertTemperature(_ value: Double, from: String, to: String) -> Double {
        if from == to { return value }
        
        // Convert to Celsius first
        var celsius: Double
        switch from {
        case "Celsius": celsius = value
        case "Fahrenheit": celsius = (value - 32) * 5/9
        case "Kelvin": celsius = value - 273.15
        default: celsius = value
        }
        
        // Convert from Celsius to target
        switch to {
        case "Celsius": return celsius
        case "Fahrenheit": return celsius * 9/5 + 32
        case "Kelvin": return celsius + 273.15
        default: return celsius
        }
    }
    
    private func convertToLiters(_ value: Double, from: String) -> Double {
        switch from {
        case "Liters": return value
        case "Milliliters": return value / 1000
        case "Gallons": return value * 3.78541
        case "Cups": return value * 0.236588
        default: return value
        }
    }
    
    private func convertFromLiters(_ value: Double, to: String) -> Double {
        switch to {
        case "Liters": return value
        case "Milliliters": return value * 1000
        case "Gallons": return value / 3.78541
        case "Cups": return value / 0.236588
        default: return value
        }
    }
}

#Preview {
    UnitConverterView()
}
