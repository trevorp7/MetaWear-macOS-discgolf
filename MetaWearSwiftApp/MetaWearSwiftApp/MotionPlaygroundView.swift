import SwiftUI
import Combine
import MetaWear
import Foundation
import SceneKit

// MARK: - Motion Playground View
struct MotionPlaygroundView: View {
    @ObservedObject var metawearManager: MetaWearManager
    @StateObject private var motionPlayground = MotionPlayground()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("🎯 Motion Playground")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Explore MetaWear motion sensors and sensor fusion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Connection Status
                ConnectionStatusView(metawearManager: metawearManager)
                
                // Sensor Fusion Section
                SensorFusionSection(motionPlayground: motionPlayground, metawearManager: metawearManager)
                
                // Motion Sensors Section
                MotionSensorsSection(motionPlayground: motionPlayground, metawearManager: metawearManager)
                
                // Motion Analysis Section
                MotionAnalysisSection(motionPlayground: motionPlayground, metawearManager: metawearManager)
                
                // Activity Recognition Section
                ActivityRecognitionSection(motionPlayground: motionPlayground, metawearManager: metawearManager)
                
                // Data Logging Section
                DataLoggingSection(motionPlayground: motionPlayground, metawearManager: metawearManager)
                
                // 3D Visualization Section
                ThreeDVisualizationSection(motionPlayground: motionPlayground, metawearManager: metawearManager)
            }
            .padding()
        }
        .onAppear {
            print("🎯 MotionPlaygroundView appeared")
        }
        .onDisappear {
            motionPlayground.stopAllStreaming()
        }
    }
}

// MARK: - Connection Status View
struct ConnectionStatusView: View {
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Circle()
                    .fill(metawearManager.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(metawearManager.isConnected ? "✅ Connected" : "❌ Disconnected")
                    .foregroundColor(metawearManager.isConnected ? .green : .red)
                    .fontWeight(.semibold)
            }
            
            if metawearManager.isConnected {
                Text("Device: \(metawearManager.deviceAddress)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Sensor Fusion Section
struct SensorFusionSection: View {
    @ObservedObject var motionPlayground: MotionPlayground
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("🧭 Sensor Fusion (NDoF)")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 10) {
                // Euler Angles
                SensorDataCard(
                    title: "Euler Angles (Pitch, Roll, Yaw)",
                    data: motionPlayground.eulerAngles,
                    unit: "degrees",
                    isActive: motionPlayground.isEulerActive
                ) {
                    motionPlayground.toggleEulerAngles(metawearManager: metawearManager)
                }
                
                // Quaternion
                SensorDataCard(
                    title: "Quaternion (WXYZ)",
                    data: motionPlayground.quaternion,
                    unit: "quaternion",
                    isActive: motionPlayground.isQuaternionActive
                ) {
                    motionPlayground.toggleQuaternion(metawearManager: metawearManager)
                }
                
                // Gravity
                SensorDataCard(
                    title: "Gravity Vector",
                    data: motionPlayground.gravity,
                    unit: "g",
                    isActive: motionPlayground.isGravityActive
                ) {
                    motionPlayground.toggleGravity(metawearManager: metawearManager)
                }
                
                // Linear Acceleration
                SensorDataCard(
                    title: "Linear Acceleration",
                    data: motionPlayground.linearAcceleration,
                    unit: "g",
                    isActive: motionPlayground.isLinearAccelActive
                ) {
                    motionPlayground.toggleLinearAcceleration(metawearManager: metawearManager)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Motion Sensors Section
struct MotionSensorsSection: View {
    @ObservedObject var motionPlayground: MotionPlayground
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("📡 Motion Sensors")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 10) {
                // Accelerometer
                SensorDataCard(
                    title: "Accelerometer",
                    data: motionPlayground.accelerometer,
                    unit: "g",
                    isActive: motionPlayground.isAccelerometerActive
                ) {
                    motionPlayground.toggleAccelerometer(metawearManager: metawearManager)
                }
                
                // Gyroscope
                SensorDataCard(
                    title: "Gyroscope",
                    data: motionPlayground.gyroscope,
                    unit: "deg/s",
                    isActive: motionPlayground.isGyroscopeActive
                ) {
                    motionPlayground.toggleGyroscope(metawearManager: metawearManager)
                }
                
                // Magnetometer
                SensorDataCard(
                    title: "Magnetometer",
                    data: motionPlayground.magnetometer,
                    unit: "μT",
                    isActive: motionPlayground.isMagnetometerActive
                ) {
                    motionPlayground.toggleMagnetometer(metawearManager: metawearManager)
                }
                
                // Step Counter
                SensorDataCard(
                    title: "Step Counter",
                    data: motionPlayground.stepCounter,
                    unit: "steps",
                    isActive: motionPlayground.isStepCounterActive
                ) {
                    motionPlayground.toggleStepCounter(metawearManager: metawearManager)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Motion Analysis Section
struct MotionAnalysisSection: View {
    @ObservedObject var motionPlayground: MotionPlayground
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("📊 Motion Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 10) {
                // Motion Intensity
                SensorDataCard(
                    title: "Motion Intensity",
                    data: motionPlayground.motionIntensity,
                    unit: "m/s²",
                    isActive: motionPlayground.isMotionIntensityActive
                ) {
                    motionPlayground.toggleMotionIntensity(metawearManager: metawearManager)
                }
                
                // Speed Calculation
                SensorDataCard(
                    title: "Calculated Speed",
                    data: motionPlayground.calculatedSpeed,
                    unit: "m/s",
                    isActive: motionPlayground.isSpeedCalculationActive
                ) {
                    motionPlayground.toggleSpeedCalculation(metawearManager: metawearManager)
                }
                
                // Orientation Detection
                SensorDataCard(
                    title: "Device Orientation",
                    data: motionPlayground.deviceOrientation,
                    unit: "orientation",
                    isActive: motionPlayground.isOrientationActive
                ) {
                    motionPlayground.toggleOrientation(metawearManager: metawearManager)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Activity Recognition Section
struct ActivityRecognitionSection: View {
    @ObservedObject var motionPlayground: MotionPlayground
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("🚶 Activity Recognition")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 10) {
                // Walking Detection
                ActivityCard(
                    title: "Walking Detection",
                    isDetected: motionPlayground.isWalking,
                    isActive: motionPlayground.isWalkingDetectionActive
                ) {
                    motionPlayground.toggleWalkingDetection(metawearManager: metawearManager)
                }
                
                // Running Detection
                ActivityCard(
                    title: "Running Detection",
                    isDetected: motionPlayground.isRunning,
                    isActive: motionPlayground.isRunningDetectionActive
                ) {
                    motionPlayground.toggleRunningDetection(metawearManager: metawearManager)
                }
                
                // Stationary Detection
                ActivityCard(
                    title: "Stationary Detection",
                    isDetected: motionPlayground.isStationary,
                    isActive: motionPlayground.isStationaryDetectionActive
                ) {
                    motionPlayground.toggleStationaryDetection(metawearManager: metawearManager)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Data Logging Section
struct DataLoggingSection: View {
    @ObservedObject var motionPlayground: MotionPlayground
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("💾 Data Logging")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Motion Data Logging")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Log sensor fusion data for analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        motionPlayground.toggleMotionLogging(metawearManager: metawearManager)
                    }) {
                        Text(motionPlayground.isMotionLoggingActive ? "Stop Logging" : "Start Logging")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(motionPlayground.isMotionLoggingActive ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
                
                if motionPlayground.isMotionLoggingActive {
                    HStack {
                        Text("Logging active...")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                        Button("Download") {
                            motionPlayground.downloadLogs(metawearManager: metawearManager)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 3D Visualization Section
struct ThreeDVisualizationSection: View {
    @ObservedObject var motionPlayground: MotionPlayground
    @ObservedObject var metawearManager: MetaWearManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("🎮 3D Device Orientation")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Real-time 3D Motion Visualization")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Shows device orientation and position trail in 3D space")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            motionPlayground.toggleQuaternion(metawearManager: metawearManager)
                            // Also start speed calculation for position tracking
                            if !motionPlayground.isSpeedCalculationActive {
                                motionPlayground.toggleSpeedCalculation(metawearManager: metawearManager)
                            }
                        }) {
                            Text(motionPlayground.isQuaternionActive ? "Stop 3D View" : "Start 3D View")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(motionPlayground.isQuaternionActive ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        
                        Button(action: {
                            motionPlayground.toggleSpeedCalculation(metawearManager: metawearManager)
                        }) {
                            Text(motionPlayground.isSpeedCalculationActive ? "Stop Position" : "Start Position")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(motionPlayground.isSpeedCalculationActive ? Color.orange : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
                
                if motionPlayground.isQuaternionActive {
                    DeviceOrientationView(
                        quaternion: motionPlayground.currentQuaternion,
                        position: motionPlayground.devicePosition,
                        positionHistory: motionPlayground.positionHistory
                    )
                    .frame(height: 500)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Show position info
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Device Position:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("X: \(String(format: "%.2f", motionPlayground.devicePosition.x)) m (Left/Right)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Y: \(String(format: "%.2f", motionPlayground.devicePosition.y)) m (Up/Down)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Z: \(String(format: "%.2f", motionPlayground.devicePosition.z)) m (Front/Back)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Speed Calculation: \(motionPlayground.isSpeedCalculationActive ? "Active" : "Inactive")")
                            .font(.caption)
                            .foregroundColor(motionPlayground.isSpeedCalculationActive ? .green : .red)
                    }
                    .padding(.horizontal)
                } else {
                    Text("3D visualization paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Sensor Data Card
struct SensorDataCard: View {
    let title: String
    let data: String
    let unit: String
    let isActive: Bool
    let toggleAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(data.isEmpty ? "No data" : "\(data) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Spacer()
            
            Button(action: toggleAction) {
                Text(isActive ? "Stop" : "Start")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isActive ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    let title: String
    let isDetected: Bool
    let isActive: Bool
    let toggleAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack {
                    Circle()
                        .fill(isDetected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(isDetected ? "Detected" : "Not detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: toggleAction) {
                Text(isActive ? "Stop" : "Start")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isActive ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Device Orientation View
struct DeviceOrientationView: View {
    let quaternion: simd_quatf
    let position: SIMD3<Float>
    let positionHistory: [SIMD3<Float>]
    
    var body: some View {
        SceneKitDeviceView(
            quaternion: quaternion,
            position: position,
            positionHistory: positionHistory
        )
    }
}

// MARK: - SceneKit Device View
struct SceneKitDeviceView: NSViewRepresentable {
    let quaternion: simd_quatf
    let position: SIMD3<Float>
    let positionHistory: [SIMD3<Float>]
    
    func makeNSView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = NSColor.windowBackgroundColor
        sceneView.scene = createScene()
        return sceneView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        // Update device position only (no rotation - static box)
        if let deviceNode = nsView.scene?.rootNode.childNode(withName: "device", recursively: true) {
            // Update position with much higher sensitivity for better movement visibility
            let scaleFactor: Float = 5.0 // Much higher scale for very visible movement
            deviceNode.position = SCNVector3(position.x * scaleFactor, position.y * scaleFactor, position.z * scaleFactor)
        }
        
        // No trail needed
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Camera positioned to see the cube clearly
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 4)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)
        
        // Enhanced lighting
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 150
        scene.rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 1000
        directionalLight.position = SCNVector3(10, 10, 10)
        scene.rootNode.addChildNode(directionalLight)
        
        // Create 3D space boundaries (room-like environment)
        create3DSpace(scene: scene)
        
        // Device representation (simple gray cube)
        let deviceNode = SCNNode(geometry: SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.02))
        deviceNode.geometry?.firstMaterial?.diffuse.contents = NSColor.lightGray
        deviceNode.geometry?.firstMaterial?.specular.contents = NSColor.white
        deviceNode.geometry?.firstMaterial?.emission.contents = NSColor.lightGray.withAlphaComponent(0.2)
        deviceNode.name = "device"
        scene.rootNode.addChildNode(deviceNode)
        
        return scene
    }
    
    private func create3DSpace(scene: SCNScene) {
        // No background space needed, only the cube
    }
    

}

// MARK: - Motion Playground Class
class MotionPlayground: ObservableObject {
    // Sensor Fusion Data
    @Published var eulerAngles: String = ""
    @Published var quaternion: String = ""
    @Published var gravity: String = ""
    @Published var linearAcceleration: String = ""
    
    // Motion Sensors Data
    @Published var accelerometer: String = ""
    @Published var gyroscope: String = ""
    @Published var magnetometer: String = ""
    @Published var stepCounter: String = ""
    
    // Motion Analysis Data
    @Published var motionIntensity: String = ""
    @Published var calculatedSpeed: String = ""
    @Published var deviceOrientation: String = ""
    
    // Activity Recognition
    @Published var isWalking: Bool = false
    @Published var isRunning: Bool = false
    @Published var isStationary: Bool = false
    
    // Active States
    @Published var isEulerActive: Bool = false
    @Published var isQuaternionActive: Bool = false
    @Published var isGravityActive: Bool = false
    @Published var isLinearAccelActive: Bool = false
    @Published var isAccelerometerActive: Bool = false
    @Published var isGyroscopeActive: Bool = false
    @Published var isMagnetometerActive: Bool = false
    @Published var isStepCounterActive: Bool = false
    @Published var isMotionIntensityActive: Bool = false
    @Published var isSpeedCalculationActive: Bool = false
    @Published var isOrientationActive: Bool = false
    @Published var isWalkingDetectionActive: Bool = false
    @Published var isRunningDetectionActive: Bool = false
    @Published var isStationaryDetectionActive: Bool = false
    @Published var isMotionLoggingActive: Bool = false
    
    // 3D Visualization Data
    @Published var currentQuaternion: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1))
    @Published var devicePosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    @Published var positionHistory: [SIMD3<Float>] = []
    
    // Position tracking constants
    private let maxPositionHistory = 100 // Maximum number of position points to store
    
    // Private properties
    private var cancellables = Set<AnyCancellable>()
    private var eulerCancellable: AnyCancellable?
    private var quaternionCancellable: AnyCancellable?
    private var gravityCancellable: AnyCancellable?
    private var linearAccelCancellable: AnyCancellable?
    private var accelerometerCancellable: AnyCancellable?
    private var gyroscopeCancellable: AnyCancellable?
    private var magnetometerCancellable: AnyCancellable?
    private var stepCounterCancellable: AnyCancellable?
    private var motionIntensityCancellable: AnyCancellable?
    private var speedCalculationCancellable: AnyCancellable?
    private var orientationCancellable: AnyCancellable?
    private var walkingDetectionCancellable: AnyCancellable?
    private var runningDetectionCancellable: AnyCancellable?
    private var stationaryDetectionCancellable: AnyCancellable?
    private var loggingCancellable: AnyCancellable?
    private var velocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    private var lastTimestamp: Date?
    private var isMoving: Bool = false
    private var movementThreshold: Float = 0.02 // g's - slightly higher threshold to reduce noise
    
    // Drift correction
    private var velocityHistory: [SIMD3<Float>] = []
    private var accelerationHistory: [SIMD3<Float>] = []
    private let historyWindow: Int = 20 // Number of samples for drift correction
    private var stationaryCount: Int = 0
    private let maxStationaryCount: Int = 50 // Reset velocity after this many stationary samples
    

    
    // MARK: - Sensor Fusion Methods
    
    func toggleEulerAngles(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isEulerActive {
            isEulerActive = false
            eulerAngles = ""
            // Cancel the specific subscription
            eulerCancellable?.cancel()
            eulerCancellable = nil
        } else {
            isEulerActive = true
            let eulerAngles = MWSensorFusion.EulerAngles(mode: .ndof)
            eulerCancellable = device.publish()
                .stream(eulerAngles)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    guard let self = self, self.isEulerActive else { return }
                    let euler = data.value
                    self.eulerAngles = String(format: "P:%.1f° R:%.1f° Y:%.1f°", euler.x, euler.y, euler.z)
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Euler angles streaming completed")
                        case .failure(let error):
                            print("🎯 Euler angles error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
        }
    }
    
    func toggleQuaternion(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isQuaternionActive {
            isQuaternionActive = false
            quaternion = ""
        } else {
            isQuaternionActive = true
            let quaternion = MWSensorFusion.Quaternion(mode: .ndof)
            device.publish()
                .stream(quaternion)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let quat = data.value
                    self?.quaternion = String(format: "W:%.3f X:%.3f Y:%.3f Z:%.3f", quat.vector.w, quat.vector.x, quat.vector.y, quat.vector.z)
                    self?.currentQuaternion = quat
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Quaternion streaming completed")
                        case .failure(let error):
                            print("🎯 Quaternion error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func toggleGravity(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isGravityActive {
            isGravityActive = false
            gravity = ""
        } else {
            isGravityActive = true
            let gravity = MWSensorFusion.Gravity(mode: .ndof)
            device.publish()
                .stream(gravity)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let gravity = data.value
                    self?.gravity = String(format: "X:%.3fg Y:%.3fg Z:%.3fg", gravity.x, gravity.y, gravity.z)
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Gravity streaming completed")
                        case .failure(let error):
                            print("🎯 Gravity error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func toggleLinearAcceleration(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isLinearAccelActive {
            isLinearAccelActive = false
            linearAcceleration = ""
        } else {
            isLinearAccelActive = true
            let linearAccel = MWSensorFusion.LinearAcceleration(mode: .ndof)
            device.publish()
                .stream(linearAccel)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let accel = data.value
                    self?.linearAcceleration = String(format: "X:%.3fg Y:%.3fg Z:%.3fg", accel.x, accel.y, accel.z)
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Linear acceleration streaming completed")
                        case .failure(let error):
                            print("🎯 Linear acceleration error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Motion Sensors Methods
    
    func toggleAccelerometer(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isAccelerometerActive {
            isAccelerometerActive = false
            accelerometer = ""
        } else {
            isAccelerometerActive = true
            let accelerometer = MWAccelerometer(rate: .hz100, gravity: .g8)
            accelerometerCancellable = device.publish()
                .stream(accelerometer)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let accel = data.value
                    self?.accelerometer = String(format: "X:%.3fg Y:%.3fg Z:%.3fg", accel.x, accel.y, accel.z)
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Accelerometer streaming completed")
                        case .failure(let error):
                            print("🎯 Accelerometer error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
            accelerometerCancellable?.store(in: &cancellables)
        }
    }
    
    func toggleGyroscope(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isGyroscopeActive {
            isGyroscopeActive = false
            gyroscope = ""
        } else {
            isGyroscopeActive = true
            let gyroscope = MWGyroscope(rate: .hz100, range: .dps2000)
            gyroscopeCancellable = device.publish()
                .stream(gyroscope)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let gyro = data.value
                    self?.gyroscope = String(format: "X:%.1f°/s Y:%.1f°/s Z:%.1f°/s", gyro.x, gyro.y, gyro.z)
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Gyroscope streaming completed")
                        case .failure(let error):
                            print("🎯 Gyroscope error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
            gyroscopeCancellable?.store(in: &cancellables)
        }
    }
    
    func toggleMagnetometer(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isMagnetometerActive {
            isMagnetometerActive = false
            magnetometer = ""
        } else {
            isMagnetometerActive = true
            let magnetometer = MWMagnetometer(freq: .hz30)
            magnetometerCancellable = device.publish()
                .stream(magnetometer)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let mag = data.value
                    self?.magnetometer = String(format: "X:%.1fμT Y:%.1fμT Z:%.1fμT", mag.x, mag.y, mag.z)
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Magnetometer streaming completed")
                        case .failure(let error):
                            print("🎯 Magnetometer error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
            magnetometerCancellable?.store(in: &cancellables)
        }
    }
    
    func toggleStepCounter(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isStepCounterActive {
            isStepCounterActive = false
            stepCounter = ""
        } else {
            isStepCounterActive = true
            device.publish()
                .stream(.stepCounter())
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let count = data.value
                    self?.stepCounter = "\(count) steps"
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Step counter streaming completed")
                        case .failure(let error):
                            print("🎯 Step counter error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Motion Analysis Methods
    
    func toggleMotionIntensity(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isMotionIntensityActive {
            isMotionIntensityActive = false
            motionIntensity = ""
        } else {
            isMotionIntensityActive = true
            let accelerometer = MWAccelerometer(rate: .hz100, gravity: .g8)
            motionIntensityCancellable = device.publish()
                .stream(accelerometer)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let accel = data.value
                    
                    // Check for valid acceleration values
                    guard !accel.x.isNaN && !accel.y.isNaN && !accel.z.isNaN else {
                        self?.motionIntensity = "0.000 g (RMS)"
                        return
                    }
                    
                    // Calculate RMS (Root Mean Square) for motion intensity
                    let rms = sqrt((accel.x * accel.x + accel.y * accel.y + accel.z * accel.z) / 3.0)
                    
                    // Check for valid RMS value
                    if rms.isNaN || rms.isInfinite {
                        self?.motionIntensity = "0.000 g (RMS)"
                    } else {
                        self?.motionIntensity = String(format: "%.3f g (RMS)", rms)
                    }
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Motion intensity streaming completed")
                        case .failure(let error):
                            print("🎯 Motion intensity error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
            motionIntensityCancellable?.store(in: &cancellables)
        }
    }
    
    func toggleSpeedCalculation(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isSpeedCalculationActive {
            isSpeedCalculationActive = false
            calculatedSpeed = ""
            velocity = SIMD3<Float>(0, 0, 0)
            lastTimestamp = nil
            isMoving = false
            // Cancel the specific subscription
            speedCalculationCancellable?.cancel()
            speedCalculationCancellable = nil
        } else {
            isSpeedCalculationActive = true
            
            // Reset all values to prevent NaN and drift
            velocity = SIMD3<Float>(0, 0, 0)
            devicePosition = SIMD3<Float>(0, 0, 0)
            positionHistory.removeAll()
            velocityHistory.removeAll()
            accelerationHistory.removeAll()
            lastTimestamp = nil
            isMoving = false
            stationaryCount = 0
            calculatedSpeed = "0.00 m/s"
            
            let linearAccel = MWSensorFusion.LinearAcceleration(mode: .ndof)
            speedCalculationCancellable = device.publish()
                .stream(linearAccel)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    guard let self = self, self.isSpeedCalculationActive else { return }
                    self.updateSpeed(acceleration: data)
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Speed calculation streaming completed")
                        case .failure(let error):
                            print("🎯 Speed calculation error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
            speedCalculationCancellable?.store(in: &cancellables)
        }
    }
    
    private func updateSpeed(acceleration: Timestamped<SIMD3<Float>>) {
        let accel = acceleration.value
        let timestamp = acceleration.time
        
        // Calculate time delta
        guard let lastTime = lastTimestamp else {
            lastTimestamp = timestamp
            return
        }
        
        let deltaTime = Float(timestamp.timeIntervalSince(lastTime))
        
        // Check for valid delta time
        guard deltaTime > 0 && deltaTime < 1.0 else {
            lastTimestamp = timestamp
            return
        }
        
        lastTimestamp = timestamp
        
        // Calculate motion intensity (RMS) for better movement detection
        let accelerationMagnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
        
        // Check for valid acceleration values
        guard !accelerationMagnitude.isNaN && !accelerationMagnitude.isInfinite else {
            return
        }
        
        // Store acceleration history for drift correction
        accelerationHistory.append(accel)
        if accelerationHistory.count > historyWindow {
            accelerationHistory.removeFirst()
        }
        
        // Use motion intensity for movement detection with hysteresis
        if accelerationMagnitude > movementThreshold {
            isMoving = true
            stationaryCount = 0
        } else {
            stationaryCount += 1
            if stationaryCount > maxStationaryCount {
                isMoving = false
                // Reset everything when stationary for too long
                velocity = SIMD3<Float>(0, 0, 0)
                velocityHistory.removeAll()
                accelerationHistory.removeAll()
                stationaryCount = 0
            }
        }
        
        // Integrate acceleration to get velocity (only when moving)
        if isMoving {
            let accelMps2 = accel * 9.81 // Convert to m/s²
            
            // Check for valid acceleration values
            guard !accelMps2.x.isNaN && !accelMps2.y.isNaN && !accelMps2.z.isNaN else {
                return
            }
            
            // Apply drift correction using acceleration history
            let correctedAccel = applyDriftCorrection(accelMps2)
            
            // Integrate corrected acceleration
            velocity += correctedAccel * deltaTime
            
            // Store velocity history for additional drift correction
            velocityHistory.append(velocity)
            if velocityHistory.count > historyWindow {
                velocityHistory.removeFirst()
            }
            
            // Apply velocity drift correction
            velocity = applyVelocityDriftCorrection(velocity)
            
            // Check for valid velocity values
            guard !velocity.x.isNaN && !velocity.y.isNaN && !velocity.z.isNaN else {
                velocity = SIMD3<Float>(0, 0, 0)
                return
            }
            
            // Update position based on velocity
            updatePosition(deltaTime: deltaTime)
        } else {
            // Gradually reduce velocity when not moving (instead of instant reset)
            let dampingFactor: Float = 0.8
            velocity *= dampingFactor
        }
        
        // Calculate speed magnitude with safety checks
        let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z)
        
        // Check for valid speed value
        if speed.isNaN || speed.isInfinite {
            self.calculatedSpeed = "0.00 m/s"
        } else {
            self.calculatedSpeed = String(format: "%.2f m/s", speed)
        }
    }
    
    private func updatePosition(deltaTime: Float) {
        // Check for valid delta time
        guard deltaTime > 0 && deltaTime < 1.0 else {
            return
        }
        
        // Check for valid velocity values
        guard !velocity.x.isNaN && !velocity.y.isNaN && !velocity.z.isNaN else {
            velocity = SIMD3<Float>(0, 0, 0)
            return
        }
        
        // Integrate velocity to get position
        let displacement = velocity * deltaTime
        
        // Check for valid displacement values
        guard !displacement.x.isNaN && !displacement.y.isNaN && !displacement.z.isNaN else {
            return
        }
        
        devicePosition += displacement
        
        // Check for valid position values
        guard !devicePosition.x.isNaN && !devicePosition.y.isNaN && !devicePosition.z.isNaN else {
            devicePosition = SIMD3<Float>(0, 0, 0)
            return
        }
        
        // Add to position history
        positionHistory.append(devicePosition)
        
        // Limit history size to prevent memory issues
        if positionHistory.count > maxPositionHistory {
            positionHistory.removeFirst()
        }
    }
    
    // MARK: - Drift Correction Methods
    
    private func applyDriftCorrection(_ acceleration: SIMD3<Float>) -> SIMD3<Float> {
        guard accelerationHistory.count >= 5 else {
            return acceleration
        }
        
        // Calculate mean acceleration over history window
        let meanAccel = accelerationHistory.reduce(SIMD3<Float>(0, 0, 0)) { $0 + $1 } / Float(accelerationHistory.count)
        
        // Remove bias (drift) from current acceleration
        let correctedAccel = acceleration - meanAccel
        
        // Apply low-pass filter to reduce noise
        let filterAlpha: Float = 0.3
        return correctedAccel * filterAlpha + acceleration * (1 - filterAlpha)
    }
    
    private func applyVelocityDriftCorrection(_ velocity: SIMD3<Float>) -> SIMD3<Float> {
        guard velocityHistory.count >= 5 else {
            return velocity
        }
        
        // Calculate mean velocity over history window
        let meanVelocity = velocityHistory.reduce(SIMD3<Float>(0, 0, 0)) { $0 + $1 } / Float(velocityHistory.count)
        
        // If velocity is very small compared to mean, likely drift
        let velocityMagnitude = sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z)
        let meanMagnitude = sqrt(meanVelocity.x * meanVelocity.x + meanVelocity.y * meanVelocity.y + meanVelocity.z * meanVelocity.z)
        
        if velocityMagnitude < meanMagnitude * 0.1 {
            // Likely drift, apply stronger correction
            return velocity * 0.5
        }
        
        // Apply moderate drift correction
        let driftCorrection: Float = 0.9
        return velocity * driftCorrection
    }
    
    func toggleOrientation(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isOrientationActive {
            isOrientationActive = false
            deviceOrientation = ""
        } else {
            isOrientationActive = true
            let gravity = MWSensorFusion.Gravity(mode: .ndof)
            orientationCancellable = device.publish()
                .stream(gravity)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let gravity = data.value
                    let orientation = self?.determineOrientation(x: gravity.x, y: gravity.y, z: gravity.z) ?? "Unknown"
                    self?.deviceOrientation = orientation
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Orientation streaming completed")
                        case .failure(let error):
                            print("🎯 Orientation error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
            orientationCancellable?.store(in: &cancellables)
        }
    }
    
    private func determineOrientation(x: Float, y: Float, z: Float) -> String {
        let absX = abs(x)
        let absY = abs(y)
        let absZ = abs(z)
        
        if absZ > absX && absZ > absY {
            return z > 0 ? "Face Up" : "Face Down"
        } else if absX > absY {
            return x > 0 ? "Right Side" : "Left Side"
        } else {
            return y > 0 ? "Portrait" : "Upside Down"
        }
    }
    
    // MARK: - Activity Recognition Methods
    
    func toggleWalkingDetection(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isWalkingDetectionActive {
            isWalkingDetectionActive = false
            isWalking = false
        } else {
            isWalkingDetectionActive = true
            device.publish()
                .stream(.stepDetector())
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.isWalking = true
                    // Reset after 2 seconds of no steps
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if self?.isWalkingDetectionActive == true {
                            self?.isWalking = false
                        }
                    }
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Walking detection streaming completed")
                        case .failure(let error):
                            print("🎯 Walking detection error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func toggleRunningDetection(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isRunningDetectionActive {
            isRunningDetectionActive = false
            isRunning = false
        } else {
            isRunningDetectionActive = true
            let accelerometer = MWAccelerometer(rate: .hz100, gravity: .g8)
            runningDetectionCancellable = device.publish()
                .stream(accelerometer)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let accel = data.value
                    let magnitude = sqrt(accel.x*accel.x + accel.y*accel.y + accel.z*accel.z) * 9.81 // Convert to m/s²
                    if magnitude > 15.0 { // High acceleration threshold
                        self?.isRunning = true
                        // Reset after 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if self?.isRunningDetectionActive == true {
                                self?.isRunning = false
                            }
                        }
                    }
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Running detection streaming completed")
                        case .failure(let error):
                            print("🎯 Running detection error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
            runningDetectionCancellable?.store(in: &cancellables)
        }
    }
    
    func toggleStationaryDetection(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isStationaryDetectionActive {
            isStationaryDetectionActive = false
            isStationary = false
        } else {
            isStationaryDetectionActive = true
            let accelerometer = MWAccelerometer(rate: .hz50, gravity: .g8)
            stationaryDetectionCancellable = device.publish()
                .stream(accelerometer)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] data in
                    let accel = data.value
                    let magnitude = sqrt(accel.x*accel.x + accel.y*accel.y + accel.z*accel.z)
                    if magnitude < 0.5 { // Low movement threshold
                        self?.isStationary = true
                        // Reset after 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if self?.isStationaryDetectionActive == true {
                                self?.isStationary = false
                            }
                        }
                    }
                })
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Stationary detection streaming completed")
                        case .failure(let error):
                            print("🎯 Stationary detection error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { _ in
                        // Data is processed in handleEvents
                    }
                )
            stationaryDetectionCancellable?.store(in: &cancellables)
        }
    }
    
    // MARK: - Data Logging Methods
    
    func toggleMotionLogging(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        if isMotionLoggingActive {
            isMotionLoggingActive = false
            // Note: stopLogging is not available in this version
            print("🎯 Motion logging stopped")
        } else {
            isMotionLoggingActive = true
            device.publish()
                .log(.sensorFusionEulerAngles(mode: .ndof))
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            print("🎯 Euler angles logging completed")
                        case .failure(let error):
                            print("🎯 Euler angles logging error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { identifier in
                        print("🎯 Motion logging started with identifier: \(identifier)")
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func downloadLogs(metawearManager: MetaWearManager) {
        guard let device = metawearManager.metawear else { return }
        
        device.publish()
            .downloadLogs(startDate: Date().addingTimeInterval(-3600)) // Last hour
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("🎯 Download completed")
                    case .failure(let error):
                        print("🎯 Download error: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] download in
                    print("🎯 Downloaded \(download.data.count) motion log entries")
                    // Here you could save to file or process the data
                    self?.processDownloadedData(download.data)
                }
            )
            .store(in: &cancellables)
    }
    
    private func processDownloadedData(_ data: [MWDataTable]) {
        // Process downloaded motion data
        for entry in data {
            print("🎯 Motion data entry: \(entry)")
        }
    }
    
    // MARK: - Utility Methods
    
    func stopAllStreaming() {
        // Cancel all individual subscriptions
        eulerCancellable?.cancel()
        quaternionCancellable?.cancel()
        gravityCancellable?.cancel()
        linearAccelCancellable?.cancel()
        accelerometerCancellable?.cancel()
        gyroscopeCancellable?.cancel()
        magnetometerCancellable?.cancel()
        stepCounterCancellable?.cancel()
        motionIntensityCancellable?.cancel()
        speedCalculationCancellable?.cancel()
        orientationCancellable?.cancel()
        walkingDetectionCancellable?.cancel()
        runningDetectionCancellable?.cancel()
        stationaryDetectionCancellable?.cancel()
        loggingCancellable?.cancel()
        
        // Clear all cancellables
        cancellables.removeAll()
        
        // Reset all individual cancellables
        eulerCancellable = nil
        quaternionCancellable = nil
        gravityCancellable = nil
        linearAccelCancellable = nil
        accelerometerCancellable = nil
        gyroscopeCancellable = nil
        magnetometerCancellable = nil
        stepCounterCancellable = nil
        motionIntensityCancellable = nil
        speedCalculationCancellable = nil
        orientationCancellable = nil
        walkingDetectionCancellable = nil
        runningDetectionCancellable = nil
        stationaryDetectionCancellable = nil
        loggingCancellable = nil
        
        // Reset all active states
        isEulerActive = false
        isQuaternionActive = false
        isGravityActive = false
        isLinearAccelActive = false
        isAccelerometerActive = false
        isGyroscopeActive = false
        isMagnetometerActive = false
        isStepCounterActive = false
        isMotionIntensityActive = false
        isSpeedCalculationActive = false
        isOrientationActive = false
        isWalkingDetectionActive = false
        isRunningDetectionActive = false
        isStationaryDetectionActive = false
        isMotionLoggingActive = false
        
        // Clear all data
        eulerAngles = ""
        quaternion = ""
        gravity = ""
        linearAcceleration = ""
        accelerometer = ""
        gyroscope = ""
        magnetometer = ""
        stepCounter = ""
        motionIntensity = ""
        calculatedSpeed = ""
        deviceOrientation = ""
        isWalking = false
        isRunning = false
        isStationary = false
        
        // Reset speed calculation state
        velocity = SIMD3<Float>(0, 0, 0)
        lastTimestamp = nil
        isMoving = false
        
        // Reset 3D visualization data
        currentQuaternion = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1))
        devicePosition = SIMD3<Float>(0, 0, 0)
        positionHistory.removeAll()
        
        print("🎯 All motion streaming stopped")
    }
} 
