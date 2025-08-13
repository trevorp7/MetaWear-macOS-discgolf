import SwiftUI
import Combine
import CoreBluetooth

// MARK: - MetaWear SDK Integration
import MetaWear
import Foundation

struct ContentView: View {
    @StateObject private var metawearManager = MetaWearManager()
    @StateObject private var speedCalculator = SpeedCalculator()
    @State private var selectedTab = 0
    
    init() {
        // Debug initialization removed to reduce log spam
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Bluetooth Connection View
            ConnectionView(metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Connection")
                }
                .tag(0)
            
            // Motion Detection Test View
            MotionDetectionTestView(metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("Motion Test")
                }
                .tag(1)
            
            // High-Frequency Logger Test View
            HighFrequencyLoggerTestView(metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "record.circle")
                    Text("Logger Test")
                }
                .tag(2)
            
            // Integrated Throw Detector Test View
            IntegratedThrowDetectorTestView(metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Integrated Test")
                }
                .tag(3)
            
            // Speed Analysis View
            SpeedAnalysisView(metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Speed Analysis")
                }
                .tag(4)
            
            // Speed Tracking View
            SpeedTrackingView(speedCalculator: speedCalculator, metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("Speed")
                }
                .tag(5)
            
            // Motion Recording View
            MotionRecordingView(metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "waveform.path.ecg.rectangle")
                    Text("Motion Recording")
                }
                .tag(6)
            
            // Motion Playground View
            MotionPlaygroundView(metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "target")
                    Text("Motion Playground")
                }
                .tag(7)
        }
        .frame(minWidth: 600, minHeight: 700)
        .onAppear {
            print("🔵 ContentView appeared")
            print("🔵 Bluetooth state: \(metawearManager.bluetoothState)")
            print("🔵 Is connected: \(metawearManager.isConnected)")
        }
        .onChange(of: metawearManager.isConnected) { isConnected in
            if !isConnected {
                // Stop speed tracking when disconnected
                speedCalculator.stopSpeedTracking()
            }
        }
        .onChange(of: speedCalculator.isTracking) { isTracking in
            if !isTracking {
                // Refresh connection state when tracking stops
                metawearManager.refreshConnectionState()
            }
        }
    }
}

// MARK: - Connection View
struct ConnectionView: View {
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🍎 MetaWear Speed Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if metawearManager.isConnected {
                    ConnectedStateView(metawearManager: metawearManager)
                } else {
                    DisconnectedStateView(metawearManager: metawearManager)
                }
            }
            .padding()
        }
    }
}

// MARK: - Connected State View
struct ConnectedStateView: View {
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Status
            VStack(spacing: 10) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("✅ Connected to MetaWear")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device: \(metawearManager.deviceAddress)")
                    Text("Connection: Active")
                    Text("SDK Version: Loaded")
                }
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 10) {
                Text("Ready to track speed!")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    InfoRow(icon: "speedometer", text: "Switch to Speed tab to start tracking")
                    InfoRow(icon: "sensor.tag.radiowaves.forward", text: "Uses sensor fusion for accurate motion tracking")
                    InfoRow(icon: "baseball", text: "Track throws and analyze speed data")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            
            // Disconnect Button
            Button("Disconnect") {
                metawearManager.disconnect()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}

// MARK: - Disconnected State View
struct DisconnectedStateView: View {
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔗 Not Connected")
                .foregroundColor(.orange)
                .fontWeight(.semibold)
            
            // Bluetooth State Display
            HStack {
                Text("📶 Bluetooth:")
                Text(metawearManager.bluetoothState)
                    .foregroundColor(metawearManager.bluetoothState == "On" ? .green : .red)
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 5)
            
            // Device Address Input
            VStack(spacing: 10) {
                Text("Enter Device MAC Address:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Device MAC Address", text: $metawearManager.deviceAddress)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .font(.system(.body, design: .monospaced))
            }
            
            // Discovered Devices Display
            if !metawearManager.discoveredDevices.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("🔍 Discovered Devices:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(metawearManager.discoveredDevices, id: \.self) { device in
                        Text(device)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: 500)
            }
            
            // Connect Button
            Button("Connect") {
                Task {
                    await metawearManager.connect()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(metawearManager.deviceAddress.isEmpty)
            
            // Info Section
            VStack(alignment: .leading, spacing: 10) {
                Text("How to use:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    InfoRow(icon: "antenna.radiowaves.left.and.right", text: "Connect to your MetaWear device")
                    InfoRow(icon: "speedometer", text: "Switch to Speed tab to start tracking")
                    InfoRow(icon: "sensor.tag.radiowaves.forward", text: "Uses sensor fusion for accurate motion tracking")
                    InfoRow(icon: "baseball", text: "Track throws and analyze speed data")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Speed Display Card
struct SpeedDisplayCard: View {
    @ObservedObject var speedCalculator: SpeedCalculator
    let metawear: MetaWear?
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Speed
            VStack(spacing: 10) {
                Text(speedCalculator.formattedSpeed)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(speedCalculator.isTracking ? .primary : .secondary)
                    .animation(.easeInOut(duration: 0.3), value: speedCalculator.currentSpeed)
                
                Text("Current Speed")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Status Indicator
            HStack {
                Circle()
                    .fill(speedCalculator.isTracking ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(speedCalculator.detailedStatus)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - MetaWear Manager
class MetaWearManager: ObservableObject {
    @Published var isConnected = false
    @Published var deviceAddress = "CF:3C:F4:38:61:9E"
    @Published var bluetoothState: String = "Unknown"
    @Published var discoveredDevices: [String] = []
    
    init() {
        print("🔵 MetaWearManager initialized")
        print("🔵 Device address: \(deviceAddress)")
        print("🔵 MetaWear SDK available: true")
        
        // Check Bluetooth status on initialization
        BluetoothHelper.checkBluetoothStatus()
    }
    
    @Published var metawear: MetaWear?
    private var scanner: MetaWearScanner?
    private var cancellables = Set<AnyCancellable>()
    
    func connect() async {
        print("🔵 Connect function called")
        guard !deviceAddress.isEmpty else { 
            print("❌ Device address is empty")
            return 
        }
        
        print("🔵 Setting up scanner...")
        scanner = MetaWearScanner.sharedRestore
        
        // Wait for Bluetooth to be ready
        _ = await scanner!.bluetoothState.values.first { state in
            
            await MainActor.run {
                let stateDescription = self.getBluetoothStateDescription(state)
                self.bluetoothState = stateDescription
                print("🔵 Bluetooth state changed to: \(stateDescription)")
            }
            
            // Only proceed when Bluetooth is powered on
            return state == .poweredOn
        }
        
        scanner?.startScan(higherPerformanceMode: true)
        
        do {
            // Set up device discovery using async/await
            let metawear: MetaWear = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<MetaWear, Error>) in
                var cancellable: AnyCancellable?
                var hasResumed = false
                
                // Helper function to safely resume continuation only once
                let safeResume: (Result<MetaWear, Error>) -> Void = { result in
                    guard !hasResumed else { return }
                    hasResumed = true
                    cancellable?.cancel()
                    
                    switch result {
                    case .success(let device):
                        continuation.resume(returning: device)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                cancellable = scanner!.discoveredDevicesPublisher
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                let error = NSError(domain: "MetaWear", code: 1, userInfo: [NSLocalizedDescriptionKey: "Device discovery timeout"])
                                safeResume(.failure(error))
                            case .failure(let error):
                                safeResume(.failure(error))
                            }
                        },
                        receiveValue: { [weak self] devices in
                            guard let self = self else { return }
                            
                            // Capture deviceAddress locally to avoid concurrency issues
                            let targetAddress = self.deviceAddress
                            
                            // Debug: Print all discovered devices
                            print("🔍 Discovered \(devices.count) devices:")
                            var deviceList: [String] = []
                            
                            for (id, device) in devices {
                                let deviceInfo = "ID: \(id), Name: \(device.peripheral.name ?? "Unknown"), MAC: \(device.info.mac)"
                                print("  - \(deviceInfo)")
                                print("    Peripheral: \(device.peripheral)")
                                print("    RSSI: \(device.rssi)")
                                deviceList.append(deviceInfo)
                            }
                            
                            // Create a local copy to avoid concurrency issues
                            let finalDeviceList = deviceList
                            DispatchQueue.main.async {
                                self.discoveredDevices = finalDeviceList
                            }
                            
                            // Try multiple matching strategies
                            if let foundDevice = devices.values.first(where: { metawear in
                                // Strategy 1: Exact MAC address match
                                metawear.info.mac.lowercased() == targetAddress.lowercased() ||
                                // Strategy 2: Partial MAC address match
                                metawear.info.mac.lowercased().contains(targetAddress.lowercased()) ||
                                // Strategy 3: Device name contains the address
                                metawear.peripheral.name?.lowercased().contains(targetAddress.lowercased()) == true ||
                                // Strategy 4: Any MetaWear device if no specific match
                                metawear.peripheral.name?.lowercased().contains("metawear") == true
                            }) {
                                print("✅ Found matching device: \(foundDevice.peripheral.name ?? "Unknown")")
                                safeResume(.success(foundDevice))
                            } else {
                                print("❌ No matching device found for address: \(targetAddress)")
                            }
                        }
                    )
                
                // Set a longer timeout for device discovery
                DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                    let timeoutError = NSError(domain: "MetaWear", code: 2, userInfo: [NSLocalizedDescriptionKey: "Device discovery timeout"])
                    safeResume(.failure(timeoutError))
                }
            }
            
            print("✅ Found MetaWear device: \(metawear.peripheral.name ?? "Unknown")")
            
            // Stop scanning since we found our device
            scanner?.stopScan()
            print("🛑 Stopped scanning after finding device")
            
            // Connect to the device using the simple connect method
            print("🔌 Attempting to connect to device...")
            
            // Use the simple connect method that was working before
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                var hasResumed = false
                
                let safeResume: (Result<Void, Error>) -> Void = { result in
                    guard !hasResumed else { return }
                    hasResumed = true
                    
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                // Use the simple connect method
                print("🔌 Calling metawear.connect()...")
                metawear.connect()
                
                // Wait a moment for connection to establish
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    print("📱 Checking connection status...")
                    let state = metawear.peripheral.state
                    print("📱 Device state after connect: \(state.rawValue)")
                    
                    if state == .connected {
                        print("✅ Device is connected!")
                        safeResume(.success(()))
                    } else {
                        print("⚠️ Device not yet connected, waiting...")
                        // Wait a bit more
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            let finalState = metawear.peripheral.state
                            print("📱 Final device state: \(finalState.rawValue)")
                            
                            if finalState == .connected {
                                print("✅ Device is now connected!")
                                safeResume(.success(()))
                            } else {
                                print("❌ Device still not connected")
                                let timeoutError = NSError(domain: "MetaWear", code: 3, userInfo: [NSLocalizedDescriptionKey: "Connection timeout - device state: \(finalState.rawValue)"])
                                safeResume(.failure(timeoutError))
                            }
                        }
                    }
                }
                
                // Set a timeout for connection
                DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                    let timeoutError = NSError(domain: "MetaWear", code: 3, userInfo: [NSLocalizedDescriptionKey: "Connection timeout"])
                    safeResume(.failure(timeoutError))
                }
            }
            
            await MainActor.run {
                self.metawear = metawear
            }
            
            // Wait for device to be fully ready
            print("⏳ Waiting for device to be fully ready...")
            try await Task.sleep(for: .seconds(2))
            
            // Check device state after waiting
            let deviceState = metawear.peripheral.state
            print("📱 Final device state: \(deviceState.rawValue)")
            
            guard deviceState == .connected else {
                throw NSError(domain: "MetaWear", code: 4, userInfo: [NSLocalizedDescriptionKey: "Device not fully connected. State: \(deviceState.rawValue)"])
            }
            
            await MainActor.run {
                self.isConnected = true
            }
            
            print("✅ Connected to MetaWear device: \(deviceAddress)")
            print("📱 Device is ready for speed tracking")
            
        } catch {
            print("❌ Device discovery or connection failed: \(error)")
            
            // Stop scanning on error
            scanner?.stopScan()
            
            await MainActor.run {
                self.isConnected = false
                // Provide more specific error information
                if let nsError = error as NSError? {
                    switch nsError.code {
                    case 1:
                        print("❌ Device discovery timeout - no devices found")
                    case 2:
                        print("❌ Device discovery timeout - scanning took too long")
                    case 3:
                        print("❌ Connection timeout - device found but connection failed")
                    case 4:
                        print("❌ Device not fully connected - state issue")
                    default:
                        print("❌ Connection error: \(nsError.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func disconnect() {
        // Disconnect the MetaWear device
        metawear?.disconnect()
        
        // Stop scanning
        scanner?.stopScan()
        
        // Clear the metawear reference
        metawear = nil
        
        // Clear cancellables
        cancellables.removeAll()
        
        DispatchQueue.main.async {
            self.isConnected = false
            // Clear discovered devices list
            self.discoveredDevices.removeAll()
        }
        
        print("🔌 Disconnected from MetaWear")
    }
    
    /// Refresh connection state - useful after stopping tracking
    func refreshConnectionState() {
        guard let device = metawear else {
            DispatchQueue.main.async {
                self.isConnected = false
            }
            return
        }
        
        let currentState = device.peripheral.state
        DispatchQueue.main.async {
            self.isConnected = (currentState == .connected)
            print("🔄 Refreshed connection state: \(currentState.rawValue) -> \(self.isConnected)")
        }
    }
    
    private func getBluetoothStateDescription(_ state: CBManagerState) -> String {
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



// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
