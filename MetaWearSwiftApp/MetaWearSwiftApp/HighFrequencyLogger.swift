import Foundation
import Combine
import MetaWear
import MetaWearCpp

/// High-frequency data logger for detailed throw analysis
/// Records 800Hz+ sensor data during motion detection
class HighFrequencyLogger: ObservableObject {
    // MARK: - Published Properties
    @Published var isLogging = false
    @Published var logStatus = "Ready"
    @Published var logDuration: TimeInterval = 0.0
    @Published var logFileCount = 0
    @Published var lastLogFile: String = ""
    
    // Timer for real-time duration updates
    private var durationTimer: Timer?
    
    // MARK: - Private Properties
    private var metawear: MetaWear?
    private var cancellables = Set<AnyCancellable>()
    private var logStartTime: Date?
    private var logData: [LogEntry] = []
    
    // Data processing options
    private var useAveraging = true
    private var useThresholdFiltering = true
    private var useLowPassFilter = true
    
    // Processing parameters (using SDK patterns)
    private let speedThreshold: Float = 0.5   // 0.5 g threshold for significant motion
    
    // MARK: - Log Entry Structure
    struct LogEntry: Codable {
        let timestamp: Date
        let linearAcceleration: SIMD3<Float>  // g's
        let eulerAngles: SIMD3<Float>         // pitch, roll, yaw in degrees
        let accelerationMagnitude: Float      // g's
        let speed: Float                      // mph (calculated from acceleration)
        let motionIntensity: Float            // motion intensity level
        let isSignificantMotion: Bool
        let orientation: String               // device orientation
        
        // Custom coding keys to handle SIMD3<Float> serialization
        enum CodingKeys: String, CodingKey {
            case timestamp
            case linearAccelerationX, linearAccelerationY, linearAccelerationZ
            case eulerAnglesX, eulerAnglesY, eulerAnglesZ
            case accelerationMagnitude
            case speed
            case motionIntensity
            case isSignificantMotion
            case orientation
        }
        
        init(timestamp: Date, linearAcceleration: SIMD3<Float>, eulerAngles: SIMD3<Float>, accelerationMagnitude: Float, speed: Float, motionIntensity: Float, isSignificantMotion: Bool, orientation: String) {
            self.timestamp = timestamp
            self.linearAcceleration = linearAcceleration
            self.eulerAngles = eulerAngles
            self.accelerationMagnitude = accelerationMagnitude
            self.speed = speed
            self.motionIntensity = motionIntensity
            self.isSignificantMotion = isSignificantMotion
            self.orientation = orientation
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
            
            let accelX = try container.decode(Float.self, forKey: .linearAccelerationX)
            let accelY = try container.decode(Float.self, forKey: .linearAccelerationY)
            let accelZ = try container.decode(Float.self, forKey: .linearAccelerationZ)
            linearAcceleration = SIMD3<Float>(accelX, accelY, accelZ)
            
            let eulerX = try container.decode(Float.self, forKey: .eulerAnglesX)
            let eulerY = try container.decode(Float.self, forKey: .eulerAnglesY)
            let eulerZ = try container.decode(Float.self, forKey: .eulerAnglesZ)
            eulerAngles = SIMD3<Float>(eulerX, eulerY, eulerZ)
            
            accelerationMagnitude = try container.decode(Float.self, forKey: .accelerationMagnitude)
            speed = try container.decode(Float.self, forKey: .speed)
            motionIntensity = try container.decode(Float.self, forKey: .motionIntensity)
            isSignificantMotion = try container.decode(Bool.self, forKey: .isSignificantMotion)
            orientation = try container.decode(String.self, forKey: .orientation)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encode(linearAcceleration.x, forKey: .linearAccelerationX)
            try container.encode(linearAcceleration.y, forKey: .linearAccelerationY)
            try container.encode(linearAcceleration.z, forKey: .linearAccelerationZ)
            try container.encode(eulerAngles.x, forKey: .eulerAnglesX)
            try container.encode(eulerAngles.y, forKey: .eulerAnglesY)
            try container.encode(eulerAngles.z, forKey: .eulerAnglesZ)
            try container.encode(accelerationMagnitude, forKey: .accelerationMagnitude)
            try container.encode(speed, forKey: .speed)
            try container.encode(motionIntensity, forKey: .motionIntensity)
            try container.encode(isSignificantMotion, forKey: .isSignificantMotion)
            try container.encode(orientation, forKey: .orientation)
        }
    }
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Public Methods
    
    /// Start high-frequency logging
    func startLogging(device: MetaWear) -> Bool {
        guard !isLogging else {
            print("⚠️ Already logging")
            return false
        }
        
        self.metawear = device
        self.isLogging = true
        self.logStartTime = Date()
        self.logData.removeAll()
        
        // Reset speed calculation state for new session
        velocity = SIMD3<Float>(0, 0, 0)
        lastTimestamp = nil
        isMoving = false
        
        // Generate unique log file name
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        self.lastLogFile = "throw_log_\(dateFormatter.string(from: Date())).json"
        
        self.logStatus = "High-frequency logging active"
        print("🚀 Started high-frequency logging: \(lastLogFile)")
        print("🔌 Device state at start: \(device.peripheral.state.rawValue)")
        print("📊 Using SDK sensor fusion: LinearAcceleration + EulerAngles, Threshold(\(speedThreshold)g)")
        
        // Note: Device should already be connected by the calling system
        // Don't call device.connect() here to avoid conflicts
        
        // Start duration timer for real-time updates
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            if let startTime = self?.logStartTime {
                self?.logDuration = Date().timeIntervalSince(startTime)
            }
            
            // Check device connection status
            if let device = self?.metawear {
                if device.peripheral.state != .connected {
                    print("⚠️ Device disconnected during logging: \(device.peripheral.state.rawValue)")
                }
            }
        }
        
        // Configure sensors with data processing
        setupProcessedSensors(device: device)
        
        return true
    }
    
    /// Stop logging and return log file path
    func stopLogging() {
        guard isLogging else {
            print("⚠️ Not currently logging")
            return
        }
        
        // Stop data collection
        cancellables.removeAll()
        
        // Stop duration timer
        durationTimer?.invalidate()
        durationTimer = nil
        
        // Calculate final duration
        if let startTime = logStartTime {
            logDuration = Date().timeIntervalSince(startTime)
        }
        
        self.isLogging = false
        self.logStatus = "Processing log data..."
        
        print("📊 Logging stopped. Collected \(logData.count) samples")
        if let device = metawear {
            print("🔌 Device state at stop: \(device.peripheral.state.rawValue)")
        }
        
        // Save log data to file
        saveLogData()
    }
    
    /// Get current logging statistics
    var loggingStats: String {
        if isLogging {
            let duration = Date().timeIntervalSince(logStartTime ?? Date())
            let sampleCount = logData.count
            let sampleRate = sampleCount > 0 ? Double(sampleCount) / duration : 0
            
            return String(format: "Duration: %.1fs | Samples: %d | Rate: %.0f Hz", 
                         duration, sampleCount, sampleRate)
        } else {
            return "Not logging"
        }
    }
    
    // MARK: - Private Methods
    
    private func setupProcessedSensors(device: MetaWear) {
        // Use sensor fusion for accurate motion analysis
        let linearAccel = MWSensorFusion.LinearAcceleration(mode: .ndof)
        let eulerAngles = MWSensorFusion.EulerAngles(mode: .ndof)
        
        // Raw linear acceleration for basic motion detection
        device
            .publish()
            .stream(linearAccel)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("📊 Linear acceleration logging completed")
                    case .failure(let error):
                        print("❌ Linear acceleration error: \(error)")
                        print("🔌 Device state: \(device.peripheral.state.rawValue)")
                    }
                },
                receiveValue: { [weak self] data in
                    self?.processLinearAcceleration(data)
                }
            )
            .store(in: &cancellables)
        

        
        // Euler angles for orientation analysis
        device
            .publish()
            .stream(eulerAngles)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("🔄 Euler angles logging completed")
                    case .failure(let error):
                        print("❌ Euler angles error: \(error)")
                        print("🔌 Device state: \(device.peripheral.state.rawValue)")
                    }
                },
                receiveValue: { [weak self] data in
                    self?.processEulerAngles(data)
                }
            )
            .store(in: &cancellables)
    }
    

    
    // MARK: - Motion Analysis Methods (using SDK patterns)
    
    // Velocity integration for speed calculation (using improved method from SpeedCalculator)
    private var velocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    private var lastTimestamp: Date?
    private var isMoving: Bool = false
    private var movementThreshold: Float = 0.05 // g's - minimum acceleration to consider movement
    
    private func calculateAccelerationMagnitude(_ acceleration: SIMD3<Float>) -> Float {
        // Calculate magnitude using RMS (Root Mean Square) as per SDK reference
        return sqrt(acceleration.x * acceleration.x + 
                   acceleration.y * acceleration.y + 
                   acceleration.z * acceleration.z)
    }
    
    private func calculateSpeed(_ acceleration: SIMD3<Float>, timestamp: Date) -> Float {
        // Using improved method from SpeedCalculator with movement detection
        let accelerationMS2 = acceleration * 9.81 // Convert g's to m/s²
        
        // Calculate time delta
        guard let lastTime = lastTimestamp else {
            lastTimestamp = timestamp
            return 0.0
        }
        
        let deltaTime = Float(timestamp.timeIntervalSince(lastTime))
        lastTimestamp = timestamp
        
        // Check if device is moving (above noise threshold)
        let accelerationMagnitude = sqrt(acceleration.x * acceleration.x + 
                                       acceleration.y * acceleration.y + 
                                       acceleration.z * acceleration.z)
        
        if accelerationMagnitude > movementThreshold {
            isMoving = true
        } else if isMoving && accelerationMagnitude < movementThreshold * 0.5 {
            // Stop tracking if acceleration drops significantly
            isMoving = false
            velocity = SIMD3<Float>(0, 0, 0)
        }
        
        // Integrate acceleration to get velocity (only when moving)
        if isMoving {
            velocity += accelerationMS2 * deltaTime
            
            // Apply simple low-pass filter to reduce noise
            let filterAlpha: Float = 0.1
            velocity = velocity * (1 - filterAlpha) + accelerationMS2 * deltaTime * filterAlpha
        } else {
            // Reset velocity when not moving
            velocity = SIMD3<Float>(0, 0, 0)
        }
        
        // Calculate speed magnitude
        let speedMS = sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z)
        
        // Convert to mph (m/s * 2.237)
        let speedMPH = speedMS * 2.237
        
        return speedMPH
    }
    
    private func determineOrientation(_ eulerAngles: SIMD3<Float>) -> String {
        let (pitch, roll, _) = (eulerAngles.x, eulerAngles.y, eulerAngles.z)
        
        // Determine orientation based on pitch and roll
        if abs(pitch) < 30 && abs(roll) < 30 {
            return "level"
        } else if pitch > 45 {
            return "tilted_forward"
        } else if pitch < -45 {
            return "tilted_backward"
        } else if roll > 45 {
            return "tilted_right"
        } else if roll < -45 {
            return "tilted_left"
        } else {
            return "other"
        }
    }
    
    private func isSignificantMotion(_ magnitude: Float) -> Bool {
        // Use threshold detection as per SDK reference
        return magnitude > speedThreshold
    }
    
    private func processLinearAcceleration(_ data: Timestamped<MWSensorFusion.LinearAcceleration.DataType>) {
        guard isLogging else { return }
        
        let timestamp = data.time
        let linearAccel = data.value
        
        // Calculate acceleration magnitude using SDK pattern
        let accelerationMagnitude = calculateAccelerationMagnitude(linearAccel)
        
        // Calculate speed using velocity integration (following Motion Reference)
        let speed = calculateSpeed(linearAccel, timestamp: timestamp)
        
        // Check for significant motion using threshold detection
        let isSignificantMotion = isSignificantMotion(accelerationMagnitude)
        
        // Create log entry (euler angles will be updated by processEulerAngles)
        let entry = LogEntry(
            timestamp: timestamp,
            linearAcceleration: linearAccel,
            eulerAngles: SIMD3<Float>(0, 0, 0), // Will be updated by euler angles
            accelerationMagnitude: accelerationMagnitude,
            speed: speed,
            motionIntensity: accelerationMagnitude, // Use magnitude as intensity
            isSignificantMotion: isSignificantMotion,
            orientation: "unknown" // Will be updated by euler angles
        )
        
        logData.append(entry)
        
        // Update status
        self.logStatus = "Logging... \(logData.count) samples"
        
        // Debug: Print first few samples to confirm data flow
        if logData.count <= 5 {
            print("📊 Logger received linear accel: \(linearAccel) (magnitude: \(accelerationMagnitude)g, speed: \(String(format: "%.2f", speed)) mph) at \(timestamp)")
        }
        
        // Log significant motion events
        if isSignificantMotion {
            print("🎯 SDK detected significant motion: \(accelerationMagnitude)g at \(timestamp)")
        }
    }
    

    
    private func processEulerAngles(_ data: Timestamped<MWSensorFusion.EulerAngles.DataType>) {
        guard isLogging else { return }
        
        let timestamp = data.time
        let eulerAngles = data.value
        
        // Determine orientation using SDK pattern
        let orientation = determineOrientation(eulerAngles)
        
        // Update the most recent log entry with euler angles data
        if var lastEntry = logData.last {
            lastEntry = LogEntry(
                timestamp: lastEntry.timestamp,
                linearAcceleration: lastEntry.linearAcceleration,
                eulerAngles: eulerAngles,
                accelerationMagnitude: lastEntry.accelerationMagnitude,
                speed: lastEntry.speed,
                motionIntensity: lastEntry.motionIntensity,
                isSignificantMotion: lastEntry.isSignificantMotion,
                orientation: orientation
            )
            logData[logData.count - 1] = lastEntry
        }
        
        // Debug: Print first few samples to confirm data flow
        if logData.count <= 5 {
            print("🔄 Logger received euler angles: \(eulerAngles) (orientation: \(orientation)) at \(timestamp)")
        }
    }
    
    private func saveLogData() {
        guard !logData.isEmpty else {
            print("⚠️ No log data to save")
            self.logStatus = "No data collected"
            return
        }
        
        // Calculate statistics using SDK patterns
        let significantMotionCount = logData.filter { $0.isSignificantMotion }.count
        
        let accelerations = logData.map { $0.accelerationMagnitude }
        let speeds = logData.map { $0.speed }
        _ = logData.map { $0.motionIntensity }
        
        let maxAcceleration = accelerations.max() ?? 0.0
        let avgAcceleration = accelerations.isEmpty ? 0.0 : accelerations.reduce(0, +) / Float(accelerations.count)
        let maxSpeed = speeds.max() ?? 0.0
        let avgSpeed = speeds.isEmpty ? 0.0 : speeds.reduce(0, +) / Float(speeds.count)

        
        let logInfo = LogFileInfo(
            fileName: lastLogFile,
            startTime: logStartTime ?? Date(),
            duration: logDuration,
            sampleCount: logData.count,
            maxSpeed: maxSpeed,
            avgSpeed: avgSpeed,
            maxSpin: maxAcceleration,
            avgSpin: avgAcceleration,
            significantMotionCount: significantMotionCount,
            significantSpinCount: 0 // No longer tracking spin separately
        )
        
        // Create log file structure
        struct LogFile: Codable {
            let info: LogFileInfo
            let data: [LogEntry]
        }
        
        let logFile = LogFile(info: logInfo, data: logData)
        
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let logsDirectory = documentsPath.appendingPathComponent("MetaWearLogs")
            
            // Create logs directory if it doesn't exist
            try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
            
            let fileURL = logsDirectory.appendingPathComponent(lastLogFile)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(logFile)
            try jsonData.write(to: fileURL)
            
            print("✅ Logging stopped. Duration: \(String(format: "%.1f", logDuration))s")
            print("📁 Log file: \(fileURL.path)")
            print("📊 Statistics: Max Speed: \(String(format: "%.2f", maxSpeed)) mph, Avg: \(String(format: "%.2f", avgSpeed)) mph")
            print("📊 Statistics: Max Acceleration: \(String(format: "%.2f", maxAcceleration))g, Avg: \(String(format: "%.2f", avgAcceleration))g")
            print("🎯 Significant events: Motion: \(significantMotionCount)")
            
            self.logStatus = "Log saved: \(lastLogFile)"
            self.logFileCount += 1
            
        } catch {
            print("❌ Failed to save log file: \(error)")
            self.logStatus = "Failed to save log"
        }
    }
    
    // MARK: - Log File Info Structure
    struct LogFileInfo: Codable {
        let fileName: String
        let startTime: Date
        let duration: TimeInterval
        let sampleCount: Int
        let maxSpeed: Float
        let avgSpeed: Float
        let maxSpin: Float
        let avgSpin: Float
        let significantMotionCount: Int
        let significantSpinCount: Int
    }
    
    // MARK: - Utility Methods
    
    /// Get list of available log files
    func getAvailableLogFiles() -> [String] {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logsDirectory = documentsPath.appendingPathComponent("MetaWearLogs")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil)
            return files.map { $0.lastPathComponent }.filter { $0.hasSuffix(".json") }
        } catch {
            print("❌ Failed to get log files: \(error)")
            return []
        }
    }
    
    /// Load log file data
    func loadLogFile(_ fileName: String) -> LogFileInfo? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logFilePath = documentsPath.appendingPathComponent("MetaWearLogs").appendingPathComponent(fileName)
        
        do {
            let jsonData = try Data(contentsOf: logFilePath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Parse the new log file structure
            struct LogFile: Codable {
                let info: LogFileInfo
                let data: [LogEntry]
            }
            
            let logFile = try decoder.decode(LogFile.self, from: jsonData)
            return logFile.info
            
        } catch {
            print("❌ Failed to load log file: \(error)")
            return nil
        }
    }
} 

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let logFileName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
} 