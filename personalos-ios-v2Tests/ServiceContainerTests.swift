import XCTest
@testable import personalos_ios_v2

@MainActor
final class ServiceContainerTests: XCTestCase {
    var container: ServiceContainer!
    
    override func setUp() async throws {
        container = ServiceContainer()
    }
    
    override func tearDown() async throws {
        container.reset()
        container = nil
    }
    
    func testRegisterAndResolveService() {
        // Given
        container.register(HealthServiceProtocol.self) {
            MockHealthService()
        }
        
        // When
        let service = container.resolve(HealthServiceProtocol.self)
        
        // Then
        XCTAssertNotNil(service)
    }
    
    func testSingletonRegistration() {
        // Given
        let mockService = MockHealthService()
        container.registerSingleton(HealthServiceProtocol.self, instance: mockService)
        
        // When
        let service1 = container.resolve(HealthServiceProtocol.self)
        let service2 = container.resolve(HealthServiceProtocol.self)
        
        // Then
        XCTAssertTrue(service1 as AnyObject === service2 as AnyObject)
    }
    
    func testServiceFactoryConfiguration() {
        // Given
        ServiceFactory.shared.configure(environment: .mock)
        
        // When
        ServiceFactory.shared.setupServices(in: container)
        let healthService = container.resolve(HealthServiceProtocol.self)
        
        // Then
        XCTAssertTrue(healthService is MockHealthService)
    }
}
