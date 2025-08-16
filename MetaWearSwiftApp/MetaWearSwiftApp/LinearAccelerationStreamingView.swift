import SwiftUI
import Charts
import MetaWear
import Combine
import AVFoundation

struct LinearAccelerationStreamingView: View {
    @ObservedObject var metawearManager: MetaWearManager
    @StateObject private var streamingManager = LinearAccelerationStreamingManager()
    @StateObject private var speedCalculator = SpeedCalculator()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                controlsSection
                statusSection
                if streamingManager.isStreaming {
                    statisticsSection
                }
                Spacer(minLength: 50)
            }
            .padding()
        }
        .onAppear {
            streamingManager.configure(with: metawearManager)
        }
        .onReceive(speedCalculator.$currentSpeed) { speed in
            // Update audio based on SpeedCalculator speed (already in mph)
            if streamingManager.isAudioEnabled {
                let now = Date()
                if now.timeIntervalSince(streamingManager.lastAudioUpdate) >= streamingManager.audioUpdateInterval {
                    streamingManager.updateAudioFrequencyForSpeed(rawSpeed: speed)
                    streamingManager.lastAudioUpdate = now
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            
            Text("Linear Acceleration Streaming")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Real-time linear acceleration data with gravity compensation")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("📊 Live data visualization at 100Hz")
                .font(.caption)
                .foregroundColor(.purple)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            Text("Streaming Controls")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                connectionStatusRow
                streamingControlButton
                if streamingManager.isStreaming {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            resetDataButton
                            audioToggleButton
                        }
                        
                        filterControlSlider
                        
                        if streamingManager.isAudioEnabled {
                            audioSmoothingSlider
                            audioSensitivitySlider
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var connectionStatusRow: some View {
        HStack {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundColor(metawearManager.isConnected ? .green : .red)
            Text("Connection Status:")
                .font(.subheadline)
            Text(metawearManager.isConnected ? "Connected" : "Disconnected")
                .fontWeight(.semibold)
                .foregroundColor(metawearManager.isConnected ? .green : .red)
            Spacer()
        }
    }
    
    private var streamingControlButton: some View {
        Button(action: {
            if streamingManager.isStreaming {
                streamingManager.stopStreaming()
                speedCalculator.stopSpeedTracking()
            } else if let device = metawearManager.metawear, metawearManager.isConnected {
                streamingManager.startStreaming(device: device)
                speedCalculator.startSpeedTracking(device: device)
            }
        }) {
            HStack {
                Image(systemName: streamingManager.isStreaming ? "stop.circle.fill" : "play.circle.fill")
                Text(streamingManager.isStreaming ? "Stop Streaming" : "Start Streaming")
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(streamingManager.isStreaming ? Color.red : Color.purple)
            .cornerRadius(10)
        }
        .disabled(!metawearManager.isConnected || metawearManager.metawear == nil)
    }
    
    private var resetDataButton: some View {
        Button(action: {
            streamingManager.resetData()
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Reset Data")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var audioToggleButton: some View {
        Button(action: {
            streamingManager.toggleAudio()
        }) {
            HStack {
                Image(systemName: streamingManager.isAudioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                Text(streamingManager.isAudioEnabled ? "Audio On" : "Audio Off")
            }
            .font(.subheadline)
            .foregroundColor(streamingManager.isAudioEnabled ? .white : .orange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(streamingManager.isAudioEnabled ? Color.orange : Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var filterControlSlider: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "waveform.path")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("Data Smoothing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(streamingManager.filterStrength * 100))%")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            }
            
            Slider(value: $streamingManager.filterStrength, in: 0...0.95) {
                Text("Data Smoothing")
            }
            .accentColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var audioSmoothingSlider: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "speaker.wave.2")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("Audio Smoothing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(streamingManager.audioSmoothingStrength * 100))%")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
            }
            
            Slider(value: $streamingManager.audioSmoothingStrength, in: 0...0.98) {
                Text("Audio Smoothing")
            }
            .accentColor(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var audioSensitivitySlider: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Speed Sensitivity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(streamingManager.audioSensitivity, specifier: "%.1f") mph")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            }
            
            Slider(value: $streamingManager.audioSensitivity, in: 0.5...3.0) {
                Text("Speed Threshold")
            }
            .accentColor(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            Text("Stream Status")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                statusRow(icon: "waveform", title: "Streaming", value: streamingManager.isStreaming ? "Active" : "Inactive", color: streamingManager.isStreaming ? .green : .gray)
                statusRow(icon: "number", title: "Data Points", value: "\(streamingManager.dataPoints.count)", color: .blue)
                statusRow(icon: "clock", title: "Duration", value: streamingManager.streamingDuration, color: .orange)
                statusRow(icon: "speedometer", title: "Rate", value: "100 Hz", color: .purple)
                if streamingManager.isAudioEnabled {
                    statusRow(icon: "speaker.wave.2", title: "Audio Freq", value: streamingManager.currentAudioFrequency, color: .orange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private func statusRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    
    private var chartSection: some View {
        VStack(spacing: 16) {
            Text("Real-Time Data")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 20) {
                accelerationChart
                magnitudeChart
            }
        }
    }
    
    private var accelerationChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Linear Acceleration (X, Y, Z)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(streamingManager.recentDataPoints, id: \.timestamp) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.relativeTime),
                        y: .value("X Acceleration", dataPoint.acceleration.x)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    LineMark(
                        x: .value("Time", dataPoint.relativeTime),
                        y: .value("Y Acceleration", dataPoint.acceleration.y)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    LineMark(
                        x: .value("Time", dataPoint.relativeTime),
                        y: .value("Z Acceleration", dataPoint.acceleration.z)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel() {
                        if let time = value.as(Double.self) {
                            Text("\(time, specifier: "%.1f")s")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel() {
                        if let accel = value.as(Double.self) {
                            Text("\(accel, specifier: "%.1f")g")
                        }
                    }
                }
            }
            .chartYScale(domain: -5...5)
            .chartLegend(position: .bottom) {
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.red)
                            .frame(width: 12, height: 2)
                        Text("X")
                            .font(.caption)
                    }
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.green)
                            .frame(width: 12, height: 2)
                        Text("Y")
                            .font(.caption)
                    }
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.blue)
                            .frame(width: 12, height: 2)
                        Text("Z")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var magnitudeChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Acceleration Magnitude")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(streamingManager.recentDataPoints, id: \.timestamp) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.relativeTime),
                        y: .value("Magnitude", dataPoint.magnitude)
                    )
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel() {
                        if let time = value.as(Double.self) {
                            Text("\(time, specifier: "%.1f")s")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel() {
                        if let mag = value.as(Double.self) {
                            Text("\(mag, specifier: "%.1f")g")
                        }
                    }
                }
            }
            .chartYScale(domain: 0...10)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Live Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Current Magnitude",
                    value: String(format: "%.2f g", streamingManager.currentMagnitude),
                    icon: "speedometer",
                    color: .purple
                )
                
                StatCard(
                    title: "Max Magnitude",
                    value: String(format: "%.2f g", streamingManager.maxMagnitude),
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Current Speed",
                    value: String(format: "%.1f mph", speedCalculator.currentSpeed),
                    icon: "speedometer",
                    color: .green
                )
                
                StatCard(
                    title: "Max Speed",
                    value: String(format: "%.1f mph", speedCalculator.maxSpeed),
                    icon: "arrow.up.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Avg Magnitude",
                    value: String(format: "%.2f g", streamingManager.averageMagnitude),
                    icon: "chart.bar.fill",
                    color: .blue
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

class LinearAccelerationStreamingManager: ObservableObject {
    @Published var isStreaming = false
    @Published var dataPoints: [AccelerationDataPoint] = []
    @Published var currentMagnitude: Double = 0.0
    @Published var maxMagnitude: Double = 0.0
    @Published var averageMagnitude: Double = 0.0
    @Published var streamingDuration: String = "0s"
    @Published var isAudioEnabled = false
    @Published var currentAudioFrequency: String = "440 Hz"
    @Published var filterStrength: Double = 0.6  // More aggressive default
    @Published var audioSmoothingStrength: Double = 0.8  // Audio-specific smoothing
    @Published var audioSensitivity: Double = 1.0  // Threshold for audio activation (in mph)
    
    private var metawearManager: MetaWearManager?
    private var cancellables = Set<AnyCancellable>()
    private var streamingStartTime: Date?
    private var timer: Timer?
    private var audioGenerator: SimpleAudioGenerator?
    
    private let maxDataPoints = 1000
    private let chartDisplayWindow = 10.0
    
    // Filtering  
    private var rawDataBuffer: [SIMD3<Float>] = []
    private let filterWindowSize = 10  // Larger window for more smoothing
    
    // Audio throttling and smoothing
    var lastAudioUpdate = Date()
    let audioUpdateInterval = 0.033 // ~30Hz update rate for better reactivity
    private var smoothedAudioMagnitude: Double = 0.0
    private var smoothedSpeed: Double = 0.0
    
    
    var recentDataPoints: [AccelerationDataPoint] {
        guard let startTime = streamingStartTime else { return [] }
        let currentTime = Date().timeIntervalSince(startTime)
        let windowStart = max(0, currentTime - chartDisplayWindow)
        
        return dataPoints.filter { dataPoint in
            dataPoint.relativeTime >= windowStart
        }
    }
    
    
    func configure(with manager: MetaWearManager) {
        self.metawearManager = manager
        setupAudio()
    }
    
    func toggleAudio() {
        isAudioEnabled.toggle()
        if isAudioEnabled {
            audioGenerator?.start()
        } else {
            audioGenerator?.stop()
        }
    }
    
    private func setupAudio() {
        audioGenerator = SimpleAudioGenerator()
    }
    
    func startStreaming(device: MetaWear) {
        guard !isStreaming else { return }
        
        print("🟣 Starting linear acceleration and speed streaming...")
        
        let linearAccel = MWSensorFusion.LinearAcceleration(mode: .ndof)
        
        streamingStartTime = Date()
        isStreaming = true
        resetData()
        startDurationTimer()
        
        // Stream linear acceleration for display
        device.publish()
            .stream(linearAccel)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        print("🟣 Linear acceleration streaming completed")
                    case .failure(let error):
                        print("❌ Linear acceleration streaming error: \(error)")
                        DispatchQueue.main.async {
                            self?.stopStreaming()
                        }
                    }
                },
                receiveValue: { [weak self] data in
                    self?.processAccelerationData(data)
                }
            )
            .store(in: &cancellables)
        
        
        print("🟣 Linear acceleration and speed streaming started successfully")
    }
    
    func stopStreaming() {
        guard isStreaming else { return }
        
        print("🟣 Stopping linear acceleration streaming...")
        
        cancellables.removeAll()
        isStreaming = false
        timer?.invalidate()
        timer = nil
        
        // Stop audio when streaming stops
        if isAudioEnabled {
            audioGenerator?.stop()
            isAudioEnabled = false
        }
        
        print("🟣 Linear acceleration streaming stopped")
    }
    
    func resetData() {
        dataPoints.removeAll()
        currentMagnitude = 0.0
        maxMagnitude = 0.0
        averageMagnitude = 0.0
        streamingStartTime = Date()
        rawDataBuffer.removeAll() // Clear filter buffer
        smoothedAudioMagnitude = 0.0 // Reset audio smoothing
    }
    
    private func startDurationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
    }
    
    private func updateDuration() {
        guard let startTime = streamingStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        
        DispatchQueue.main.async {
            if duration < 60 {
                self.streamingDuration = String(format: "%.0fs", duration)
            } else {
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                self.streamingDuration = String(format: "%dm %ds", minutes, seconds)
            }
        }
    }
    
    private func processAccelerationData(_ data: Timestamped<SIMD3<Float>>) {
        let rawAcceleration = data.value
        
        // Apply filtering
        let filteredAcceleration = applyFilter(rawAcceleration)
        let magnitude = sqrt(filteredAcceleration.x * filteredAcceleration.x + filteredAcceleration.y * filteredAcceleration.y + filteredAcceleration.z * filteredAcceleration.z)
        
        guard let startTime = streamingStartTime else { return }
        let relativeTime = data.time.timeIntervalSince(startTime)
        
        let dataPoint = AccelerationDataPoint(
            timestamp: data.time,
            relativeTime: relativeTime,
            acceleration: filteredAcceleration,
            magnitude: Double(magnitude)
        )
        
        DispatchQueue.main.async {
            self.dataPoints.append(dataPoint)
            
            if self.dataPoints.count > self.maxDataPoints {
                self.dataPoints.removeFirst(self.dataPoints.count - self.maxDataPoints)
            }
            
            self.currentMagnitude = Double(magnitude)
            self.maxMagnitude = max(self.maxMagnitude, Double(magnitude))
            
            if !self.dataPoints.isEmpty {
                self.averageMagnitude = self.dataPoints.map { $0.magnitude }.reduce(0, +) / Double(self.dataPoints.count)
            }
        }
    }
    
    
    private func updateAudioFrequency(rawMagnitude: Double) {
        // Apply heavy smoothing specifically for audio
        smoothedAudioMagnitude = smoothedAudioMagnitude * audioSmoothingStrength + rawMagnitude * (1.0 - audioSmoothingStrength)
        
        // Mute below threshold - no hiss until crossing threshold
        guard smoothedAudioMagnitude > audioSensitivity else {
            audioGenerator?.setVolume(0.0)
            currentAudioFrequency = "0 Hz"
            return
        }
        
        let adjustedMagnitude = smoothedAudioMagnitude - audioSensitivity
        
        // Focus on 0.2-3g primary range (most activity happens here)
        let primaryRange = 3.0 - audioSensitivity
        let normalizedMagnitude = min(adjustedMagnitude / primaryRange, 1.0)
        
        // Wind-like frequency range - lower and more natural
        let minFreq = 100.0
        let maxFreq = 600.0
        let frequency = minFreq + (normalizedMagnitude * (maxFreq - minFreq))
        
        // Gradual volume mapping for wind effect
        let minVolume = 0.01
        let maxVolume = 0.06
        let volume = minVolume + (normalizedMagnitude * (maxVolume - minVolume))
        
        audioGenerator?.setFrequency(frequency)
        audioGenerator?.setVolume(volume)
        currentAudioFrequency = String(format: "%.0f Hz", frequency)
    }
    
    func updateAudioFrequencyForSpeed(rawSpeed: Double) {
        // Apply heavy smoothing specifically for audio
        smoothedSpeed = smoothedSpeed * audioSmoothingStrength + rawSpeed * (1.0 - audioSmoothingStrength)
        
        // Use adjustable threshold (audioSensitivity is now speed threshold in mph)
        let speedThreshold = audioSensitivity
        
        // Mute below threshold - no sound until moving
        guard smoothedSpeed > speedThreshold else {
            audioGenerator?.setVolume(0.0)
            currentAudioFrequency = "0 Hz"
            return
        }
        
        let adjustedSpeed = smoothedSpeed - speedThreshold
        
        // Focus on threshold to 15 mph range
        let primaryRange = 15.0 - speedThreshold
        let normalizedSpeed = min(adjustedSpeed / primaryRange, 1.0)
        
        // Apply exponential curve for more sensitivity at lower speeds
        // Using square root gives more response at lower speeds without being too aggressive
        let exponentialSpeed = sqrt(normalizedSpeed)
        
        // Wind-like frequency range for speed
        let minFreq = 80.0
        let maxFreq = 500.0
        let frequency = minFreq + (exponentialSpeed * (maxFreq - minFreq))
        
        // Volume mapping for speed (also using exponential curve)
        let minVolume = 0.015
        let maxVolume = 0.08
        let volume = minVolume + (exponentialSpeed * (maxVolume - minVolume))
        
        audioGenerator?.setFrequency(frequency)
        audioGenerator?.setVolume(volume)
        currentAudioFrequency = String(format: "%.0f Hz", frequency)
    }
    
    private func applyFilter(_ newValue: SIMD3<Float>) -> SIMD3<Float> {
        // Add new value to buffer
        rawDataBuffer.append(newValue)
        
        // Keep only the last N values for moving average
        if rawDataBuffer.count > filterWindowSize {
            rawDataBuffer.removeFirst()
        }
        
        // Apply exponential moving average for smoother results
        if rawDataBuffer.count == 1 {
            return newValue // First value, no filtering needed
        }
        
        // Calculate moving average
        let sum = rawDataBuffer.reduce(SIMD3<Float>(0, 0, 0)) { result, value in
            return result + value
        }
        let movingAverage = sum / Float(rawDataBuffer.count)
        
        // Blend with exponential smoothing based on filter strength
        let alpha = Float(1.0 - filterStrength) // Higher filterStrength = more smoothing
        return alpha * newValue + (1.0 - alpha) * movingAverage
    }
}

struct AccelerationDataPoint {
    let timestamp: Date
    let relativeTime: TimeInterval
    let acceleration: SIMD3<Float>
    let magnitude: Double
}


class SimpleAudioGenerator {
    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var isPlaying = false
    private var targetFrequency: Double = 440.0
    private var currentFrequency: Double = 440.0
    private var targetVolume: Double = 0.003
    private var currentVolume: Double = 0.003
    private var phase: Double = 0.0
    private var sampleRate: Double = 44100.0
    private let frequencySmoothing: Double = 0.98 // Less aggressive for better reactivity
    private let volumeSmoothing: Double = 0.95 // Less aggressive for better reactivity
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine else { return }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Create a source node for continuous audio generation
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self, self.isPlaying else {
                // Fill with silence when not playing
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for buffer in ablPointer {
                    memset(buffer.mData, 0, Int(buffer.mDataByteSize))
                }
                return noErr
            }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            for frame in 0..<Int(frameCount) {
                // Smooth frequency and volume transitions
                self.currentFrequency = self.currentFrequency * self.frequencySmoothing + self.targetFrequency * (1.0 - self.frequencySmoothing)
                self.currentVolume = self.currentVolume * self.volumeSmoothing + self.targetVolume * (1.0 - self.volumeSmoothing)
                
                // Generate wind-like sample (sine + noise for texture)
                let sineSample = sin(2.0 * Double.pi * self.phase)
                let noiseSample = (Double.random(in: -1...1)) * 0.3  // Low-level noise
                let sample = sineSample * 0.7 + noiseSample * 0.3    // Blend sine + noise for wind effect
                let scaledSample = Float(sample * self.currentVolume)
                
                // Write to all channels
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = scaledSample
                }
                
                // Update phase correctly to maintain continuity
                let phaseIncrement = self.currentFrequency / self.sampleRate
                self.phase += phaseIncrement
                if self.phase >= 1.0 {
                    self.phase -= 1.0
                }
            }
            
            return noErr
        }
        
        guard let source = sourceNode else { return }
        
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        phase = 0.0 // Reset phase
        currentFrequency = targetFrequency
        currentVolume = targetVolume
        print("🔊 Continuous audio tone started at \(targetFrequency) Hz")
    }
    
    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        print("🔇 Continuous audio tone stopped")
    }
    
    func setFrequency(_ newFrequency: Double) {
        // Set target frequency for smooth transitions with safety bounds
        targetFrequency = max(50.0, min(2000.0, newFrequency))
    }
    
    func setVolume(_ newVolume: Double) {
        // Set target volume for smooth transitions with safety bounds
        targetVolume = max(0.001, min(0.1, newVolume))
    }
    
    deinit {
        stop()
        audioEngine?.stop()
    }
}

struct LinearAccelerationStreamingView_Previews: PreviewProvider {
    static var previews: some View {
        LinearAccelerationStreamingView(metawearManager: MetaWearManager())
    }
}