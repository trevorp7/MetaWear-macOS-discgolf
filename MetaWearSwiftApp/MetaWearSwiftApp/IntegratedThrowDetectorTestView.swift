import SwiftUI
import MetaWear

/// Test view for integrated two-tier throw detection
/// Tests Step 3: Combined motion detection + high-frequency logging
struct IntegratedThrowDetectorTestView: View {
    @StateObject private var detector = IntegratedThrowDetector()
    @ObservedObject var metawearManager: MetaWearManager
    @State private var availableLogFiles: [String] = []
    @State private var selectedLogFile: String = ""
    @State private var logFileData: HighFrequencyLogger.LogFileInfo?
    @State private var motionThreshold: Double = 0.2
    @State private var motionEndDelay: Double = 1.0
    
    // Direct observation of logger properties for better UI updates
    @State private var currentLogDuration: TimeInterval = 0.0
    @State private var currentLogFileCount: Int = 0
    @State private var currentLastLogPath: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Integrated Throw Detector")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Step 3: Test two-tier system")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Connection Status
                HStack {
                    Circle()
                        .fill(metawearManager.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(metawearManager.isConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                // System Status Card
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "gear")
                            .font(.title2)
                        Text("System Status")
                            .font(.headline)
                        Spacer()
                    }
                    
                    // Phase Indicator
                    HStack {
                        Circle()
                            .fill(phaseColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(detector.currentPhase.rawValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(phaseColor)
                            
                            Text(detector.systemStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Motion Detection Indicator
                    HStack {
                        Circle()
                            .fill(detector.motionDetected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(detector.motionDetected ? "Motion Detected" : "No Motion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    // Logging Status
                    if detector.isLogging {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            Text("Recording... \(String(format: "%.1fs", currentLogDuration))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Controls Card
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                        Text("Controls")
                            .font(.headline)
                        Spacer()
                    }
                    
                    // Start/Stop Button
                    Button(action: {
                        if detector.isActive {
                            detector.stopDetection()
                            refreshLogFiles()
                        } else if let device = metawearManager.metawear {
                            _ = detector.startDetection(device: device)
                        }
                    }) {
                        HStack {
                            Image(systemName: detector.isActive ? "stop.circle.fill" : "play.circle.fill")
                            Text(detector.isActive ? "Stop Detection" : "Start Detection")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(detector.isActive ? Color.red : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(metawearManager.metawear == nil || !metawearManager.isConnected)
                    
                    // Manual Stop Logging Button (for testing)
                    if detector.isLogging {
                        Button(action: {
                            detector.forceStopLogging()
                            refreshLogFiles()
                        }) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                Text("Force Stop Logging")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Settings
                    VStack(spacing: 12) {
                        // Motion Threshold
                        VStack(spacing: 8) {
                            HStack {
                                Text("Motion Threshold")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.2f g's", motionThreshold))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Slider(value: $motionThreshold, in: 0.05...0.5, step: 0.01) { _ in
                                detector.setMotionThreshold(motionThreshold)
                            }
                            
                            HStack {
                                Text("Sensitive")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Less Sensitive")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Motion End Delay
                        VStack(spacing: 8) {
                            HStack {
                                Text("End Delay")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1fs", motionEndDelay))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            Slider(value: $motionEndDelay, in: 0.5...3.0, step: 0.1) { _ in
                                detector.setMotionEndDelay(motionEndDelay)
                            }
                            
                            HStack {
                                Text("Quick Stop")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Longer Log")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Last Log File
                if let lastLogPath = currentLastLogPath {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.title2)
                            Text("Last Log File")
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Path: \(lastLogPath)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Duration: \(String(format: "%.2f seconds", currentLogDuration))")
                                .font(.subheadline)
                            
                            Text("Total Logs: \(currentLogFileCount)")
                                .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.green.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Log Files Card
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.title2)
                        Text("All Log Files")
                            .font(.headline)
                        Spacer()
                        
                        Button("Refresh") {
                            refreshLogFiles()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    if availableLogFiles.isEmpty {
                        Text("No log files found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(availableLogFiles, id: \.self) { fileName in
                                LogFileRow(
                                    fileName: fileName,
                                    isSelected: selectedLogFile == fileName,
                                    onTap: {
                                        selectedLogFile = fileName
                                        loadLogFileData(fileName)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Log File Details
                if let logData = logFileData {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                            Text("Log Details")
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            DetailRow(label: "File", value: logData.fileName)
                            DetailRow(label: "Path", value: getLogFilePath(logData.fileName))
                            DetailRow(label: "Duration", value: String(format: "%.2f seconds", logData.duration))
                            DetailRow(label: "Samples", value: "\(logData.sampleCount)")
                            DetailRow(label: "Sample Rate", value: String(format: "%.0f Hz", Double(logData.sampleCount) / logData.duration))
                            DetailRow(label: "Start Time", value: logData.startTime.formatted(date: .omitted, time: .shortened))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Instructions Card
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.title2)
                        Text("Test Instructions")
                        .font(.headline)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionRow(number: "1", text: "Connect MetaWear device")
                        InstructionRow(number: "2", text: "Start integrated detection")
                        InstructionRow(number: "3", text: "Move sensor (simulate throw)")
                        InstructionRow(number: "4", text: "Watch automatic logging start/stop")
                        InstructionRow(number: "5", text: "Check generated log files")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            refreshLogFiles()
            detector.refreshLogFileCount()
        }
        .onReceive(detector.$logDuration) { duration in
            currentLogDuration = duration
        }
        .onReceive(detector.$logFileCount) { count in
            currentLogFileCount = count
        }
        .onReceive(detector.$lastLogFilePath) { path in
            currentLastLogPath = path
        }
    }
    
    // MARK: - Computed Properties
    
    private var phaseColor: Color {
        switch detector.currentPhase {
        case .idle: return .gray
        case .monitoring: return .blue
        case .logging: return .red
        case .processing: return .orange
        case .ready: return .green
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshLogFiles() {
        availableLogFiles = detector.getAvailableLogFiles()
    }
    
    private func loadLogFileData(_ fileName: String) {
        logFileData = detector.loadLogFile(fileName)
    }
    
    private func getLogFilePath(_ fileName: String) -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logFilePath = documentsPath.appendingPathComponent("ThrowLogs").appendingPathComponent(fileName)
        return logFilePath.path
    }
}

// MARK: - Preview
struct IntegratedThrowDetectorTestView_Previews: PreviewProvider {
    static var previews: some View {
        IntegratedThrowDetectorTestView(metawearManager: MetaWearManager())
    }
} 