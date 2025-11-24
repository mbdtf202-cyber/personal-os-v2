import Foundation

enum ConfigValidationError: Error, LocalizedError {
    case missingAPIKey(service: String)
    case invalidConfiguration(message: String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let service):
            return "Missing API key for \(service). Please configure in Settings."
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}

struct ConfigurationStatus {
    let isValid: Bool
    let missingKeys: [String]
    let warnings: [String]
    
    static let valid = ConfigurationStatus(isValid: true, missingKeys: [], warnings: [])
}

@MainActor
class ConfigurationValidator {
    static let shared = ConfigurationValidator()
    
    private init() {}
    
    func validate() -> ConfigurationStatus {
        var missingKeys: [String] = []
        var warnings: [String] = []
        
        // Check News API
        if !APIConfig.hasValidNewsAPIKey {
            missingKeys.append("News API")
            warnings.append("News features will use mock data")
        }
        
        // Check Stock API
        if !APIConfig.hasValidStockAPIKey {
            missingKeys.append("Stock API")
            warnings.append("Stock prices will use mock data")
        }
        
        // GitHub token is optional, no validation needed
        
        let isValid = missingKeys.isEmpty
        
        if !isValid {
            Logger.warning("Configuration incomplete: \(missingKeys.joined(separator: ", "))", category: Logger.general)
        }
        
        return ConfigurationStatus(
            isValid: isValid,
            missingKeys: missingKeys,
            warnings: warnings
        )
    }
    
    func validateOrThrow() throws {
        let status = validate()
        
        if !status.isValid {
            throw ConfigValidationError.invalidConfiguration(
                message: "Missing: \(status.missingKeys.joined(separator: ", "))"
            )
        }
    }
    
    func shouldShowConfigurationPrompt() -> Bool {
        let status = validate()
        return !status.missingKeys.isEmpty
    }
}
