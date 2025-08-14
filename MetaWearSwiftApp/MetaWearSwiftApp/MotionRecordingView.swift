import SwiftUI
import Charts
import simd
import UniformTypeIdentifiers

// MARK: - Speed Unit Enum
enum SpeedUnit: String, CaseIterable {
    case mph = "mph"
    case kmh = "km/h"
    case ms = "m/s"
    
    var conversionFactor: Double {
        switch self {
        case .mph: return 2.237 // m/s to mph
        case .kmh: return 3.6   // m/s to km/h
        case .ms: return 1.0    // m/s to m/s
        }
    }
}

// MARK: - Motion Recording View
struct MotionRecordingView: View {
    @ObservedObject var metawearManager: MetaWearManager
    @StateObject private var recordingManager = MotionRecordingManager()
    @State private var speedUnit: SpeedUnit = .mph
    @State private var showFirst4gZoom: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Recording Controls
                recordingControlsSection
                
                // Recording Status
                recordingStatusSection
                
                // Data Analysis Section
                if let data = recordingManager.downloadedData {
                    dataAnalysisSection(data: data)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            recordingManager.configure(with: metawearManager)
        }
        .fileExporter(
            isPresented: $showingDocumentPicker,
            document: CSVDocument(content: csvToExport),
            contentType: .commaSeparatedText,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success(let url):
                print("✅ Data exported to: \(url)")
            case .failure(let error):
                print("❌ Failed to export data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("High-Frequency Motion Recording")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Record accelerometer (200Hz), gyroscope (200Hz), and magnetometer (25Hz) data during motion")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("💡 Tips: Ensure device motion during recording for best results")
                .font(.caption)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Recording Controls Section
    private var recordingControlsSection: some View {
        VStack(spacing: 16) {
            Text("Recording Controls")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Recording Presets
            HStack {
                Text("Auto-stop:")
                    .font(.subheadline)
                
                Toggle("", isOn: $recordingManager.useAutoStop)
                    .toggleStyle(SwitchToggleStyle())
                
                if recordingManager.useAutoStop {
                    Picker("Duration", selection: $recordingManager.autoStopDuration) {
                        Text("5s").tag(5.0)
                        Text("10s").tag(10.0)
                        Text("15s").tag(15.0)
                        Text("30s").tag(30.0)
                        Text("60s").tag(60.0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 200)
                }
                
                Divider().frame(height: 16)
                Text("Accel Source:")
                    .font(.subheadline)
                Picker("Accel Source", selection: $recordingManager.accelSource) {
                    Text("Linear (Fusion)").tag(MotionRecordingManager.AccelSource.linearFusion)
                    Text("Raw (400 Hz)").tag(MotionRecordingManager.AccelSource.raw)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 260)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // Start Recording Button
                Button(action: {
                    recordingManager.startRecording()
                }) {
                    HStack {
                        Image(systemName: "record.circle.fill")
                        Text("Start Recording")
                    }
                    .frame(minWidth: 150, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!recordingManager.recordingState.canStart || !metawearManager.isConnected)
                
                // Stop Recording Button
                Button(action: {
                    recordingManager.stopRecording()
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Recording")
                    }
                    .frame(minWidth: 150, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(!recordingManager.recordingState.canStop)
                
                // Download Data Button
                Button(action: {
                    recordingManager.downloadData()
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Download & Analyze")
                    }
                    .frame(minWidth: 150, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!recordingManager.recordingState.canDownload)
            }
            
            // Export and Reset Section
            HStack(spacing: 15) {
                // Export Data Button
                if let data = recordingManager.downloadedData, data.totalSamples > 0 {
                    Button(action: {
                        exportData(data: data, speedUnit: speedUnit)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export CSV")
                        }
                        .frame(minWidth: 120, minHeight: 36)
                    }
                    .buttonStyle(.bordered)
                }
                
                // Reset Button
                Button(action: {
                    recordingManager.resetRecording()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .frame(minWidth: 120, minHeight: 36)
                }
                .buttonStyle(.bordered)
                .disabled(recordingManager.recordingState.isRecording)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Recording Status Section
    private var recordingStatusSection: some View {
        VStack(spacing: 16) {
            Text("Recording Status")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Connection Status
                HStack {
                    Circle()
                        .fill(metawearManager.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text("Device Connection:")
                    Spacer()
                    Text(metawearManager.isConnected ? "Connected" : "Disconnected")
                        .fontWeight(.medium)
                        .foregroundColor(metawearManager.isConnected ? .green : .red)
                }
                
                // Recording State
                HStack {
                    Circle()
                        .fill(recordingStateColor)
                        .frame(width: 12, height: 12)
                    Text("Recording State:")
                    Spacer()
                    Text(recordingStateText)
                        .fontWeight(.medium)
                        .foregroundColor(recordingStateColor)
                }
                
                // Recording Duration
                if recordingManager.recordingState.isRecording || recordingManager.recordingDuration > 0 {
                    HStack {
                        Image(systemName: "clock")
                        Text("Recording Duration:")
                        Spacer()
                        Text(formatDuration(recordingManager.recordingDuration))
                            .fontWeight(.medium)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(recordingManager.recordingState.isRecording ? .red : .primary)
                    }
                    
                    // Auto-stop progress bar
                    if recordingManager.useAutoStop && recordingManager.recordingState.isRecording {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Auto-stop in:")
                                    .font(.caption)
                                Spacer()
                                Text(formatDuration(recordingManager.autoStopDuration - recordingManager.recordingDuration))
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            ProgressView(value: recordingManager.recordingDuration, total: recordingManager.autoStopDuration)
                                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        }
                    }
                }
                
                // Download Progress
                if case .downloading = recordingManager.recordingState {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Download Progress:")
                            Spacer()
                            Text("\(Int(recordingManager.downloadProgress * 100))%")
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: recordingManager.downloadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                // Error Display
                if let error = recordingManager.lastError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("Error:")
                        Spacer()
                    }
                    
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Data Analysis Section
    private func dataAnalysisSection(data: MotionRecordingData) -> some View {
        VStack(spacing: 20) {
            Text("Motion Analysis")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Recording Summary
            recordingSummary(data: data)
            
            // Sample Rate Information
            sampleRateInfo(data: data)
            
            // Motion Statistics
            motionStatistics(data: data)
            
            // Data Visualization Placeholder
            dataVisualizationPlaceholder(data: data)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func recordingSummary(data: MotionRecordingData) -> some View {
        VStack(spacing: 12) {
            Text("Recording Summary")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                VStack {
                    Text("\(data.totalSamples)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Samples")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text(formatDuration(data.recordingDuration))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text(DateFormatter.timeFormatter.string(from: data.recordingStartTime))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Start Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func sampleRateInfo(data: MotionRecordingData) -> some View {
        VStack(spacing: 12) {
            Text("Sample Rates")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                sampleRateRow(
                    icon: "waveform.path.ecg",
                    name: "Accelerometer",
                    samples: data.accelerometer.count,
                    rate: data.averageSampleRates.accelerometer,
                    color: .blue
                )
                
                sampleRateRow(
                    icon: "gyroscope",
                    name: "Gyroscope",
                    samples: data.gyroscope.count,
                    rate: data.averageSampleRates.gyroscope,
                    color: .green
                )
                
                sampleRateRow(
                    icon: "location.north.circle",
                    name: "Magnetometer",
                    samples: data.magnetometer.count,
                    rate: data.averageSampleRates.magnetometer,
                    color: .orange
                )
            }
        }
    }
    
    private func sampleRateRow(icon: String, name: String, samples: Int, rate: Double, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(name)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text("\(samples) samples")
                .font(.system(.body, design: .monospaced))
            
            Spacer()
            
            Text("\(String(format: "%.1f", rate)) Hz")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
    
    private func motionStatistics(data: MotionRecordingData) -> some View {
        VStack(spacing: 12) {
            Text("Motion Statistics")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                VStack {
                    Text(String(format: "%.2f", data.peakAcceleration))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Peak Acceleration (g)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack {
                    Text(String(format: "%.1f", data.peakAngularVelocity))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Peak Angular Velocity (°/s)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private func dataVisualizationPlaceholder(data: MotionRecordingData) -> some View {
        VStack(spacing: 12) {
            Text("Data Visualization")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Toggle for 4g zoom window
                HStack(spacing: 8) {
                    Toggle("Zoom to first 4g event (±0.5s)", isOn: $showFirst4gZoom)
                        .toggleStyle(SwitchToggleStyle())
                        .scaleEffect(0.9)
                    if showFirst4gZoom && first4gTimeWindow(in: data) == nil {
                        Text("No 4g event found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Real accelerometer chart
                if showFirst4gZoom, let window = first4gTimeWindow(in: data) {
                    AccelerometerChart(data: data, timeWindow: window)
                } else {
                    AccelerometerChart(data: data)
                }
                
                // Real speed chart
                SpeedChart(data: data, speedUnit: $speedUnit)
                
                // Placeholder for gyroscope chart
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title)
                                .foregroundColor(.green)
                            Text("Gyroscope Data")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Text("(\(data.gyroscope.count) samples)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
    }

    // MARK: - 4g Window Detection
    private func first4gTimeWindow(in data: MotionRecordingData) -> ClosedRange<Double>? {
        guard !data.accelerometer.isEmpty else { return nil }
        let start = data.recordingStartTime
        for sample in data.accelerometer {
            let v = sample.value
            let mag = sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
            if mag >= 4.0 {
                let t = sample.time.timeIntervalSince(start)
                // Enforce a strict 1.0s window centered on the first 4g time
                let half: Double = 0.5
                let lower = max(0.0, t - half)
                var upper = t + half
                if upper > data.recordingDuration {
                    // Shift the window left if we're near the end so it remains 1.0s wide
                    let overflow = upper - data.recordingDuration
                    let adjustedLower = max(0.0, lower - overflow)
                    upper = data.recordingDuration
                    if adjustedLower <= upper { return adjustedLower...upper }
                } else {
                    if lower <= upper { return lower...upper }
                }
                break
            }
        }
        return nil
    }
    
    // MARK: - Helper Properties
    private var recordingStateColor: Color {
        switch recordingManager.recordingState {
        case .idle, .completed:
            return .secondary
        case .preparing, .downloading:
            return .orange
        case .recording:
            return .red
        case .stopping:
            return .yellow
        case .error:
            return .red
        }
    }
    
    private var recordingStateText: String {
        switch recordingManager.recordingState {
        case .idle:
            return "Idle"
        case .preparing:
            return "Preparing..."
        case .recording:
            return "Recording"
        case .stopping:
            return "Stopping..."
        case .downloading:
            return "Downloading..."
        case .completed:
            return "Completed"
        case .error(_):
            return "Error"
        }
    }
    
    // MARK: - Helper Functions
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = duration.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%05.2f", minutes, seconds)
    }
    
    private func exportData(data: MotionRecordingData, speedUnit: SpeedUnit) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "motion_recording_\(dateFormatter.string(from: data.recordingStartTime)).csv"
        
        // Enhanced CSV with linear acceleration and speed data
        var csvContent = "Timestamp,RelativeTime,Sensor,X,Y,Z,Magnitude,SpeedX,SpeedY,SpeedZ,TotalSpeed\n"
        
        // Get speed calculations (based on linear acceleration)  
        let speeds = calculateSpeedsForExport(data: data, speedUnit: speedUnit)
        var speedIndex = 0
        
        // Add linear accelerometer data (gravity removed) with speed
        for entry in data.accelerometer {
            let magnitude = sqrt(entry.value.x * entry.value.x + entry.value.y * entry.value.y + entry.value.z * entry.value.z)
            let relativeTime = entry.time.timeIntervalSince(data.recordingStartTime)
            
            // Find corresponding speed data
            let speed = speedIndex < speeds.count ? speeds[speedIndex] : SpeedDataPoint(time: relativeTime, speedX: 0, speedY: 0, speedZ: 0, totalSpeed: 0)
            
            csvContent += "\(entry.time.timeIntervalSince1970),\(relativeTime),LinearAccelerometer,\(entry.value.x),\(entry.value.y),\(entry.value.z),\(magnitude),\(speed.speedX),\(speed.speedY),\(speed.speedZ),\(speed.totalSpeed)\n"
            speedIndex += 1
        }
        
        // Add gyroscope data
        for entry in data.gyroscope {
            let magnitude = sqrt(entry.value.x * entry.value.x + entry.value.y * entry.value.y + entry.value.z * entry.value.z)
            let relativeTime = entry.time.timeIntervalSince(data.recordingStartTime)
            csvContent += "\(entry.time.timeIntervalSince1970),\(relativeTime),Gyroscope,\(entry.value.x),\(entry.value.y),\(entry.value.z),\(magnitude),,,, \n"
        }
        
        // Add magnetometer data
        for entry in data.magnetometer {
            let magnitude = sqrt(entry.value.x * entry.value.x + entry.value.y * entry.value.y + entry.value.z * entry.value.z)
            let relativeTime = entry.time.timeIntervalSince(data.recordingStartTime)
            csvContent += "\(entry.time.timeIntervalSince1970),\(relativeTime),Magnetometer,\(entry.value.x),\(entry.value.y),\(entry.value.z),\(magnitude),,,, \n"
        }
        
        // Use document picker instead of direct Downloads access
        saveCSVWithDocumentPicker(content: csvContent, filename: filename)
    }
    
    @State private var showingDocumentPicker = false
    @State private var csvToExport = ""
    @State private var exportFilename = ""
    
    private func saveCSVWithDocumentPicker(content: String, filename: String) {
        csvToExport = content
        exportFilename = filename
        showingDocumentPicker = true
    }
    
    private func calculateSpeedsForExport(data: MotionRecordingData, speedUnit: SpeedUnit) -> [SpeedDataPoint] {
        guard !data.accelerometer.isEmpty else { return [] }
        
        var speeds: [SpeedDataPoint] = []
        let startTime = data.recordingStartTime
        
        var velocity = SIMD3<Float>(0, 0, 0)
        var lastTimestamp: Date?
        
        // Skip first 1.5 seconds to avoid sensor fusion initialization artifacts
        let skipDuration: TimeInterval = 1.5
        
        for sample in data.accelerometer {
            let timestamp = sample.time
            let timeOffset = timestamp.timeIntervalSince(startTime)
            
            // Skip initialization period
            if timeOffset < skipDuration {
                speeds.append(SpeedDataPoint(time: timeOffset, speedX: 0, speedY: 0, speedZ: 0, totalSpeed: 0))
                continue
            }
            
            guard let lastTime = lastTimestamp else {
                lastTimestamp = timestamp
                speeds.append(SpeedDataPoint(time: timeOffset, speedX: 0, speedY: 0, speedZ: 0, totalSpeed: 0))
                continue
            }
            
            let deltaTime = Float(timestamp.timeIntervalSince(lastTime))
            lastTimestamp = timestamp
            
            // Linear acceleration is already gravity-compensated by sensor fusion
            let linearAcceleration = sample.value
            
            // Convert to m/s² (SDK approach: multiply by 9.81)
            let accelerationMps2 = linearAcceleration * 9.81
            
            // SDK runningSum equivalent: integrate acceleration to get velocity
            velocity += accelerationMps2 * deltaTime
            
            // Apply aggressive stationary detection (when acceleration magnitude is very low)
            let accelerationMagnitude = simd_length(linearAcceleration)
            if accelerationMagnitude < 0.01 { // Very low threshold - essentially noise level
                velocity = SIMD3<Float>(0, 0, 0) // Complete reset when stationary
            } else if accelerationMagnitude < 0.02 {
                velocity *= 0.8 // Strong decay for low acceleration
            }
            
            // Calculate speed components and total (convert m/s to desired unit)
            let speedMps = simd_length(velocity)
            let totalSpeedInUnit = Double(speedMps) * speedUnit.conversionFactor
            
            let speedXInUnit = Double(abs(velocity.x)) * speedUnit.conversionFactor  
            let speedYInUnit = Double(abs(velocity.y)) * speedUnit.conversionFactor
            let speedZInUnit = Double(abs(velocity.z)) * speedUnit.conversionFactor
            
            speeds.append(SpeedDataPoint(
                time: timeOffset,
                speedX: speedXInUnit,
                speedY: speedYInUnit, 
                speedZ: speedZInUnit,
                totalSpeed: totalSpeedInUnit
            ))
        }
        
        return speeds
    }
}

// MARK: - CSV Document
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var content: String
    
    init(content: String = "") {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}

// MARK: - Accelerometer Chart
struct AccelerometerChart: View {
    let data: MotionRecordingData
    let timeWindow: ClosedRange<Double>?
    @State private var selectedAxis: AxisSelection = .all
    @State private var showMagnitude = true
    
    enum AxisSelection: String, CaseIterable {
        case all = "All"
        case x = "X-Axis"
        case y = "Y-Axis" 
        case z = "Z-Axis"
        case magnitude = "Magnitude"
    }
    
    init(data: MotionRecordingData, timeWindow: ClosedRange<Double>? = nil) {
        self.data = data
        self.timeWindow = timeWindow
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Chart header with controls
            HStack {
                Text("Accelerometer (g)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Axis", selection: $selectedAxis) {
                    ForEach(AxisSelection.allCases, id: \.self) { axis in
                        Text(axis.rawValue).tag(axis)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 250)
            }
            
            // Chart
            Chart {
                ForEach(chartData, id: \.id) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Acceleration", point.value)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                    .lineStyle(StrokeStyle(lineWidth: point.lineWidth))
                }
                if let center = centerTime {
                    RuleMark(x: .value("4g Event", center))
                        .foregroundStyle(Color.gray)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4,4]))
                }
            }
            .chartForegroundStyleScale([
                "X-Axis": .red,
                "Y-Axis": .green,
                "Z-Axis": .blue,
                "Magnitude": .purple
            ])
            .frame(height: timeWindow != nil ? 240 : 200)
            .chartXAxis {
                AxisMarks(values: timeWindow != nil ? .stride(by: 0.1) : .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let t: Double = value.as(Double.self) {
                            if let c = centerTime {
                                Text(String(format: "% .2fs", t - c))
                            } else {
                                Text(String(format: "%.2fs", t))
                            }
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXScale(domain: xAxisRange)
            .chartYScale(domain: yAxisRange)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            
            // Chart legend
            if selectedAxis == .all {
                HStack(spacing: 16) {
                    LegendItem(color: .red, label: "X-Axis")
                    LegendItem(color: .green, label: "Y-Axis")
                    LegendItem(color: .blue, label: "Z-Axis")
                    if showMagnitude {
                        LegendItem(color: .purple, label: "Magnitude")
                    }
                }
                .font(.caption)
            }
            
            // Stats summary
            VStack(spacing: 4) {
                Text("Chart Statistics")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    StatItem(label: "Samples", value: "\(data.accelerometer.count)")
                    StatItem(label: "Duration", value: String(format: "%.2fs", data.recordingDuration))
                    StatItem(label: "Max G", value: String(format: "%.2f", data.peakAcceleration))
                    StatItem(label: "Rate", value: String(format: "%.1f Hz", data.averageSampleRates.accelerometer))
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Chart Data Processing
    private var filteredAccelerometer: [(time: Double, value: SIMD3<Float>)] {
        let start = data.recordingStartTime
        return data.accelerometer.compactMap { sample in
            let t = sample.time.timeIntervalSince(start)
            if let w = timeWindow, (t < w.lowerBound || t > w.upperBound) { return nil }
            return (t, sample.value)
        }
    }

    private var xAxisRange: ClosedRange<Double> {
        if let w = timeWindow { return w }
        guard let first = filteredAccelerometer.first?.time, let last = filteredAccelerometer.last?.time else {
            return 0...max(1, data.recordingDuration)
        }
        return first...last
    }

    private var centerTime: Double? {
        guard let w = timeWindow else { return nil }
        return (w.lowerBound + w.upperBound) / 2.0
    }

    private var chartData: [ChartDataPoint] {
        var points: [ChartDataPoint] = []

        for (index, sample) in filteredAccelerometer.enumerated() {
            let timeOffset = sample.time
            let id = "accel_\(index)"

            switch selectedAxis {
            case .all:
                points.append(ChartDataPoint(id: "\(id)_x", series: "X-Axis", time: timeOffset, value: sample.value.x, color: .red, lineWidth: 1.5))
                points.append(ChartDataPoint(id: "\(id)_y", series: "Y-Axis", time: timeOffset, value: sample.value.y, color: .green, lineWidth: 1.5))
                points.append(ChartDataPoint(id: "\(id)_z", series: "Z-Axis", time: timeOffset, value: sample.value.z, color: .blue, lineWidth: 1.5))
                if showMagnitude {
                    let m = sqrt(sample.value.x * sample.value.x + sample.value.y * sample.value.y + sample.value.z * sample.value.z)
                    points.append(ChartDataPoint(id: "\(id)_mag", series: "Magnitude", time: timeOffset, value: m, color: .purple, lineWidth: 2.0))
                }
            case .x:
                points.append(ChartDataPoint(id: id, series: "X-Axis", time: timeOffset, value: sample.value.x, color: .red, lineWidth: 2.0))
            case .y:
                points.append(ChartDataPoint(id: id, series: "Y-Axis", time: timeOffset, value: sample.value.y, color: .green, lineWidth: 2.0))
            case .z:
                points.append(ChartDataPoint(id: id, series: "Z-Axis", time: timeOffset, value: sample.value.z, color: .blue, lineWidth: 2.0))
            case .magnitude:
                let m = sqrt(sample.value.x * sample.value.x + sample.value.y * sample.value.y + sample.value.z * sample.value.z)
                points.append(ChartDataPoint(id: id, series: "Magnitude", time: timeOffset, value: m, color: .purple, lineWidth: 2.0))
            }
        }

        return points
    }

    private var yAxisRange: ClosedRange<Double> {
        var maxG: Double = 0
        for sample in filteredAccelerometer {
            switch selectedAxis {
            case .x:
                maxG = max(maxG, Double(abs(sample.value.x)))
            case .y:
                maxG = max(maxG, Double(abs(sample.value.y)))
            case .z:
                maxG = max(maxG, Double(abs(sample.value.z)))
            case .magnitude, .all:
                let m = sqrt(sample.value.x * sample.value.x + sample.value.y * sample.value.y + sample.value.z * sample.value.z)
                maxG = max(maxG, Double(m))
            }
        }
        if maxG == 0 { return -1...1 }
        let padding = max(0.2, maxG * 0.1)
        return (-maxG - padding)...(maxG + padding)
    }
}

// MARK: - Speed Chart
struct SpeedChart: View {
    let data: MotionRecordingData
    @Binding var speedUnit: SpeedUnit
    @State private var showComponents = false
    
    
    var body: some View {
        VStack(spacing: 12) {
            // Chart header with controls
            HStack {
                Text("Speed (\(speedUnit.rawValue))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Toggle("Components", isOn: $showComponents)
                        .toggleStyle(SwitchToggleStyle())
                        .scaleEffect(0.8)
                    
                    Picker("Unit", selection: $speedUnit) {
                        ForEach(SpeedUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 150)
                }
            }
            
            // Chart
            Chart {
                ForEach(speedChartPoints, id: \.id) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Speed", point.value)
                    )
                    .foregroundStyle(point.color)
                    .lineStyle(StrokeStyle(lineWidth: point.lineWidth))
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.second(.defaultDigits))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: speedYAxisRange)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            
            // Chart legend
            if showComponents {
                HStack(spacing: 16) {
                    LegendItem(color: .red, label: "X-Speed")
                    LegendItem(color: .green, label: "Y-Speed")
                    LegendItem(color: .blue, label: "Z-Speed")
                    LegendItem(color: .orange, label: "Total Speed")
                }
                .font(.caption)
            }
            
            // Speed statistics
            VStack(spacing: 4) {
                Text("Speed Statistics")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    StatItem(label: "Max Speed", value: String(format: "%.1f", maxSpeed))
                    StatItem(label: "Avg Speed", value: String(format: "%.1f", avgSpeed))
                    StatItem(label: "Peak Time", value: String(format: "%.2fs", peakSpeedTime))
                    StatItem(label: "Unit", value: speedUnit.rawValue)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Use backend-provided speed and velocity
    private var speedChartPoints: [ChartDataPoint] {
        let start = data.recordingStartTime
        let factor = Float(speedUnit.conversionFactor)
        var points: [ChartDataPoint] = []
        if showComponents {
            for (i, v) in data.velocity.enumerated() {
                let t = v.time.timeIntervalSince(start)
                let id = "vel_\(i)"
                points.append(ChartDataPoint(id: "\(id)_x", series: "X-Speed", time: t, value: abs(v.value.x) * factor, color: .red, lineWidth: 1.5))
                points.append(ChartDataPoint(id: "\(id)_y", series: "Y-Speed", time: t, value: abs(v.value.y) * factor, color: .green, lineWidth: 1.5))
                points.append(ChartDataPoint(id: "\(id)_z", series: "Z-Speed", time: t, value: abs(v.value.z) * factor, color: .blue, lineWidth: 1.5))
            }
        }
        for (i, s) in data.speed.enumerated() {
            let t = s.time.timeIntervalSince(start)
            points.append(ChartDataPoint(id: "speedTotal_\(i)", series: "Total Speed", time: t, value: s.value * factor, color: .orange, lineWidth: 2.0))
        }
        return points
    }

    private var speedYAxisRange: ClosedRange<Double> {
        let factor = speedUnit.conversionFactor
        var maxVal: Double = 0
        if showComponents {
            for v in data.velocity {
                maxVal = max(maxVal, Double(abs(v.value.x)) * factor)
                maxVal = max(maxVal, Double(abs(v.value.y)) * factor)
                maxVal = max(maxVal, Double(abs(v.value.z)) * factor)
            }
        }
        for s in data.speed {
            maxVal = max(maxVal, Double(s.value) * factor)
        }
        if maxVal == 0 { return 0...10 }
        return 0...(maxVal * 1.1)
    }

    private var maxSpeed: Double {
        let factor = speedUnit.conversionFactor
        return data.speed.map { Double($0.value) * factor }.max() ?? 0
    }

    private var avgSpeed: Double {
        let factor = speedUnit.conversionFactor
        guard !data.speed.isEmpty else { return 0 }
        let total = data.speed.map { Double($0.value) * factor }.reduce(0, +)
        return total / Double(data.speed.count)
    }

    private var peakSpeedTime: Double {
        let factor = speedUnit.conversionFactor
        guard let maxVal = data.speed.map({ Double($0.value) * factor }).max() else { return 0 }
        let start = data.recordingStartTime
        return data.speed.first(where: { Double($0.value) * factor == maxVal })?.time.timeIntervalSince(start) ?? 0
    }
}

// MARK: - Speed Data Model
struct SpeedDataPoint {
    let time: TimeInterval
    let speedX: Double
    let speedY: Double
    let speedZ: Double
    let totalSpeed: Double
}

// MARK: - Chart Data Model
struct ChartDataPoint {
    let id: String
    let series: String
    let time: TimeInterval
    let value: Float
    let color: Color
    let lineWidth: Double
}

// MARK: - Helper Views
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 2)
            Text(label)
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .fontWeight(.medium)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
struct MotionRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        MotionRecordingView(metawearManager: MetaWearManager())
            .frame(width: 800, height: 900)
    }
}
