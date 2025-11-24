import Foundation
import SwiftData

@globalActor
actor DataActor {
    static let shared = DataActor()
    
    private init() {}
}

extension ModelContext {
    @DataActor
    func performSafe<T>(_ block: @DataActor () throws -> T) rethrows -> T {
        return try block()
    }
}
