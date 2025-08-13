import SwiftUI
import MetaWear

/// High-frequency speed analysis view
/// Simple start/stop logging with speed analysis from log files
struct SpeedAnalysisView: View {
    @StateObject private var logger = HighFrequencyLogger()
    @ObservedObject var metawearManager: MetaWearManager
    @State private var analysisResults: SpeedAnalysisResults?
    @State private var isAnalyzing = false
    
    // Motion analysis results (using proper units)
    struct SpeedAnalysisResults {
        let maxSpeed: Double // mph
        let averageSpeed: Double // mph
        let maxAcceleration: Double // g's
        let averageAcceleration: Double // g's
        let duration: TimeInterval
        let sampleCount: Int
        let sampleRate: Double
        let significantMotionCount: Int
        let fileName: String
        let analysisTime: Date
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Speed Analysis")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("High-frequency logging with speed analysis")
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
                
                // Logging Status Card
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "speedometer")
                            .font(.title2)
                        Text("Logging Status")
                            .font(.headline)
                        Spacer()
                    }
                    
                    // Logging Indicator
                    HStack {
                        Circle()
                            .fill(logger.isLogging ? Color.red : Color.gray)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(logger.isLogging ? "Recording..." : "Ready")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(logger.isLogging ? .red : .gray)
                            
                            Text(logger.logStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Logging Stats
                    if logger.isLogging {
                        VStack(spacing: 8) {
                            Text("Live Statistics")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(logger.loggingStats)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
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
                        if logger.isLogging {
                            logger.stopLogging()
                            if !logger.lastLogFile.isEmpty {
                                analyzeLogFile(logger.lastLogFile)
                            }
                        } else if let device = metawearManager.metawear {
                            _ = logger.startLogging(device: device)
                        }
                    }) {
                        HStack {
                            Image(systemName: logger.isLogging ? "stop.circle.fill" : "play.circle.fill")
                            Text(logger.isLogging ? "Stop & Analyze" : "Start Logging")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(logger.isLogging ? Color.orange : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(metawearManager.metawear == nil || !metawearManager.isConnected)
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
                
                // Analysis Results
                if let results = analysisResults {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                            Text("Speed Analysis Results")
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            // Speed Results
                            VStack(spacing: 8) {
                                Text("Speed Data")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Max Speed")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.2f mph", results.maxSpeed))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("Avg Speed")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.2f mph", results.averageSpeed))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Acceleration Results
                            VStack(spacing: 8) {
                                Text("Acceleration Data")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Max Accel")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.2f g's", results.maxAcceleration))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("Avg Accel")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.2f g's", results.averageAcceleration))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Motion Events
                            VStack(spacing: 8) {
                                Text("Motion Events")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Significant Events")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(results.significantMotionCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("Event Rate")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "%.1f/sec", Double(results.significantMotionCount) / results.duration))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Session Info
                            VStack(spacing: 8) {
                                Text("Session Info")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 4) {
                                    DetailRow(label: "Duration", value: String(format: "%.2f seconds", results.duration))
                                    DetailRow(label: "Samples", value: "\(results.sampleCount)")
                                    DetailRow(label: "Sample Rate", value: String(format: "%.0f Hz", results.sampleRate))
                                    DetailRow(label: "File", value: results.fileName)
                                    DetailRow(label: "Analyzed", value: results.analysisTime.formatted(date: .omitted, time: .shortened))
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
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
                
                // Analysis Status
                if isAnalyzing {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                            Text("Analyzing Data")
                                .font(.headline)
                            Spacer()
                        }
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        
                        Text("Processing log file and calculating speed metrics...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.orange.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func analyzeLogFile(_ logPath: String) {
        isAnalyzing = true
        analysisResults = nil
        
        // Perform analysis on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let results = performSpeedAnalysis(logPath: logPath)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.analysisResults = results
                self.isAnalyzing = false
            }
        }
    }
    
    private func performSpeedAnalysis(logPath: String) -> SpeedAnalysisResults {
        // Load log file
        guard let logData = loadLogFileData(logPath) else {
            return SpeedAnalysisResults(
                maxSpeed: 0, averageSpeed: 0, maxAcceleration: 0, averageAcceleration: 0,
                duration: 0, sampleCount: 0, sampleRate: 0, significantMotionCount: 0,
                fileName: "Error", analysisTime: Date()
            )
        }
        
        // Use pre-calculated statistics from the log file
        let maxSpeed = Double(logData.maxSpeed) // Already in mph
        let averageSpeed = Double(logData.avgSpeed) // Already in mph
        let maxAcceleration = Double(logData.maxSpin) // Already in g's
        let averageAcceleration = Double(logData.avgSpin) // Already in g's
        
        return SpeedAnalysisResults(
            maxSpeed: maxSpeed,
            averageSpeed: averageSpeed,
            maxAcceleration: maxAcceleration,
            averageAcceleration: averageAcceleration,
            duration: logData.duration,
            sampleCount: logData.sampleCount,
            sampleRate: Double(logData.sampleCount) / logData.duration,
            significantMotionCount: logData.significantMotionCount,
            fileName: logData.fileName,
            analysisTime: Date()
        )
    }
    
    private func loadLogFileData(_ logPath: String) -> HighFrequencyLogger.LogFileInfo? {
        let fileName = URL(fileURLWithPath: logPath).lastPathComponent
        return logger.loadLogFile(fileName)
    }
}

// MARK: - Preview
struct SpeedAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedAnalysisView(metawearManager: MetaWearManager())
    }
} 