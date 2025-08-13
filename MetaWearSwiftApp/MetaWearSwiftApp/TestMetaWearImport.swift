import Foundation
import SwiftUI

// Test if MetaWear SDK can be imported
#if canImport(MetaWear)
import MetaWear

// Test basic MetaWear functionality
class MetaWearTest {
    static func testSDK() {
        print("✅ MetaWear SDK is available!")
        
        // Test if we can create basic types
        let sampleRate = MWAccelerometer.SampleFrequency.hz100
        let gravityRange = MWAccelerometer.GravityRange.g8
        
        print("✅ Sample rate: \(sampleRate.label)")
        print("✅ Gravity range: \(gravityRange.label)")
        
        // Test if we can create an accelerometer configuration
        let _ = MWAccelerometer(rate: sampleRate, gravity: gravityRange)
        print("✅ Accelerometer configuration created successfully")
    }
}
#else
class MetaWearTest {
    static func testSDK() {
        print("❌ MetaWear SDK is NOT available")
        print("This means the package dependency is not properly linked to your target")
    }
}
#endif

// Simple test view
struct TestView: View {
    var body: some View {
        VStack {
            Text("MetaWear SDK Test")
                .font(.headline)
            
            Button("Test SDK") {
                MetaWearTest.testSDK()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
} 