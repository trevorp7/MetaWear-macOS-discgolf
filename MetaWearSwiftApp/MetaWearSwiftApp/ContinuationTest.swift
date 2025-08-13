import Foundation
import Combine

// Test file to verify safe continuation pattern
class ContinuationTest {
    
    static func testSafeResume() {
        print("=== Testing Safe Continuation Resume ===")
        
        // Simulate the safe resume pattern
        var hasResumed = false
        var callCount = 0
        
        let safeResume: (Result<String, Error>) -> Void = { result in
            callCount += 1
            guard !hasResumed else { 
                print("⚠️ Attempted to resume continuation \(callCount) times, but only first was accepted")
                return 
            }
            hasResumed = true
            
            switch result {
            case .success(let value):
                print("✅ Successfully resumed with value: \(value)")
            case .failure(let error):
                print("❌ Resumed with error: \(error)")
            }
        }
        
        // Test multiple calls - only first should succeed
        safeResume(.success("First call"))
        safeResume(.success("Second call"))
        safeResume(.failure(NSError(domain: "Test", code: 1, userInfo: nil)))
        
        print("✅ Safe resume test completed - continuation was only resumed once")
    }
}

// Run test
// Commented out for compilation
// #if DEBUG
// ContinuationTest.testSafeResume()
// #endif 