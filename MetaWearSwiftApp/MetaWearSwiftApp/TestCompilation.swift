import Foundation
import CoreBluetooth

// Test file to verify compilation fixes
class TestCompilation {
    
    static func testBluetoothStateDescription() {
        let state = CBManagerState.poweredOn
        let description = getBluetoothStateDescription(state)
        print("Bluetooth state description: \(description)")
    }
    
    private static func getBluetoothStateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOn:
            return "On"
        case .poweredOff:
            return "Off"
        case .unauthorized:
            return "Unauthorized"
        case .unsupported:
            return "Unsupported"
        case .resetting:
            return "Resetting"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
}

// Run test
// Commented out for compilation
// #if DEBUG
// TestCompilation.testBluetoothStateDescription()
// #endif 