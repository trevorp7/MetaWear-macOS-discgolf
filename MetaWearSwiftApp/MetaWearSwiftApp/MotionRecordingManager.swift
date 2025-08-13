import SwiftUI
import Combine
import Foundation
import MetaWear
import MetaWearCpp
import simd

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Motion Recording Data Models
struct MotionRecordingData {
    let accelerometer: [Timestamped<SIMD3<Float>>]        // Linear acceleration (gravity removed)
    let gyroscope: [Timestamped<SIMD3<Float>>]
    let magnetometer: [Timestamped<SIMD3<Float>>]
    let speed: [Timestamped<Float>]                        // Calculated speed from integration
    let velocity: [Timestamped<SIMD3<Float>>]              // Velocity vector (vx, vy, vz) in m/s
    let recordingDuration: TimeInterval
    let recordingStartTime: Date
    
    var totalSamples: Int {
        accelerometer.count + gyroscope.count + magnetometer.count + speed.count
    }
    
    var averageSampleRates: SampleRates {
        SampleRates(
            accelerometer: recordingDuration > 0 ? Double(accelerometer.count) / recordingDuration : 0,
            gyroscope: recordingDuration > 0 ? Double(gyroscope.count) / recordingDuration : 0,
            magnetometer: recordingDuration > 0 ? Double(magnetometer.count) / recordingDuration : 0,
            speed: recordingDuration > 0 ? Double(speed.count) / recordingDuration : 0
        )
    }
    
    var peakAcceleration: Float {
        accelerometer.map { data in
            let x = data.value.x
            let y = data.value.y
            let z = data.value.z
            return sqrt(x*x + y*y + z*z)
        }.max() ?? 0.0
    }
    
    var peakAngularVelocity: Float {
        gyroscope.map { data in
            let x = data.value.x
            let y = data.value.y
            let z = data.value.z
            return sqrt(x*x + y*y + z*z)
        }.max() ?? 0.0
    }
    
    var peakSpeed: Float {
        speed.map { $0.value }.max() ?? 0.0
    }
}

struct SampleRates {
    let accelerometer: Double
    let gyroscope: Double
    let magnetometer: Double
    let speed: Double
}

// MARK: - Recording States
enum RecordingState {
    case idle
    case preparing
    case recording
    case stopping
    case downloading
    case completed
    case error(String)
    
    var isRecording: Bool {
        switch self {
        case .recording:
            return true
        default:
            return false
        }
    }
    
    var canStart: Bool {
        switch self {
        case .idle, .completed, .error:
            return true
        default:
            return false
        }
    }
    
    var canStop: Bool {
        switch self {
        case .recording:
            return true
        default:
            return false
        }
    }
    
    var canDownload: Bool {
        switch self {
        case .completed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Motion Recording Manager
class MotionRecordingManager: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var recordingDuration: TimeInterval = 0
    @Published var downloadedData: MotionRecordingData?
    @Published var lastError: String?
    @Published var downloadProgress: Double = 0.0
    @Published var autoStopDuration: TimeInterval = 30.0 // Default 30 seconds
    @Published var useAutoStop: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private weak var metawearManager: MetaWearManager?
    private var sensorsStarted = 0
    private var setupTimeoutTimer: Timer?
    
    // MetaWear sensor fusion for proper speed calculation
    private var sensorFusionData: [Timestamped<SensorFusionData>] = []
    
    // Simplified sensor fusion data structure
    struct SensorFusionData {
        let linearAcceleration: SIMD3<Float>  // Gravity-removed acceleration
    }
    
    init() {
        print("🎯 MotionRecordingManager initialized")
    }
    
    // MARK: - Setup
    func configure(with metawearManager: MetaWearManager) {
        self.metawearManager = metawearManager
    }
    
    // MARK: - Recording Controls
    func startRecording() {
        guard let metawearManager = metawearManager,
              let device = metawearManager.metawear,
              metawearManager.isConnected,
              recordingState.canStart else {
            setError("Device not connected or invalid state")
            return
        }
        
        // Additional safety check for device state
        guard device.peripheral.state == .connected else {
            setError("Device connection lost before starting recording")
            return
        }
        
        print("🎯 Starting high-frequency motion recording...")
        print("🔌 Device state: \(device.peripheral.state.rawValue)")
        recordingState = .preparing
        lastError = nil
        recordingDuration = 0
        downloadedData = nil
        
        // Cancel any existing operations first
        cancellables.removeAll()
        
        // Clear any existing logs first
        clearExistingLogs(device: device) { [weak self] in
            // Double-check connection before proceeding
            guard device.peripheral.state == .connected else {
                self?.setError("Device disconnected during setup")
                return
            }
            
            // Add a small delay to ensure device is fully ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard device.peripheral.state == .connected else {
                    self?.setError("Device disconnected during setup delay")
                    return
                }
                self?.startSensorLogging(device: device)
            }
        }
    }
    
    func stopRecording() {
        guard recordingState.canStop else { return }
        
        print("🎯 Stopping motion recording...")
        recordingState = .stopping
        
        // Stop the timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // MetaWear sensor fusion logging stops with device logging
        
        // Stop logging on device
        guard let metawearManager = metawearManager,
              let device = metawearManager.metawear else {
            setError("Device connection lost")
            return
        }
        
        stopSensorLogging(device: device)
    }
    
    func downloadData() {
        guard recordingState.canDownload,
              let metawearManager = metawearManager,
              let device = metawearManager.metawear else {
            setError("Cannot download - device not ready")
            return
        }
        
        print("🎯 Starting data download...")
        recordingState = .downloading
        downloadProgress = 0.0
        
        downloadLoggedData(device: device)
    }
    
    func resetRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        setupTimeoutTimer?.invalidate()
        setupTimeoutTimer = nil
        recordingStartTime = nil
        recordingDuration = 0
        downloadedData = nil
        lastError = nil
        downloadProgress = 0.0
        recordingState = .idle
        sensorsStarted = 0
        sensorFusionData.removeAll()
        print("🎯 Recording reset to idle state")
    }
    
    // MARK: - Private Implementation
    private func clearExistingLogs(device: MetaWear, completion: @escaping () -> Void) {
        print("🧹 Using C++ clear_entries function to clear all existing logs...")
        
        // Use the C++ function directly since .clearLogs() doesn't exist
        device.bleQueue.async {
            mbl_mw_logging_clear_entries(device.board)
            print("✅ All existing logs cleared using C++ clear_entries function!")
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func startSensorLogging(device: MetaWear) {
        print("🎯 Starting sensor logging with board validation...")
        print("🔍 Device info:")
        print("   - Peripheral state: \(device.peripheral.state.rawValue)")
        print("   - Peripheral name: \(device.peripheral.name ?? "nil")")
        print("   - Board pointer valid: \(device.board != nil)")
        
        // Clear any existing subscriptions
        cancellables.removeAll()
        print("✅ Cleared existing cancellables")
        
        // First, let's try to read device information to verify the board is responsive
        print("🔍 Testing board responsiveness by reading device info...")
        
        device.publish()
            .read(.deviceInformation)
            .timeout(.seconds(5), scheduler: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        print("✅ Device info read successfully - board is responsive")
                        // Now try logging
                        self?.attemptLogging(device: device)
                    case .failure(let error):
                        print("❌ Device info read failed: \(error)")
                        print("❌ Board may not be ready for operations")
                        self?.setError("Device not ready: \(error.localizedDescription)")
                    }
                },
                receiveValue: { deviceInfo in
                    print("📊 Device info: \(deviceInfo)")
                }
            )
            .store(in: &cancellables)
        
        // Set timeout for the entire process
        setupTimeoutTimer?.invalidate()
        setupTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            print("⏰ Overall setup timeout after 15 seconds")
            self?.setError("Setup timeout - device not responding")
        }
    }
    
    private func attemptLogging(device: MetaWear) {
        print("🚀 Board is responsive, clearing device state first...")
        
        // First, PROPERLY clear all logs and reset device
        print("🔥 Step 1: Stopping any existing loggers...")
        
        device.publish()
            .loggersPause()
            .flatMap { metawear -> AnyPublisher<MetaWear, MWError> in
                print("🔥 Step 2: Resetting all device activities...")
                return metawear.publish().command(.resetActivities)
            }
            .flatMap { metawear -> AnyPublisher<MetaWear, MWError> in
                print("🔥 Step 3: Power cycling sensors...")
                return metawear.publish().command(.powerDownSensors)
            }
            .delay(for: 3, scheduler: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        print("✅ Device completely cleared and reset!")
                        self?.startFreshLogging(device: device)
                    case .failure(let error):
                        print("❌ Device reset failed: \(error)")
                        self?.setError("Device reset failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { metawear in
                    print("🔥 Device cleared and reset successfully")
                }
            )
            .store(in: &cancellables)
    }
    
    private func startFreshLogging(device: MetaWear) {
        print("🚀 Starting fresh logging after device reset...")
        
        // Use MetaWear sensor fusion for proper speed calculation
        let linearAcceleration = MWSensorFusion.LinearAcceleration(mode: .ndof)  // Gravity-removed acceleration (~100 Hz)
        let gyroscope = MWGyroscope(rate: .hz100, range: .dps1000)               // Gyroscope at 100Hz
        let magnetometer = MWMagnetometer(freq: .hz25)                           // Magnetometer at 25Hz
        
        print("📊 Sensor configuration (METAWEAR SENSOR FUSION):")
        print("   - Linear Acceleration: NDOF (gravity removed)")
        print("   - Speed: Calculated from linear acceleration with simplified integration")
        print("   - Gyroscope: 100Hz, ±1000°/s range") 
        print("   - Magnetometer: 25Hz")
        
        sensorsStarted = 0
        let totalSensors = 3 // Linear acceleration, gyroscope, magnetometer
        
        // Start sensor fusion logging for proper speed calculation
        print("📊 Starting sensor fusion logging...")
        
        // Log linear acceleration (gravity-removed)
        device.publish()
            .log(linearAcceleration)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("❌ Linear acceleration logging failed: \(error)")
                        self?.setError("Linear acceleration logging failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    guard device.peripheral.state == .connected else {
                        self.setError("Device disconnected during sensor fusion setup")
                        return
                    }
                    
                    print("📊 Linear acceleration logging started")
                    self.sensorsStarted += 1
                    print("🔄 Sensors started: \(self.sensorsStarted)/\(totalSensors)")
                    if self.sensorsStarted == totalSensors {
                        self.beginRecordingSession()
                    }
                }
            )
            .store(in: &cancellables)

        // (Raw accelerometer disabled to avoid conflicts with sensor fusion logging)
        
        // Start gyroscope logging - EXACT working pattern
        device.publish()
            .log(gyroscope)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("❌ Gyroscope logging failed: \(error)")
                        self?.setError("Gyroscope logging failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    guard device.peripheral.state == .connected else {
                        self.setError("Device disconnected during gyroscope setup")
                        return
                    }
                    
                    print("🔄 Gyroscope logging started")
                    self.sensorsStarted += 1
                    print("🔄 Sensors started: \(self.sensorsStarted)/\(totalSensors)")
                    if self.sensorsStarted == totalSensors {
                        self.beginRecordingSession()
                    }
                }
            )
            .store(in: &cancellables)
        
        // Start magnetometer logging - EXACT working pattern
        device.publish()
            .log(magnetometer)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        print("❌ Magnetometer logging failed: \(error)")
                        self?.setError("Magnetometer logging failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    guard device.peripheral.state == .connected else {
                        self.setError("Device disconnected during magnetometer setup")
                        return
                    }
                    
                    print("🧲 Magnetometer logging started")
                    self.sensorsStarted += 1
                    print("🔄 Sensors started: \(self.sensorsStarted)/\(totalSensors)")
                    if self.sensorsStarted == totalSensors {
                        self.beginRecordingSession()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func beginRecordingSession() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel timeout timer since setup completed successfully
            self.setupTimeoutTimer?.invalidate()
            self.setupTimeoutTimer = nil
            
            print("🎯 All sensors configured - beginning recording session")
            self.recordingState = .recording
            self.recordingStartTime = Date()
            
            // MetaWear sensor fusion is already logging - ready for speed calculation
            
            // Start recording timer
            self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingDuration = Date().timeIntervalSince(startTime)
                
                // Check for auto-stop
                if self.useAutoStop && self.recordingDuration >= self.autoStopDuration {
                    print("⏰ Auto-stop triggered at \(String(format: "%.1f", self.recordingDuration))s")
                    self.stopRecording()
                }
            }
        }
    }
    
    private func stopSensorLogging(device: MetaWear) {
        print("🛑 Stopping sensor logging...")
        print("🛑 Device state before stop: \(device.peripheral.state.rawValue)")
        
        device.publish()
            .loggersPause()
            .sink(
                receiveCompletion: { [weak self] result in
                    print("🛑 Stop logging completion: \(result)")
                    switch result {
                    case .finished:
                        DispatchQueue.main.async {
                            print("⏹️ Sensor logging stopped successfully")
                            self?.recordingState = .completed
                        }
                    case .failure(let error):
                        print("❌ Failed to stop logging: \(error)")
                        self?.setError("Failed to stop logging: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in 
                    print("🛑 Stop logging command executed")
                }
            )
            .store(in: &cancellables)
    }
    
    private func downloadLoggedData(device: MetaWear) {
        // Safety check before starting download
        guard device.peripheral.state == .connected else {
            setError("Device disconnected during download attempt")
            return
        }
        
        let startDate = recordingStartTime ?? Date()
        print("📥 Starting download with start date: \(startDate)")
        
        device.publish()
            .downloadLogs(startDate: startDate)
            .sink(
                receiveCompletion: { [weak self] result in
                    switch result {
                    case .finished:
                        print("📥 Download completed successfully")
                    case .failure(let error):
                        print("❌ Download failed: \(error)")
                        print("🔌 Device state during error: \(device.peripheral.state.rawValue)")
                        self?.setError("Download failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] downloadData in
                    let (dataTables, progress) = downloadData
                    print("📥 Download progress: \(String(format: "%.1f", progress * 100))% - \(dataTables.count) tables")
                    DispatchQueue.main.async {
                        self?.downloadProgress = progress
                        if progress >= 1.0 {
                            print("📥 Download completed with \(dataTables.count) data tables")
                            self?.processDownloadedData(dataTables)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func processDownloadedData(_ dataTables: [MWDataTable]) {
        print("🔄 Processing \(dataTables.count) downloaded data tables...")
        
        var accelerometerData: [Timestamped<SIMD3<Float>>] = []      // Linear acceleration
        var gyroscopeData: [Timestamped<SIMD3<Float>>] = []
        var magnetometerData: [Timestamped<SIMD3<Float>>] = []
        var speedData: [Timestamped<Float>] = []                     // Calculated speed
        var velocityData: [Timestamped<SIMD3<Float>>] = []            // Velocity components
        
        // Build sensor fusion data from downloaded logs
        var sensorFusionData: [Timestamped<SensorFusionData>] = []
        var linearAccelByTime: [Date: SIMD3<Float>] = [:]
        
        var totalRowsProcessed = 0
        var totalRowsSkipped = 0
        
        for table in dataTables {
            print("📊 Processing table for signal: \(table.source)")
            print("   - Header: \(table.headerRow)")
            print("   - Rows: \(table.rows.count)")
            
            // Show first few rows for debugging
            if table.rows.count > 0 {
                print("   - Sample first row: \(table.rows[0])")
                if table.rows.count > 1 {
                    print("   - Sample second row: \(table.rows[1])")
                }
            }
            
            // Parse CSV data rows into timestamped sensor data
            for row in table.rows {
                totalRowsProcessed += 1
                
                // Parse timestamp (column 0: Epoch) 
                guard let timestamp = Double(row[0]) else { 
                    totalRowsSkipped += 1
                    print("⚠️ Invalid timestamp: \(row[0])")
                    continue 
                }
                let date = Date(timeIntervalSince1970: timestamp)
                
                // Determine if this is vector (XYZ) or scalar data based on signal type
                switch table.source {
                case .acceleration:
                    // Vector data - need X, Y, Z columns
                    guard row.count >= 6 else { 
                        totalRowsSkipped += 1
                        print("⚠️ Skipping acceleration row with insufficient columns: \(row.count) < 6")
                        continue 
                    }
                    guard let x = Float(row[3]), let y = Float(row[4]), let z = Float(row[5]) else { 
                        totalRowsSkipped += 1
                        print("⚠️ Invalid acceleration components: [\(row[3]), \(row[4]), \(row[5])]")
                        continue 
                    }
                    let vector = SIMD3<Float>(x, y, z)
                    let timestampedData = Timestamped(time: date, value: vector)
                    accelerometerData.append(timestampedData)
                case .linearAcceleration:
                    // Vector data - need X, Y, Z columns
                    guard row.count >= 6 else { 
                        totalRowsSkipped += 1
                        print("⚠️ Skipping linear acceleration row with insufficient columns: \(row.count) < 6")
                        continue 
                    }
                    guard let x = Float(row[3]), let y = Float(row[4]), let z = Float(row[5]) else { 
                        totalRowsSkipped += 1
                        print("⚠️ Invalid linear acceleration components: [\(row[3]), \(row[4]), \(row[5])]")
                        continue 
                    }
                    let vector = SIMD3<Float>(x, y, z)
                    let timestampedData = Timestamped(time: date, value: vector)
                    accelerometerData.append(timestampedData)
                    linearAccelByTime[date] = vector
                case .gyroscope:
                    // Vector data - need X, Y, Z columns
                    guard row.count >= 6 else { 
                        totalRowsSkipped += 1
                        print("⚠️ Skipping gyroscope row with insufficient columns: \(row.count) < 6")
                        continue 
                    }
                    guard let x = Float(row[3]), let y = Float(row[4]), let z = Float(row[5]) else { 
                        totalRowsSkipped += 1
                        print("⚠️ Invalid gyroscope components: [\(row[3]), \(row[4]), \(row[5])]")
                        continue 
                    }
                    let vector = SIMD3<Float>(x, y, z)
                    let timestampedData = Timestamped(time: date, value: vector)
                    gyroscopeData.append(timestampedData)
                case .magnetometer:
                    // Vector data - need X, Y, Z columns  
                    guard row.count >= 6 else { 
                        totalRowsSkipped += 1
                        print("⚠️ Skipping magnetometer row with insufficient columns: \(row.count) < 6")
                        continue 
                    }
                    guard let x = Float(row[3]), let y = Float(row[4]), let z = Float(row[5]) else { 
                        totalRowsSkipped += 1
                        print("⚠️ Invalid magnetometer components: [\(row[3]), \(row[4]), \(row[5])]")
                        continue 
                    }
                    let vector = SIMD3<Float>(x, y, z)
                    let timestampedData = Timestamped(time: date, value: vector)
                    magnetometerData.append(timestampedData)
                case .quaternion:
                    print("⚠️ Quaternion data received but not used (simplified speed calculation)")
                case .eulerAngles:
                    print("⚠️ Euler angles data received but not used (simplified speed calculation)")
                default:
                    print("⚠️ Unknown signal type: \(table.source)")
                }
            }
        }
        
        print("📈 Data processing summary:")
        print("   - Total rows processed: \(totalRowsProcessed)")
        print("   - Rows skipped: \(totalRowsSkipped)")
        print("   - Success rate: \(String(format: "%.1f", Double(totalRowsProcessed - totalRowsSkipped) / Double(max(totalRowsProcessed, 1)) * 100))%")
        
        // Build sensor fusion data structure from collected data
        print("🔧 Building sensor fusion data structure...")
        let allTimestamps = linearAccelByTime.keys.sorted()
        
        for timestamp in allTimestamps {
            if let linearAccel = linearAccelByTime[timestamp] {
                let fusionData = SensorFusionData(
                    linearAcceleration: linearAccel
                )
                sensorFusionData.append(Timestamped(time: timestamp, value: fusionData))
            }
        }
        
        print("📊 Sensor fusion data built: \(sensorFusionData.count) complete samples")
        
        // Calculate speed from linear acceleration data (simplified integration)
        print("🚀 Calculating speed from linear acceleration data with simplified integration...")
        let speedAndVelocity = calculateSpeedFromSensorFusionData(sensorFusionData)
        speedData = speedAndVelocity.speed
        velocityData = speedAndVelocity.velocity
        
        let recordingData = MotionRecordingData(
            accelerometer: accelerometerData,        // Raw acceleration (gravity removed in processing)
            gyroscope: gyroscopeData,
            magnetometer: magnetometerData,
            speed: speedData,                         // Calculated speed from raw acceleration
            velocity: velocityData,                   // Velocity components
            recordingDuration: recordingDuration,
            recordingStartTime: recordingStartTime ?? Date()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.downloadedData = recordingData
            self?.downloadProgress = 1.0
            
            // Validate if we captured meaningful data
            let totalSamples = recordingData.totalSamples
            if totalSamples == 0 {
                self?.recordingState = .error("No sensor data captured. Try recording with device motion or check sensor configuration.")
                print("⚠️ No sensor data captured!")
                print("💡 Troubleshooting suggestions:")
                print("   - Ensure device was in motion during recording")
                print("   - Check that sensors are properly configured")
                print("   - Verify device connection stability")
                print("   - Try a longer recording duration")
            } else {
                self?.recordingState = .completed
                print("✅ Data processing completed:")
                print("   📊 Raw Accelerometer: \(accelerometerData.count) samples (gravity removed in processing)")
                print("   🔄 Gyroscope: \(gyroscopeData.count) samples")
                print("   🧲 Magnetometer: \(magnetometerData.count) samples")
                print("   🔄 Linear Acceleration: \(sensorFusionData.count) samples (for speed calculation)")
                print("   🚀 Speed: \(speedData.count) samples (calculated from linear acceleration)")
                print("   🧭 Velocity vectors: \(velocityData.count) samples (vx, vy, vz)")
                print("   ⏱️ Duration: \(String(format: "%.2f", recordingData.recordingDuration))s")
                
                if totalSamples > 0 {
                    print("   🚀 Peak acceleration: \(String(format: "%.2f", recordingData.peakAcceleration))g")
                    print("   🌪️ Peak angular velocity: \(String(format: "%.2f", recordingData.peakAngularVelocity))°/s")
                    print("   🏃 Peak speed: \(String(format: "%.2f", recordingData.peakSpeed)) m/s")
                }
            }
        }
    }
    
    
    private func calculateSpeedFromSensorFusionData(_ sensorFusionData: [Timestamped<SensorFusionData>]) -> (speed: [Timestamped<Float>], velocity: [Timestamped<SIMD3<Float>>]) {
        guard sensorFusionData.count > 1 else { return ([], []) }
        
        var speedData: [Timestamped<Float>] = []
        var velocityData: [Timestamped<SIMD3<Float>>] = []
        var lastTimestamp = sensorFusionData[0].time
        let seriesStartTime = sensorFusionData[0].time
        let warmupSkipSeconds: Float = 2.5
        
        // Integration and detection parameters (m/s²)
        let stationaryTimeThreshold: Float = 0.5 // seconds for ZUPT
        let velocityDecayTau: Float = 0.5       // seconds, time constant for velocity decay
        let gToMS2: Float = 9.80665             // convert g -> m/s²
        
        // State variables
        var velocity = SIMD3<Float>(0, 0, 0)
        var accelerationBias = SIMD3<Float>(0, 0, 0)
        var stationaryTimer: Float = 0.0
        var isCurrentlyMoving = false
        
        // Low-pass filter for acceleration
        var filteredAcceleration = SIMD3<Float>(0, 0, 0)
        let lowPassAlpha: Float = 0.1 // Filter coefficient

        // Motion detection via RMS with hysteresis
        // Estimate sample rate for window sizing
        let estimatedSampleRate = max(1.0, Double(sensorFusionData.count) / max(recordingDuration, 1.0))
        let rmsWindowSeconds: Double = 0.25 // 250 ms window
        let rmsWindowSamples = max(5, min(200, Int(estimatedSampleRate * rmsWindowSeconds)))
        var rmsQueue: [Float] = []
        var rmsSumSquares: Float = 0.0

        // Baseline noise (updated when stationary)
        var baselineRMS: Float = 0.0
        var baselineInitialized = false
        let baselineAlpha: Float = 0.05 // slow update when stationary

        // Hysteresis margins and debounce durations
        let startHysteresisMargin: Float = 0.25 // m/s² above baseline to start moving
        let stopHysteresisMargin: Float = 0.10  // m/s² above baseline to remain moving
        let startMinDuration: Float = 0.15      // seconds above start threshold to confirm start
        let stopMinDuration: Float = 0.30       // seconds below stop threshold to confirm stop
        var aboveStartTime: Float = 0.0
        var belowStopTime: Float = 0.0
        
        print("📊 Simplified speed calculation parameters (RMS-based detection):")
        print("   - Total linear acceleration samples: \(sensorFusionData.count)")
        print("   - Sample rate: ~\(String(format: "%.0f", estimatedSampleRate)) Hz")
        print("   - Warmup skip: \(String(format: "%.1f", warmupSkipSeconds)) s will be ignored")
        print("   - RMS window: \(rmsWindowSamples) samples (~\(String(format: "%.0f", rmsWindowSeconds*1000)) ms)")
        print("   - Start margin: +\(startHysteresisMargin) m/s², Stop margin: +\(stopHysteresisMargin) m/s²")
        print("   - Start debounce: \(startMinDuration)s, Stop debounce: \(stopMinDuration)s")
        print("   - ZUPT time threshold: \(stationaryTimeThreshold)s")
        print("   - Velocity decay tau: \(velocityDecayTau)s")
        
                for i in 0..<sensorFusionData.count {
            let currentData = sensorFusionData[i]
            let currentTimestamp = currentData.time
            
            // Calculate time delta with proper clamping
            let deltaTime = Float(currentTimestamp.timeIntervalSince(lastTimestamp))
            let clampedDeltaTime = max(0.002, min(0.1, deltaTime)) // Clamp to 2-100ms
            
            // Always advance timestamp even if we skip
            lastTimestamp = currentTimestamp
            
            // Skip if time delta is too small or invalid
            guard clampedDeltaTime > 0.001 && clampedDeltaTime < 1.0 else {
                print("⚠️ Skipping sample \(i) - invalid delta time: \(clampedDeltaTime)s")
                continue
            }
            
            // Warmup skip window: ignore first N seconds entirely to avoid sensor fusion settling
            let elapsedFromStart = Float(currentTimestamp.timeIntervalSince(seriesStartTime))
            if elapsedFromStart < warmupSkipSeconds {
                // Reset state during warmup so integration starts cleanly after skip
                velocity = .zero
                accelerationBias = .zero
                filteredAcceleration = .zero
                baselineRMS = 0
                baselineInitialized = false
                stationaryTimer = 0
                aboveStartTime = 0
                belowStopTime = 0
                continue
            }
            
            // Get linear acceleration in m/s² (sensor fusion is in g)
            let linearAcceleration = currentData.value.linearAcceleration * gToMS2
            
            // Use linear acceleration directly (already in device frame, gravity removed)
            let worldAcceleration = linearAcceleration
            
            // Apply low-pass filter to reduce noise
            filteredAcceleration = filteredAcceleration * (1.0 - lowPassAlpha) + worldAcceleration * lowPassAlpha
            
            // Calculate horizontal acceleration magnitude (ignore vertical)
            let horizontalAcceleration = SIMD2<Float>(filteredAcceleration.x, filteredAcceleration.y)
            let horizontalMagnitude = sqrt(horizontalAcceleration.x * horizontalAcceleration.x + horizontalAcceleration.y * horizontalAcceleration.y)

            // Update RMS window
            let sq = horizontalMagnitude * horizontalMagnitude
            rmsQueue.append(sq)
            rmsSumSquares += sq
            if rmsQueue.count > rmsWindowSamples {
                rmsSumSquares -= rmsQueue.removeFirst()
            }
            let rms: Float = sqrt(max(0.0, rmsSumSquares / Float(max(1, rmsQueue.count))))

            // Initialize/update baseline when stationary (or at start)
            if !baselineInitialized {
                baselineRMS = rms
                baselineInitialized = true
            }
            if !isCurrentlyMoving {
                baselineRMS = baselineRMS * (1.0 - baselineAlpha) + rms * baselineAlpha
            }

            // Dynamic thresholds with hysteresis
            let startThreshold = baselineRMS + startHysteresisMargin
            let stopThreshold  = baselineRMS + stopHysteresisMargin
            
            // Motion detection based on RMS with hysteresis and debounce
            if rms > startThreshold {
                aboveStartTime += clampedDeltaTime
                belowStopTime = 0.0
                if !isCurrentlyMoving && aboveStartTime >= startMinDuration {
                    isCurrentlyMoving = true
                    stationaryTimer = 0.0
                }
            } else if rms < stopThreshold {
                belowStopTime += clampedDeltaTime
                aboveStartTime = 0.0
                if isCurrentlyMoving && belowStopTime >= stopMinDuration {
                    isCurrentlyMoving = false
                }
            } else {
                // Between thresholds
                aboveStartTime = 0.0
                belowStopTime = 0.0
            }

            // ZUPT timer when under overall stationary threshold (close to baseline)
            if rms < stopThreshold {
                stationaryTimer += clampedDeltaTime
                if stationaryTimer > stationaryTimeThreshold {
                    // Zero-velocity update (ZUPT) and bias update
                    velocity = SIMD3<Float>(0, 0, 0)
                    accelerationBias = accelerationBias * 0.95 + filteredAcceleration * 0.05
                }
            } else {
                stationaryTimer = 0.0
            }
            
            var currentSpeed: Float = 0.0
            
            if isCurrentlyMoving {
                // Remove bias from acceleration
                let correctedAcceleration = filteredAcceleration - accelerationBias
                
                // Integrate acceleration to get velocity: v = v0 + a*dt
                velocity = velocity + correctedAcceleration * clampedDeltaTime
                
                // Apply time-based velocity decay (not per-sample)
                velocity = velocity * exp(-clampedDeltaTime / velocityDecayTau)
                
                // Calculate horizontal speed magnitude
                let horizontalVelocity = SIMD2<Float>(velocity.x, velocity.y)
                currentSpeed = sqrt(horizontalVelocity.x * horizontalVelocity.x + horizontalVelocity.y * horizontalVelocity.y)
            } else {
                // Device is stationary - speed should be zero
                currentSpeed = 0.0
                velocity = SIMD3<Float>(0, 0, 0)
            }
            
            let speedTimestamp = Timestamped(time: currentTimestamp, value: currentSpeed)
            speedData.append(speedTimestamp)
            let velocityTimestamp = Timestamped(time: currentTimestamp, value: velocity)
            velocityData.append(velocityTimestamp)
            
            // Debug output for first few samples
            if i < 10 {
                print("📊 Sample \(i): dt=\(String(format: "%.3f", clampedDeltaTime))s, horiz_rms=\(String(format: "%.2f", rms)) m/s², baseline=\(String(format: "%.2f", baselineRMS)) m/s², moving=\(isCurrentlyMoving), speed=\(String(format: "%.2f", currentSpeed)) m/s")
            }
            
            // Progress indicator for long recordings
            if i % 1000 == 0 && i > 0 {
                print("📊 Processed \(i)/\(sensorFusionData.count) samples (\(String(format: "%.1f", Double(i) / Double(sensorFusionData.count) * 100))%)")
            }
        }
        
        print("📊 Speed calculation completed:")
        print("   - Calculated \(speedData.count) speed samples")
        if let maxSpeed = speedData.map({ $0.value }).max() {
            print("   - Maximum speed: \(String(format: "%.2f", maxSpeed)) m/s (\(String(format: "%.1f", maxSpeed * 2.237)) mph)")
        }
        
        return (speed: speedData, velocity: velocityData)
    }
    
    // Helper function to convert quaternion to rotation matrix
    private func quaternionToRotationMatrix(_ quaternion: SIMD4<Float>) -> simd_float3x3 {
        let q = simd_quatf(ix: quaternion.x, iy: quaternion.y, iz: quaternion.z, r: quaternion.w)
        return simd_float3x3(q)
    }
    
    private func applySmoothingFilter(_ data: [Float], windowSize: Int) -> [Float] {
        guard data.count > windowSize else { return data }
        
        var smoothed: [Float] = []
        let halfWindow = windowSize / 2
        
        for i in 0..<data.count {
            let startIndex = max(0, i - halfWindow)
            let endIndex = min(data.count - 1, i + halfWindow)
            
            let sum = (startIndex...endIndex).reduce(0) { $0 + data[$1] }
            let average = sum / Float(endIndex - startIndex + 1)
            smoothed.append(average)
        }
        
        return smoothed
    }
    
    // MetaWear sensor fusion data is logged to device and downloaded later
    
    private func setError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.lastError = message
            self?.recordingState = .error(message)
            self?.recordingTimer?.invalidate()
            self?.recordingTimer = nil
            // MetaWear sensor fusion stops with device
        }
    }
    
    deinit {
        recordingTimer?.invalidate()
        setupTimeoutTimer?.invalidate()
        cancellables.forEach { $0.cancel() }
        // MetaWear sensor fusion stops with device
        print("🎯 MotionRecordingManager deinitialized")
    }
}
