import Foundation
import Combine
import simd
import MetaWear



/// Speed Calculator using MbientLab's recommended approach
/// Uses sensor fusion linear acceleration for gravity-compensated motion tracking
/// Now includes gyroscope-based spin rate tracking
class SpeedCalculator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentSpeed: Double = 0.0 // mph
    @Published var isTracking: Bool = false
    @Published var status: String = "Not started"
    @Published var maxSpeed: Double = 0.0 // Overall max speed
    @Published var maxSpeedDuringThrow: Double = 0.0 // Max speed during current throw
    
    // Spin tracking properties
    @Published var currentSpinRate: Double = 0.0 // RPM
    @Published var maxSpinRate: Double = 0.0 // Overall max RPM
    @Published var maxSpinRateDuringThrow: Double = 0.0 // Max RPM during current throw
    @Published var avgSpinRateDuringThrow: Double = 0.0 // Average RPM during current throw
    @Published var spinAxis: SIMD3<Float> = SIMD3<Float>(0, 0, 0) // Dominant rotation axis
    @Published var spinDataPointsDuringThrow: [SpinDataPoint] = [] // Detailed spin data during throw
    
    // MARK: - Private Properties
    private var metawear: MetaWear?
    private var cancellables = Set<AnyCancellable>()
    
    // Speed calculation state
    private var velocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    private var lastTimestamp: Date?
    private var isMoving: Bool = false
    private var movementThreshold: Float = 0.05 // g's - minimum acceleration to consider movement
    
    // Speed filtering and averaging
    private var speedHistory: [Double] = [] // Recent speed values for averaging
    private var speedFilterWindow: Int = 10 // Number of samples to average
    private var speedFilterAlpha: Float = 0.15 // Low-pass filter coefficient (0.1 = more smoothing, 0.3 = less smoothing)
    
    // Spin calculation state
    private var angularVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    private var lastSpinTimestamp: Date?
    private var spinHistory: [Double] = [] // Recent RPM values for averaging
    private var spinRatesDuringThrow: [Double] = [] // RPM values during current throw
    
    // Constants
    private let gToMps2: Float = 9.80665 // Convert g's to m/s²
    private let mpsToMph: Float = 2.23694 // Convert m/s to mph
    private let degreesToRPM: Float = 1.0 / 6.0 // Convert °/s to RPM (60/360)
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Public Methods
    
    /// Start speed tracking using MbientLab's sensor fusion approach
    func startSpeedTracking(device: MetaWear) {
        // Check if device is already connected
        guard device.peripheral.state == .connected else {
            self.status = "Device not connected. Please connect first."
            print("❌ Cannot start tracking - device not connected. State: \(device.peripheral.state.rawValue)")
            return
        }
        
        self.metawear = device
        self.isTracking = true
        self.status = "Connecting..."
        
        // Reset state
        velocity = SIMD3<Float>(0, 0, 0)
        lastTimestamp = nil
        isMoving = false
        angularVelocity = SIMD3<Float>(0, 0, 0)
        lastSpinTimestamp = nil
        spinHistory.removeAll()
        speedHistory.removeAll()
        self.spinDataPointsDuringThrow.removeAll()
        spinRatesDuringThrow.removeAll()
        
        // Connect to device and set up sensors
        device.connect()
        
        // Set up sensor fusion for linear acceleration
        let linearAccel = MWSensorFusion.LinearAcceleration(mode: .ndof)
        
        // Set up gyroscope for spin tracking
        let gyroscope = MWGyroscope(rate: .hz800, range: .dps2000) // High frequency, max range
        
        // Stream linear acceleration for speed
        device
            .publish()
            .stream(linearAccel)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] data in
                self?.processLinearAcceleration(data)
            })
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.status = "Streaming completed"
                    case .failure(let error):
                        self.status = "Error: \(error.localizedDescription)"
                    }
                },
                receiveValue: { _ in
                    // Data is processed in handleEvents
                }
            )
            .store(in: &cancellables)
        
        // Stream gyroscope for spin rate
        device
            .publish()
            .stream(gyroscope)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] data in
                self?.processAngularVelocity(data)
            })
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.status = "Spin tracking completed"
                    case .failure(let error):
                        self.status = "Spin error: \(error.localizedDescription)"
                    }
                },
                receiveValue: { _ in
                    // Data is processed in handleEvents
                }
            )
            .store(in: &cancellables)
        
        self.status = "Speed and spin tracking active"
    }
    
    /// Restart speed tracking (when device is already connected)
    func restartSpeedTracking() {
        guard let device = metawear else {
            self.status = "No device available"
            return
        }
        
        // Stop current tracking first
        stopSpeedTracking()
        
        // Wait a moment then restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startSpeedTracking(device: device)
        }
    }
    
    /// Stop speed tracking
    func stopSpeedTracking() {
        cancellables.removeAll()
        // Don't disconnect the device here - let MetaWearManager handle connection state
        // metawear?.disconnect() // Removed to prevent state mismatch
        isTracking = false
        status = "Stopped"
        
        // Reset speeds when stopping
        self.currentSpeed = 0.0
        self.currentSpinRate = 0.0
        
        // Note: MetaWearManager should refresh its connection state after this
        // This will be handled by the ContentView's onChange modifier
    }
    
    /// Reset speed calculation
    func resetSpeed() {
        velocity = SIMD3<Float>(0, 0, 0)
        lastTimestamp = nil
        isMoving = false
        
        self.currentSpeed = 0.0
        self.status = "Reset"
    }
    
    /// Reset max speed tracking
    func resetMaxSpeed() {
        self.maxSpeedDuringThrow = 0.0
        self.maxSpinRateDuringThrow = 0.0
        self.avgSpinRateDuringThrow = 0.0
        self.spinDataPointsDuringThrow = []
        spinRatesDuringThrow.removeAll()
    }
    
    /// Start tracking spin data for a new throw
    func startSpinTracking() {
        spinRatesDuringThrow.removeAll()
        self.spinDataPointsDuringThrow.removeAll()
        self.maxSpinRateDuringThrow = 0.0
        self.avgSpinRateDuringThrow = 0.0
    }
    
    /// Reset all speed tracking (including overall max)
    func resetAllSpeed() {
        velocity = SIMD3<Float>(0, 0, 0)
        lastTimestamp = nil
        isMoving = false
        angularVelocity = SIMD3<Float>(0, 0, 0)
        lastSpinTimestamp = nil
        spinHistory.removeAll()
        speedHistory.removeAll()
        self.spinDataPointsDuringThrow.removeAll()
        spinRatesDuringThrow.removeAll()
        
        self.currentSpeed = 0.0
        self.maxSpeed = 0.0
        self.maxSpeedDuringThrow = 0.0
        self.currentSpinRate = 0.0
        self.maxSpinRate = 0.0
        self.maxSpinRateDuringThrow = 0.0
        self.avgSpinRateDuringThrow = 0.0
        self.spinAxis = SIMD3<Float>(0, 0, 0)
        self.spinDataPointsDuringThrow = []
        self.status = "Reset"
    }
    
    // MARK: - Private Methods
    
    /// Process linear acceleration data from sensor fusion
    /// This is MbientLab's recommended approach for motion tracking
    private func processLinearAcceleration(_ data: Timestamped<SIMD3<Float>>) {
        let acceleration = data.value
        let timestamp = data.time
        
        print("📊 Received acceleration: \(acceleration) at \(timestamp)")
        
        // Convert from g's to m/s²
        let accelerationMps2 = acceleration * gToMps2
        
        // Calculate time delta
        guard let lastTime = lastTimestamp else {
            lastTimestamp = timestamp
            return
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
            // Simple Euler integration: v = v0 + a * dt
            velocity += accelerationMps2 * deltaTime
            
            // Apply simple low-pass filter to reduce noise
            let filterAlpha: Float = 0.1
            velocity = velocity * (1 - filterAlpha) + accelerationMps2 * deltaTime * filterAlpha
        } else {
            // Reset velocity when not moving
            velocity = SIMD3<Float>(0, 0, 0)
        }
        
        // Calculate speed magnitude
        let speedMps = sqrt(velocity.x * velocity.x + 
                           velocity.y * velocity.y + 
                           velocity.z * velocity.z)
        
        // Convert to mph
        let rawSpeedMph = Double(speedMps * mpsToMph)
        
        // Apply noise filtering and averaging for off-center sensor
        let filteredSpeedMph = applySpeedFiltering(rawSpeedMph)
        
        // Update UI (now on main thread due to .receive(on: DispatchQueue.main))
        self.currentSpeed = filteredSpeedMph
        
        // Update max speeds (use filtered speed for more accurate readings)
        if filteredSpeedMph > self.maxSpeed {
            self.maxSpeed = filteredSpeedMph
        }
        
        if filteredSpeedMph > self.maxSpeedDuringThrow {
            self.maxSpeedDuringThrow = filteredSpeedMph
        }
    }
    
    /// Process angular velocity data from gyroscope
    /// Converts degrees/second to RPM and tracks spin rate
    private func processAngularVelocity(_ data: Timestamped<SIMD3<Float>>) {
        let angularVel = data.value
        let timestamp = data.time
        
        print("🔄 Received angular velocity: \(angularVel) at \(timestamp)")
        
        // Check if we have a previous timestamp
        guard lastSpinTimestamp != nil else {
            lastSpinTimestamp = timestamp
            return
        }
        
        lastSpinTimestamp = timestamp
        
        // Apply low-pass filter to reduce noise
        let filterAlpha: Float = 0.2
        angularVelocity = angularVelocity * (1 - filterAlpha) + angularVel * filterAlpha
        
        // Calculate spin rate magnitude (RPM)
        let spinMagnitude = sqrt(angularVelocity.x * angularVelocity.x + 
                                angularVelocity.y * angularVelocity.y + 
                                angularVelocity.z * angularVelocity.z)
        
        // Convert from degrees/second to RPM
        let spinRateRPM = Double(spinMagnitude * degreesToRPM)
        
        // Update spin history for averaging
        spinHistory.append(spinRateRPM)
        if spinHistory.count > 10 { // Keep last 10 samples
            spinHistory.removeFirst()
        }
        
        // Calculate average spin rate to smooth out noise
        let averageSpinRate = spinHistory.reduce(0, +) / Double(spinHistory.count)
        
        // Track spin data during throw if we're in a throw session
        if !spinRatesDuringThrow.isEmpty {
            spinRatesDuringThrow.append(averageSpinRate)
            
            // Create detailed spin data point
            let spinDataPoint = SpinDataPoint(
                timestamp: timestamp,
                rpm: averageSpinRate,
                axisX: Double(angularVelocity.x),
                axisY: Double(angularVelocity.y),
                axisZ: Double(angularVelocity.z)
            )
            self.spinDataPointsDuringThrow.append(spinDataPoint)
            
            // Update average spin rate during throw
            self.avgSpinRateDuringThrow = spinRatesDuringThrow.reduce(0, +) / Double(spinRatesDuringThrow.count)
        }
        
        // Determine dominant rotation axis
        let absX = abs(angularVelocity.x)
        let absY = abs(angularVelocity.y)
        let absZ = abs(angularVelocity.z)
        
        let maxAxis = max(absX, absY, absZ)
        let totalMagnitude = absX + absY + absZ
        
        if totalMagnitude > 50 { // Only update axis if significant rotation
            if maxAxis == absX {
                spinAxis = SIMD3<Float>(angularVelocity.x > 0 ? 1 : -1, 0, 0)
            } else if maxAxis == absY {
                spinAxis = SIMD3<Float>(0, angularVelocity.y > 0 ? 1 : -1, 0)
            } else {
                spinAxis = SIMD3<Float>(0, 0, angularVelocity.z > 0 ? 1 : -1)
            }
        }
        
        // Update UI (now on main thread due to .receive(on: DispatchQueue.main))
        self.currentSpinRate = averageSpinRate
        
        // Update max spin rates
        if averageSpinRate > self.maxSpinRate {
            self.maxSpinRate = averageSpinRate
        }
        
        if averageSpinRate > self.maxSpinRateDuringThrow {
            self.maxSpinRateDuringThrow = averageSpinRate
        }
    }
    
    /// Apply noise filtering and averaging for off-center sensor readings
    /// This helps reduce the effects of centrifugal acceleration from spinning
    private func applySpeedFiltering(_ rawSpeed: Double) -> Double {
        // Add raw speed to history
        speedHistory.append(rawSpeed)
        
        // Keep only the last N samples
        if speedHistory.count > speedFilterWindow {
            speedHistory.removeFirst()
        }
        
        // Calculate moving average to smooth out noise
        let averageSpeed = speedHistory.reduce(0, +) / Double(speedHistory.count)
        
        // Adjust filtering based on spin rate
        // Higher spin rates = more centrifugal acceleration = more aggressive filtering
        let adaptiveFilterAlpha = getAdaptiveFilterAlpha()
        
        // Apply adaptive low-pass filter for extra smoothing
        // This helps with the off-center sensor issue on spinning frisbees
        let filteredSpeed = averageSpeed * Double(1 - adaptiveFilterAlpha) + rawSpeed * Double(adaptiveFilterAlpha)
        
        // Only return significant speeds (above noise threshold)
        // This helps eliminate false readings from sensor noise
        let noiseThreshold: Double = 0.5 // mph
        return filteredSpeed > noiseThreshold ? filteredSpeed : 0.0
    }
    
    /// Get adaptive filter alpha based on current spin rate
    /// Higher spin rates need more aggressive filtering due to centrifugal acceleration
    private func getAdaptiveFilterAlpha() -> Float {
        let currentSpinRPM = Float(self.currentSpinRate)
        
        // Adjust filtering based on spin rate ranges
        if currentSpinRPM > 1000 {
            // Very high spin (1000+ RPM) - most aggressive filtering
            return 0.05
        } else if currentSpinRPM > 500 {
            // High spin (500-1000 RPM) - moderate filtering
            return 0.1
        } else if currentSpinRPM > 200 {
            // Medium spin (200-500 RPM) - light filtering
            return 0.15
        } else {
            // Low spin (<200 RPM) - minimal filtering
            return speedFilterAlpha
        }
    }
    
    /// Get current speed with formatting
    var formattedSpeed: String {
        return String(format: "%.1f mph", currentSpeed)
    }
    
    /// Get current spin rate with formatting
    var formattedSpinRate: String {
        return String(format: "%.0f RPM", currentSpinRate)
    }
    
    /// Get detailed status information
    var detailedStatus: String {
        if isTracking {
            let filterLevel = getFilterLevelDescription()
            return "Tracking: \(formattedSpeed) | \(formattedSpinRate) | Filter: \(filterLevel)"
        } else {
            return status
        }
    }
    
    /// Get human-readable filter level description
    private func getFilterLevelDescription() -> String {
        let currentSpinRPM = self.currentSpinRate
        
        if currentSpinRPM > 1000 {
            return "High"
        } else if currentSpinRPM > 500 {
            return "Medium"
        } else if currentSpinRPM > 200 {
            return "Light"
        } else {
            return "Minimal"
        }
    }
    
    /// Check if device is connected
    var isDeviceConnected: Bool {
        return metawear?.peripheral.state == .connected
    }
    
    /// Get spin axis description
    var spinAxisDescription: String {
        let x = spinAxis.x
        let y = spinAxis.y
        let z = spinAxis.z
        
        if abs(x) > 0.5 {
            return x > 0 ? "Forward" : "Backward"
        } else if abs(y) > 0.5 {
            return y > 0 ? "Right" : "Left"
        } else if abs(z) > 0.5 {
            return z > 0 ? "Clockwise" : "Counter-clockwise"
        } else {
            return "None"
        }
    }
    
    /// Get spin axis components for detailed analysis
    var spinAxisX: Double { Double(spinAxis.x) }
    var spinAxisY: Double { Double(spinAxis.y) }
    var spinAxisZ: Double { Double(spinAxis.z) }
}

// MARK: - Speed Tracking Configuration

extension SpeedCalculator {
    
    /// Configure movement threshold (sensitivity)
    func setMovementThreshold(_ threshold: Float) {
        movementThreshold = threshold
    }
    
    /// Get current movement threshold
    var currentMovementThreshold: Float {
        return movementThreshold
    }
    
    /// Recommended threshold values
    enum ThresholdPreset {
        case low      // 0.02 g - Very sensitive
        case medium   // 0.05 g - Default
        case high     // 0.10 g - Less sensitive
        
        var value: Float {
            switch self {
            case .low: return 0.02
            case .medium: return 0.05
            case .high: return 0.10
            }
        }
        
        var description: String {
            switch self {
            case .low: return "Very Sensitive"
            case .medium: return "Medium"
            case .high: return "Less Sensitive"
            }
        }
    }
    
    /// Apply a preset threshold
    func applyThresholdPreset(_ preset: ThresholdPreset) {
        setMovementThreshold(preset.value)
    }
} 