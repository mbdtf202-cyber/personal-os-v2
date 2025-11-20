import SwiftUI
import Observation

@Observable
class BaseViewModel {
    var errorMessage: String?
    var isError: Bool = false
    
    func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
        self.isError = true
    }
    
    func clearError() {
        self.errorMessage = nil
        self.isError = false
    }
}
