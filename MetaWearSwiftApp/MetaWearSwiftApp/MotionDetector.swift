import Foundation
import MetaWear
import Combine

/// Simple motion detector using streaming data
/// Detects when frisbee starts/stops moving for throw detection
class MotionDetector: ObservableObject {
    // MARK: - Published Properties
    @Published var isMotionDetected = false
    @Published var motionStatus = "No motion"
    @Published var accelerationMagnitude: Double = 0.0
    @Published var motionThreshold: Double = 0.1 // g's - adjustable threshold
    
    // MARK: - Private Properties
    private var metawear: MetaWear?
    private var cancellables = Set<AnyCancellable>()
    private var lastAcceleration: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    private var motionHistory: [Double] = [] // Recent acceleration magnitudes
    private let motionHistorySize = 5 // Number of samples to average
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Public Methods
    
    /// Start motion detection using streaming data
    func startMotionDetection(device: MetaWear) {
        self.metawear = device
        self.motionStatus = "Starting motion detection..."
        
        // Reset state
        isMotionDetected = false
        motionHistory.removeAll()
        lastAcceleration = SIMD3<Float>(0, 0, 0)
        
        // Connect to device
        device.connect()
        
        // Set up sensor fusion for linear acceleration (100Hz streaming)
        let linearAccel = MWSensorFusion.LinearAcceleration(mode: .ndof)
        
        // Stream linear acceleration for motion detection
        device
            .publish()
            .stream(linearAccel)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] data in
                self?.processAcceleration(data)
            })
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.motionStatus = "Motion detection completed"
                    case .failure(let error):
                        self.motionStatus = "Error: \(error.localizedDescription)"
                    }
                },
                receiveValue: { _ in
                    // Data is processed in handleEvents
                }
            )
            .store(in: &cancellables)
        
        self.motionStatus = "Motion detection active"
    }
    
    /// Stop motion detection
    func stopMotionDetection() {
        cancellables.removeAll()
        metawear?.disconnect()
        isMotionDetected = false
        motionStatus = "Motion detection stopped"
    }
    
    /// Adjust motion detection sensitivity
    func setMotionThreshold(_ threshold: Double) {
        motionThreshold = threshold
        print("🔧 Motion threshold set to: \(threshold) g's")
    }
    
    // MARK: - Private Methods
    
    /// Process acceleration data for motion detection
    private func processAcceleration(_ data: Timestamped<SIMD3<Float>>) {
        let acceleration = data.value
        
        // Calculate acceleration magnitude
        let magnitude = sqrt(acceleration.x * acceleration.x + 
                           acceleration.y * acceleration.y + 
                           acceleration.z * acceleration.z)
        
        // Convert to g's (assuming 1g = 9.81 m/s²)
        let magnitudeInG = Double(magnitude) / 9.81
        
        // Update UI
        self.accelerationMagnitude = magnitudeInG
        
        // Add to motion history for averaging
        motionHistory.append(magnitudeInG)
        if motionHistory.count > motionHistorySize {
            motionHistory.removeFirst()
        }
        
        // Calculate average acceleration over recent samples
        let averageMagnitude = motionHistory.reduce(0, +) / Double(motionHistory.count)
        
        // Detect motion based on threshold
        let wasMotionDetected = isMotionDetected
        isMotionDetected = averageMagnitude > motionThreshold
        
        // Update status and log state changes
        if isMotionDetected != wasMotionDetected {
            if isMotionDetected {
                motionStatus = "Motion detected! (\(String(format: "%.2f", averageMagnitude)) g's)"
                print("🚀 Motion detected: \(String(format: "%.2f", averageMagnitude)) g's")
            } else {
                motionStatus = "No motion (\(String(format: "%.2f", averageMagnitude)) g's)"
                print("⏹️ Motion stopped: \(String(format: "%.2f", averageMagnitude)) g's")
            }
        } else {
            // Update status with current magnitude
            if isMotionDetected {
                motionStatus = "Motion detected (\(String(format: "%.2f", averageMagnitude)) g's)"
            } else {
                motionStatus = "No motion (\(String(format: "%.2f", averageMagnitude)) g's)"
            }
        }
        
        // Store last acceleration for potential future use
        lastAcceleration = acceleration
    }
    
    // MARK: - Utility Methods
    
    /// Get current motion status with formatting
    var formattedMotionStatus: String {
        return motionStatus
    }
    
    /// Get acceleration magnitude with formatting
    var formattedAcceleration: String {
        return String(format: "%.2f g's", accelerationMagnitude)
    }
    
    /// Check if motion detection is active
    var isActive: Bool {
        return !cancellables.isEmpty
    }
} 