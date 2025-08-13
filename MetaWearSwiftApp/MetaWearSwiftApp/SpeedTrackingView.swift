import SwiftUI
import MetaWear

struct SpeedTrackingView: View {
    @ObservedObject var speedCalculator: SpeedCalculator
    @ObservedObject var metawearManager: MetaWearManager
    @State private var throwHistory: [ThrowRecord] = []
    @State private var isThrowActive = false
    @State private var throwStartTime: Date?
    @State private var throwStartSpeed: Double = 0.0
    @State private var trackingStartTime: Date?
    @State private var isCalibrating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // Header
                VStack(spacing: 4) {
                    Text("Speed Tracker")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Real-time motion tracking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
                
                // Main Speed Display
                SpeedDisplayCard(speedCalculator: speedCalculator, metawear: metawearManager.metawear)
                
                // Simple Controls
                SimpleControlsCard(
                    speedCalculator: speedCalculator,
                    metawearManager: metawearManager,
                    isThrowActive: $isThrowActive,
                    isCalibrating: isCalibrating,
                    onThrowStart: startThrow,
                    onThrowEnd: endThrow
                )
                
                // Key Statistics
                SimpleStatsCard(
                    speedCalculator: speedCalculator,
                    throwHistory: throwHistory,
                    isThrowActive: isThrowActive
                )
                
                // Spin Rate Display
                SpinRateCard(speedCalculator: speedCalculator)
                
                // Throw History (only if there are throws)
                if !throwHistory.isEmpty {
                    SimpleThrowHistoryCard(throwHistory: throwHistory)
                }
                
                Spacer()
            }
            .padding()
        }
        .onReceive(speedCalculator.$isTracking) { isTracking in
            if !isTracking {
                // Reset calibration state when tracking stops
                trackingStartTime = nil
                isCalibrating = false
            }
        }
        .onReceive(speedCalculator.$currentSpeed) { speed in
            // Handle calibration period when tracking starts
            if speedCalculator.isTracking && trackingStartTime == nil {
                trackingStartTime = Date()
                isCalibrating = true
                print("🔄 Starting calibration period...")
            }
            
            // Check if calibration period is complete (3 seconds)
            if isCalibrating, let startTime = trackingStartTime {
                let calibrationTime = Date().timeIntervalSince(startTime)
                if calibrationTime > 3.0 {
                    isCalibrating = false
                    print("✅ Calibration complete - ready for throws")
                }
            }
            
            // Only monitor for throws after calibration is complete
            guard !isCalibrating else { return }
            
            // Monitor for throw start/end conditions
            if isThrowActive {
                // End throw if speed drops significantly
                if speed < throwStartSpeed * 0.3 {
                    endThrow()
                }
            } else if speed > 5.0 && !isThrowActive && speedCalculator.isTracking {
                // Start throw if speed exceeds threshold
                startThrow()
            }
        }
    }
    
    private func startThrow() {
        guard !isThrowActive && speedCalculator.isTracking else { return }
        
        isThrowActive = true
        throwStartTime = Date()
        throwStartSpeed = speedCalculator.currentSpeed
        
        // Start tracking detailed spin data for this throw
        speedCalculator.startSpinTracking()
        
        print("🚀 Throw started at \(speedCalculator.formattedSpeed)")
    }
    
    private func endThrow() {
        guard isThrowActive else { return }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(throwStartTime ?? endTime)
        let maxSpeed = speedCalculator.maxSpeedDuringThrow
        
        // Create throw record with comprehensive spin data
        let throwRecord = ThrowRecord(
            id: UUID(),
            startTime: throwStartTime ?? endTime,
            endTime: endTime,
            duration: duration,
            maxSpeed: maxSpeed,
            startSpeed: throwStartSpeed,
            maxSpinRate: speedCalculator.maxSpinRateDuringThrow,
            avgSpinRate: speedCalculator.avgSpinRateDuringThrow,
            spinAxisX: speedCalculator.spinAxisX,
            spinAxisY: speedCalculator.spinAxisY,
            spinAxisZ: speedCalculator.spinAxisZ,
            spinAxisDescription: speedCalculator.spinAxisDescription,
            spinDataPoints: speedCalculator.spinDataPointsDuringThrow
        )
        
        throwHistory.append(throwRecord)
        
        // Reset throw state
        isThrowActive = false
        throwStartTime = nil
        throwStartSpeed = 0.0
        speedCalculator.resetMaxSpeed()
        
        print("🏁 Throw ended - Max speed: \(String(format: "%.1f mph", maxSpeed))")
    }
}

// MARK: - Simple Controls Card
struct SimpleControlsCard: View {
    @ObservedObject var speedCalculator: SpeedCalculator
    @ObservedObject var metawearManager: MetaWearManager
    @Binding var isThrowActive: Bool
    let isCalibrating: Bool
    let onThrowStart: () -> Void
    let onThrowEnd: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // Connection Status
            HStack {
                Circle()
                    .fill(metawearManager.isConnected ? Color.green : Color.red)
                    .frame(width: 6, height: 6)
                Text(metawearManager.isConnected ? "Connected" : "Disconnected")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Start/Stop Tracking Button
            Button(action: {
                if speedCalculator.isTracking {
                    speedCalculator.stopSpeedTracking()
                } else if let device = metawearManager.metawear {
                    // Check if device is connected before starting tracking
                    if metawearManager.isConnected {
                        speedCalculator.startSpeedTracking(device: device)
                    } else {
                        // Device is not connected, show error
                        print("❌ Cannot start tracking - device not connected")
                    }
                }
            }) {
                HStack {
                    Image(systemName: speedCalculator.isTracking ? "stop.circle.fill" : "play.circle.fill")
                    Text(speedCalculator.isTracking ? "Stop Tracking" : "Start Tracking")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(speedCalculator.isTracking ? Color.red : Color.blue)
                .cornerRadius(8)
            }
            .disabled(metawearManager.metawear == nil || !metawearManager.isConnected)
            
            // Throw Controls (only show when tracking)
            if speedCalculator.isTracking {
                HStack(spacing: 10) {
                    Button(action: {
                        if isThrowActive {
                            onThrowEnd()
                        } else {
                            onThrowStart()
                        }
                    }) {
                        HStack {
                            Image(systemName: isThrowActive ? "stop.circle.fill" : "play.circle.fill")
                            Text(isThrowActive ? "End Throw" : "Start Throw")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(isThrowActive ? Color.red : Color.green)
                        .cornerRadius(6)
                    }
                    
                    Button(action: {
                        speedCalculator.resetAllSpeed()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                
                            // Status messages
            VStack(spacing: 4) {
                // Auto-detect status
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                    Text("Auto-detect enabled (5+ mph)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                // Calibration status
                if isCalibrating {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("Calibrating...")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
                
                // Connection status message
                if !metawearManager.isConnected {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption2)
                        Text("Device not connected - please connect in Connection tab")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                
                // Speed calculator status
                if !speedCalculator.status.isEmpty && speedCalculator.status != "Speed and spin tracking active" {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption2)
                        Text(speedCalculator.status)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Simple Stats Card
struct SimpleStatsCard: View {
    @ObservedObject var speedCalculator: SpeedCalculator
    let throwHistory: [ThrowRecord]
    let isThrowActive: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                Text("Statistics")
                    .font(.subheadline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                // Max Speed
                SimpleStatCard(
                    title: "Max Speed",
                    value: String(format: "%.1f mph", speedCalculator.maxSpeed),
                    icon: "speedometer",
                    color: .blue
                )
                
                // Current Throw Max
                SimpleStatCard(
                    title: "Throw Max",
                    value: isThrowActive ? String(format: "%.1f mph", speedCalculator.maxSpeedDuringThrow) : "N/A",
                    icon: "baseball",
                    color: .orange
                )
                
                // Total Throws
                SimpleStatCard(
                    title: "Total Throws",
                    value: "\(throwHistory.count)",
                    icon: "list.bullet",
                    color: .green
                )
                
                // Average Max Speed
                SimpleStatCard(
                    title: "Avg Max Speed",
                    value: averageMaxSpeed,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var averageMaxSpeed: String {
        guard !throwHistory.isEmpty else { return "N/A" }
        let average = throwHistory.map { $0.maxSpeed }.reduce(0, +) / Double(throwHistory.count)
        return String(format: "%.1f mph", average)
    }
}

// MARK: - Simple Stat Card
struct SimpleStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Spin Rate Card
struct SpinRateCard: View {
    @ObservedObject var speedCalculator: SpeedCalculator
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "rotate.3d")
                    .font(.title3)
                Text("Spin Rate")
                    .font(.subheadline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                // Current Spin Rate
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(speedCalculator.formattedSpinRate)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(speedCalculator.isTracking ? .primary : .secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Max")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f RPM", speedCalculator.maxSpinRate))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
                
                // Spin Axis
                HStack {
                    Text("Axis:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(speedCalculator.spinAxisDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                // Throw Max Spin Rate
                if speedCalculator.isTracking {
                    HStack {
                        Text("Throw Max:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f RPM", speedCalculator.maxSpinRateDuringThrow))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Simple Throw History Card
struct SimpleThrowHistoryCard: View {
    let throwHistory: [ThrowRecord]
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title3)
                Text("Recent Throws")
                    .font(.subheadline)
                Spacer()
            }
            
            ForEach(throwHistory.suffix(3).reversed(), id: \.id) { throwRecord in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Speed: \(String(format: "%.1f mph", throwRecord.maxSpeed))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("Spin: \(String(format: "%.0f RPM", throwRecord.maxSpinRate))")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        Text(throwRecord.startTime, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Axis: \(throwRecord.spinAxisDescription)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text("Duration: \(String(format: "%.1fs", throwRecord.duration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Throw Record Model
struct ThrowRecord: Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let maxSpeed: Double
    let startSpeed: Double
    
    // Spin data
    let maxSpinRate: Double
    let avgSpinRate: Double
    let spinAxisX: Double
    let spinAxisY: Double
    let spinAxisZ: Double
    let spinAxisDescription: String
    let spinDataPoints: [SpinDataPoint] // Detailed spin history during throw
}

// MARK: - Spin Data Point
struct SpinDataPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let rpm: Double
    let axisX: Double
    let axisY: Double
    let axisZ: Double
    
    init(timestamp: Date, rpm: Double, axisX: Double, axisY: Double, axisZ: Double) {
        self.id = UUID()
        self.timestamp = timestamp
        self.rpm = rpm
        self.axisX = axisX
        self.axisY = axisY
        self.axisZ = axisZ
    }
}

// MARK: - Preview
struct SpeedTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedTrackingView(
            speedCalculator: SpeedCalculator(),
            metawearManager: MetaWearManager()
        )
    }
} 