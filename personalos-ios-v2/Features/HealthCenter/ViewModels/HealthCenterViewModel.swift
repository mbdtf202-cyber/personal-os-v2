import SwiftUI
import Observation

@Observable
@MainActor
class HealthCenterViewModel {
    var healthCheckIns: [HealthCheckIn] = []
    var isLoading: Bool = false
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        isLoading = false
    }
}
