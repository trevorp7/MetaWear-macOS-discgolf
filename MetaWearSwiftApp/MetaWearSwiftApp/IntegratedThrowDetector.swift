import Foundation
import MetaWear
import Combine

/// Integrated two-tier throw detection system
/// Combines motion detection (streaming) with high-frequency logging
class IntegratedThrowDetector: ObservableObject {
    // MARK: - Published Properties
    @Published var isActive = false
    @Published var systemStatus = "Ready"
    @Published var currentPhase = DetectionPhase.idle
    @Published var motionDetected = false
    @Published var isLogging = false
    @Published var logDuration: TimeInterval = 0.0
    @Published var logFileCount = 0
    @Published var lastLogFilePath: String?
    
    // MARK: - Detection Phases
    enum DetectionPhase: String, CaseIterable {
        case idle = "Idle"
        case monitoring = "Monitoring"
        case logging = "Logging"
        case processing = "Processing"
        case ready = "Ready"
        
        var color: String {
            switch self {
            case .idle: return "gray"
            case .monitoring: return "blue"
            case .logging: return "red"
            case .processing: return "orange"
            case .ready: return "green"
            }
        }
    }
    
    // MARK: - Private Properties
    private var metawear: MetaWear?
    private var cancellables = Set<AnyCancellable>()
    private var motionHistory: [Double] = []
    private var motionThreshold: Double = 0.2  // Increased for accelerometer baseline
    private var motionHistorySize = 5
    
    // High-frequency logger
    private let logger = HighFrequencyLogger()
    
    // Timing
    private var motionStartTime: Date?
    private var motionEndDelay: TimeInterval = 1.0 // Wait 1 second after motion stops
    private var motionEndTimer: Timer?
    
    // Calibration
    private var isCalibrating = false
    private var calibrationStartTime: Date?
    private var calibrationDuration: TimeInterval = 2.0 // 2 second calibration period
    private var baselineMagnitude: Double = 1.0 // Baseline gravity reading
    
    // Motion detection improvements
    private var consecutiveMotionSamples = 0
    private var consecutiveStillSamples = 0
    private let motionConfirmationSamples = 3 // Need 3 consecutive samples to confirm motion
    private let stillConfirmationSamples = 3 // Reduced from 5 to 3 for faster stop detection
    
    // MARK: - Initialization
    init() {
        // Observe logger state changes
        logger.$isLogging
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLogging in
                self?.isLogging = isLogging
                self?.updateSystemStatus()
                print("🔄 UI: isLogging updated to \(isLogging)")
            }
            .store(in: &cancellables)
        
        logger.$logDuration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                self?.logDuration = duration
                print("🔄 UI: logDuration updated to \(duration)")
            }
            .store(in: &cancellables)
        
        logger.$logFileCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.logFileCount = count
                print("🔄 UI: logFileCount updated to \(count)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Start the integrated detection system
    func startDetection(device: MetaWear) -> Bool {
        guard !isActive else {
            print("⚠️ Detection already active")
            return false
        }
        
        print("🚀 Starting fresh detection cycle...")
        
        // Reset any existing state
        resetMotionDetectionState()
        
        self.metawear = device
        self.isActive = true
        self.currentPhase = .monitoring
        self.motionDetected = false
        self.motionHistory.removeAll()
        self.lastLogFilePath = nil
        
        // Clear any existing cancellables
        self.cancellables.removeAll()
        
        // Ensure device is connected
        if device.peripheral.state != .connected {
            print("🔌 Connecting to device...")
            device.connect()
        }
        
        // Start calibration period
        self.isCalibrating = true
        self.calibrationStartTime = Date()
        
        self.systemStatus = "Calibrating... (2s)"
        
        // Connect to device
        device.connect()
        
        // Start low-frequency motion detection using accelerometer (separate from logging)
        let motionDetectionAccel = MWAccelerometer(rate: .hz50, gravity: .g8)
        
        device
            .publish()
            .stream(motionDetectionAccel)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] data in
                self?.processMotionData(data)
            })
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("📊 Motion detection completed")
                    case .failure(let error):
                        print("❌ Motion detection error: \(error)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        self.systemStatus = "Monitoring for motion..."
        print("🚀 Started integrated throw detection")
        print("📊 Motion detection stream active")
        
        // Schedule calibration end
        DispatchQueue.main.asyncAfter(deadline: .now() + calibrationDuration) { [weak self] in
            self?.endCalibration()
        }
        
        return true
    }
    
    /// Stop the integrated detection system
    func stopDetection() {
        guard isActive else {
            print("⚠️ Detection not active")
            return
        }
        
        print("⏹️ Stopping detection system...")
        
        // Stop motion detection
        cancellables.removeAll()
        
        // Stop logging if active
        if isLogging {
            logger.stopLogging()
            self.lastLogFilePath = logger.lastLogFile
        }
        
        // Cancel any pending timers
        motionEndTimer?.invalidate()
        motionEndTimer = nil
        
        // Reset all state
        self.isActive = false
        self.currentPhase = .idle
        self.motionDetected = false
        self.motionHistory.removeAll()
        self.consecutiveMotionSamples = 0
        self.consecutiveStillSamples = 0
        self.baselineMagnitude = 1.0
        self.isCalibrating = false
        self.calibrationStartTime = nil
        self.motionStartTime = nil
        
        self.systemStatus = "Detection stopped"
        
        print("⏹️ Stopped integrated throw detection - all state reset")
        print("🔄 System ready for next detection cycle")
    }
    
    /// Set motion detection threshold
    func setMotionThreshold(_ threshold: Double) {
        motionThreshold = threshold
        print("🔧 Motion threshold set to: \(threshold) g's")
    }
    
    /// Set motion end delay (how long to wait after motion stops)
    func setMotionEndDelay(_ delay: TimeInterval) {
        motionEndDelay = delay
        print("⏱️ Motion end delay set to: \(delay) seconds")
    }
    
    /// Get system statistics
    var systemStats: String {
        switch currentPhase {
        case .idle:
            return "System ready"
        case .monitoring:
            return "Monitoring for motion"
        case .logging:
            return String(format: "Logging... %.1fs", logDuration)
        case .processing:
            return "Processing log data"
        case .ready:
            return "Ready for next throw"
        }
    }
    
    // MARK: - Private Methods
    
    /// Process motion detection data
    private func processMotionData(_ data: Timestamped<SIMD3<Float>>) {
        let acceleration = data.value
        
        let magnitude = sqrt(acceleration.x * acceleration.x + 
                           acceleration.y * acceleration.y + 
                           acceleration.z * acceleration.z)
        
        // For accelerometer data, magnitude is already in g's
        let magnitudeInG = Double(magnitude)
        
        // Debug: Print first few samples to confirm data flow
        if motionHistory.count < 5 {
            print("📊 Motion detection received: \(String(format: "%.3f", magnitudeInG)) g's")
        }
        
        // Update motion history
        motionHistory.append(magnitudeInG)
        if motionHistory.count > motionHistorySize {
            motionHistory.removeFirst()
        }
        
        let averageMagnitude = motionHistory.reduce(0, +) / Double(motionHistory.count)
        
        // During calibration, collect baseline readings
        if isCalibrating {
            print("🔧 Calibrating... magnitude: \(String(format: "%.3f", averageMagnitude)) g's")
            // Update baseline during calibration
            baselineMagnitude = averageMagnitude
            return
        }
        
        let wasMotionDetected = motionDetected
        // Calculate deviation from baseline (gravity-compensated motion detection)
        let deviationFromBaseline = abs(averageMagnitude - baselineMagnitude)
        let currentMotionDetected = deviationFromBaseline > motionThreshold
        
        // Improved motion detection with confirmation
        if currentMotionDetected {
            consecutiveMotionSamples += 1
            consecutiveStillSamples = 0
        } else {
            consecutiveStillSamples += 1
            consecutiveMotionSamples = 0
        }
        
        // Determine new motion state with confirmation
        var newMotionDetected: Bool
        if currentMotionDetected && consecutiveMotionSamples >= motionConfirmationSamples {
            newMotionDetected = true
        } else if !currentMotionDetected && consecutiveStillSamples >= stillConfirmationSamples {
            newMotionDetected = false
        } else {
            newMotionDetected = motionDetected // Keep current state
        }
        
        // Additional check: if we're logging and deviation drops significantly, consider motion stopped
        if motionDetected && !currentMotionDetected && deviationFromBaseline < (motionThreshold * 0.7) {
            print("🔍 Potential motion stop detected: deviation \(String(format: "%.3f", deviationFromBaseline)) g's is well below threshold \(String(format: "%.3f", motionThreshold)) g's")
        }
        
        // Force motion stop if deviation is very low while logging
        if motionDetected && deviationFromBaseline < (motionThreshold * 0.5) && consecutiveStillSamples >= 2 {
            print("🛑 Force motion stop: deviation \(String(format: "%.3f", deviationFromBaseline)) g's is very low")
            newMotionDetected = false
        }
        
        motionDetected = newMotionDetected
        
        // Debug motion detection
        if motionDetected != wasMotionDetected {
            print("🔄 Motion state changed: \(wasMotionDetected) → \(motionDetected) (magnitude: \(String(format: "%.3f", averageMagnitude)) g's, baseline: \(String(format: "%.3f", baselineMagnitude)) g's, deviation: \(String(format: "%.3f", deviationFromBaseline)) g's, threshold: \(String(format: "%.3f", motionThreshold)) g's, motion: \(consecutiveMotionSamples), still: \(consecutiveStillSamples)")
        } else {
            // Debug ongoing state
            print("📊 Motion: \(motionDetected), magnitude: \(String(format: "%.3f", averageMagnitude)) g's, baseline: \(String(format: "%.3f", baselineMagnitude)) g's, deviation: \(String(format: "%.3f", deviationFromBaseline)) g's, motion: \(consecutiveMotionSamples), still: \(consecutiveStillSamples)")
        }
        
        // Handle motion state changes
        if motionDetected != wasMotionDetected {
            if motionDetected {
                // Motion started
                handleMotionStarted()
            } else {
                // Motion stopped
                handleMotionStopped()
            }
        }
        
        updateSystemStatus()
        
        // Check if motion detection stream is still active (debug)
        if isActive && currentPhase == .monitoring && motionHistory.isEmpty {
            print("⚠️ Motion detection stream may be inactive - no data received")
        }
    }
    
    /// End calibration period
    private func endCalibration() {
        isCalibrating = false
        calibrationStartTime = nil
        systemStatus = "Monitoring for motion..."
        print("✅ Calibration complete - motion detection active")
    }
    
    /// Handle motion start event
    private func handleMotionStarted() {
        print("🚀 Motion detected - starting high-frequency logging")
        
        // Cancel any pending stop timer
        motionEndTimer?.invalidate()
        motionEndTimer = nil
        
        // Start high-frequency logging
        if let device = metawear {
            print("📊 Attempting to start high-frequency logging...")
            let success = logger.startLogging(device: device)
            if success {
                currentPhase = .logging
                motionStartTime = Date()
                systemStatus = "High-frequency logging active"
                print("✅ High-frequency logging started successfully")
            } else {
                print("❌ Failed to start high-frequency logging")
                systemStatus = "Error starting logging"
            }
        } else {
            print("❌ No MetaWear device available for logging")
        }
    }
    
    /// Handle motion stop event
    private func handleMotionStopped() {
        print("⏹️ Motion stopped - scheduling logging stop")
        
        // Schedule logging stop after delay
        motionEndTimer?.invalidate()
        motionEndTimer = Timer.scheduledTimer(withTimeInterval: motionEndDelay, repeats: false) { [weak self] _ in
            self?.stopLoggingAfterDelay()
        }
        
        systemStatus = "Motion stopped - logging will stop in \(String(format: "%.1f", motionEndDelay))s"
    }
    
    /// Stop logging after motion end delay
    private func stopLoggingAfterDelay() {
        guard isLogging else { return }
        
        print("📊 Stopping high-frequency logging")
        currentPhase = .processing
        
        logger.stopLogging()
        self.lastLogFilePath = logger.lastLogFile
        
        // Check if log was saved successfully
        if !logger.lastLogFile.isEmpty {
            currentPhase = .ready
            systemStatus = "Log saved - detection complete"
            print("✅ Log saved: \(logger.lastLogFile)")
            print("🔄 UI: lastLogFilePath updated to \(logger.lastLogFile)")
            
            // Brief delay then stop detection entirely
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.stopDetection()
                print("🔄 Detection stopped after successful throw")
            }
        } else {
            currentPhase = .ready
            systemStatus = "Error saving log - detection complete"
            print("❌ Failed to save log")
            
            // Brief delay then stop detection entirely
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.stopDetection()
                print("🔄 Detection stopped after failed throw")
            }
        }
    }
    
    /// Update system status based on current state
    private func updateSystemStatus() {
        switch currentPhase {
        case .idle:
            systemStatus = "Ready"
        case .monitoring:
            if isCalibrating {
                let remaining = calibrationDuration - (Date().timeIntervalSince(calibrationStartTime ?? Date()))
                systemStatus = String(format: "Calibrating... (%.1fs)", max(0, remaining))
            } else if motionDetected {
                systemStatus = "Motion detected - logging active"
            } else {
                systemStatus = "Monitoring for motion"
            }
        case .logging:
            systemStatus = String(format: "Logging... %.1fs", logDuration)
        case .processing:
            systemStatus = "Processing log data"
        case .ready:
            systemStatus = "Ready for next throw"
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get list of available log files
    func getAvailableLogFiles() -> [String] {
        return logger.getAvailableLogFiles()
    }
    
    /// Load log file data
    func loadLogFile(_ fileName: String) -> HighFrequencyLogger.LogFileInfo? {
        return logger.loadLogFile(fileName)
    }
    
    /// Get current motion threshold
    var currentMotionThreshold: Double {
        return motionThreshold
    }
    
    /// Get current motion end delay
    var currentMotionEndDelay: TimeInterval {
        return motionEndDelay
    }
    
    /// Refresh log file count from disk
    func refreshLogFileCount() {
        let files = getAvailableLogFiles()
        logger.logFileCount = files.count
        print("🔄 UI: Refreshed log file count to \(files.count)")
    }
    
    /// Force stop logging (for testing)
    func forceStopLogging() {
        print("🛑 Force stopping logging")
        stopLoggingAfterDelay()
    }
    
    /// Reset motion detection state for next throw
    private func resetMotionDetectionState() {
        motionDetected = false
        motionHistory.removeAll()
        consecutiveMotionSamples = 0
        consecutiveStillSamples = 0
        baselineMagnitude = 1.0
        motionStartTime = nil
        
        print("🔄 Motion detection state reset for next throw")
    }
    
} 