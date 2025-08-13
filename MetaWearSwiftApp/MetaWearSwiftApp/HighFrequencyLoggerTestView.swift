import SwiftUI
import MetaWear

/// Test view for high-frequency logging
/// Tests Step 2: High-frequency data collection
struct HighFrequencyLoggerTestView: View {
    @StateObject private var logger = HighFrequencyLogger()
    @ObservedObject var metawearManager: MetaWearManager
    @State private var availableLogFiles: [String] = []
    @State private var selectedLogFile: String = ""
    @State private var logFileData: HighFrequencyLogger.LogFileInfo?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("High-Frequency Logger Test")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Step 2: Test high-frequency data logging")
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
                
                // Logger Status Card
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "record.circle")
                            .font(.title2)
                        Text("Logger Status")
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
                                refreshLogFiles()
                            }
                        } else if let device = metawearManager.metawear {
                            _ = logger.startLogging(device: device)
                        }
                    }) {
                        HStack {
                            Image(systemName: logger.isLogging ? "stop.circle.fill" : "play.circle.fill")
                            Text(logger.isLogging ? "Stop Logging" : "Start Logging")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(logger.isLogging ? Color.red : Color.blue)
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
                
                // Log Files Card
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.title2)
                        Text("Log Files")
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
                        InstructionRow(number: "2", text: "Start high-frequency logging")
                        InstructionRow(number: "3", text: "Move sensor around (simulate throw)")
                        InstructionRow(number: "4", text: "Stop logging after a few seconds")
                        InstructionRow(number: "5", text: "Check log file details")
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
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshLogFiles() {
        availableLogFiles = logger.getAvailableLogFiles()
    }
    
    private func loadLogFileData(_ fileName: String) {
        logFileData = logger.loadLogFile(fileName)
    }
}

// MARK: - Log File Row
struct LogFileRow: View {
    let fileName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Tap to view details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct HighFrequencyLoggerTestView_Previews: PreviewProvider {
    static var previews: some View {
        HighFrequencyLoggerTestView(metawearManager: MetaWearManager())
    }
} 