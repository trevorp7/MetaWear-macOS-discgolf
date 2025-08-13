import Foundation
import CoreBluetooth

// Bluetooth Helper for MetaWear App
class BluetoothHelper: NSObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager?
    private var completion: ((CBManagerState) -> Void)?
    
    static let shared = BluetoothHelper()
    
    override init() {
        super.init()
    }
    
    func checkBluetoothStatus(completion: @escaping (CBManagerState) -> Void) {
        self.completion = completion
        print("=== Bluetooth Status Check ===")
        
        // Initialize with delegate to get proper state updates
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // If state is already known, call completion immediately
        if let state = centralManager?.state, state != .unknown {
            completion(state)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("🔵 Bluetooth state updated: \(central.state)")
        completion?(central.state)
    }
    
    static func checkBluetoothStatus() {
        shared.checkBluetoothStatus { state in
            print("Bluetooth State: \(state)")
            print("Bluetooth State Raw Value: \(state.rawValue)")
            
            switch state {
            case .poweredOn:
                print("✅ Bluetooth is powered on and ready")
            case .poweredOff:
                print("❌ Bluetooth is powered off")
                print("💡 Solution: Enable Bluetooth in System Preferences > Bluetooth")
            case .unauthorized:
                print("❌ Bluetooth access is unauthorized")
                print("💡 Solution: Grant Bluetooth permission in System Preferences > Security & Privacy > Privacy > Bluetooth")
            case .unsupported:
                print("❌ Bluetooth is not supported on this device")
            case .resetting:
                print("⚠️ Bluetooth is resetting, please wait...")
            case .unknown:
                print("❓ Bluetooth state is unknown")
            @unknown default:
                print("❓ Unknown Bluetooth state")
            }
        }
        
        print("\n=== Troubleshooting Steps ===")
        print("1. Open System Preferences")
        print("2. Click on 'Bluetooth'")
        print("3. Make sure Bluetooth is turned ON")
        print("4. If prompted, allow the app to use Bluetooth")
        print("5. Restart the MetaWear app")
        
        print("\n=== Permission Check ===")
        print("If you see 'Unauthorized' above:")
        print("1. Open System Preferences")
        print("2. Click on 'Security & Privacy'")
        print("3. Click on 'Privacy' tab")
        print("4. Select 'Bluetooth' from the left sidebar")
        print("5. Make sure your app is checked")
        print("6. If not, click the '+' button and add your app")
    }
    
    static func getBluetoothStateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .poweredOn:
            return "On - Ready to use"
        case .poweredOff:
            return "Off - Enable in System Preferences"
        case .unauthorized:
            return "Unauthorized - Grant permission"
        case .unsupported:
            return "Unsupported on this device"
        case .resetting:
            return "Resetting - Please wait"
        case .unknown:
            return "Unknown state"
        @unknown default:
            return "Unknown state"
        }
    }
}

// Run the check if this file is executed directly
// Commented out for compilation
// #if DEBUG
// if CommandLine.arguments.contains("--check-bluetooth") {
//     BluetoothHelper.checkBluetoothStatus()
// }
// #endif 