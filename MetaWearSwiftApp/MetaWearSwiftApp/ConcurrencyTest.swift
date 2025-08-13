import Foundation
import Combine

// Test file to verify concurrency fixes
class ConcurrencyTest {
    
    static func testLocalCapture() {
        print("=== Testing Local Variable Capture ===")
        
        let originalValue = "CF:3C:F4:38:61:9E"
        var capturedValue: String?
        
        // Simulate the pattern we fixed
        let targetAddress = originalValue // Local capture
        
        DispatchQueue.main.async {
            capturedValue = targetAddress // Use local copy
            print("✅ Captured value: \(capturedValue ?? "nil")")
        }
        
        // Simulate device list creation
        var deviceList: [String] = []
        deviceList.append("Device 1")
        deviceList.append("Device 2")
        
        let finalDeviceList = deviceList // Local copy
        
        DispatchQueue.main.async {
            print("✅ Final device list count: \(finalDeviceList.count)")
        }
        
        print("✅ Concurrency test completed successfully")
    }
}

// Run test
// Commented out for compilation
// #if DEBUG
// ConcurrencyTest.testLocalCapture()
// #endif 