import SwiftUI
import Charts
import MetaWear
import Combine
import AVFoundation

struct LinearAccelerationStreamingView: View {
    @ObservedObject var metawearManager: MetaWearManager
    @StateObject private var streamingManager = LinearAccelerationStreamingManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                controlsSection
                statusSection
                if streamingManager.isStreaming {
                    chartSection
                    statisticsSection
                }
                Spacer(minLength: 50)
            }
            .padding()
        }
        .onAppear {
            streamingManager.configure(with: metawearManager)
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
                    HStack(spacing: 12) {
                        resetDataButton
                        audioToggleButton
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
            } else if let device = metawearManager.metawear, metawearManager.isConnected {
                streamingManager.startStreaming(device: device)
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
    
    private var metawearManager: MetaWearManager?
    private var cancellables = Set<AnyCancellable>()
    private var streamingStartTime: Date?
    private var timer: Timer?
    private var audioGenerator: SimpleAudioGenerator?
    
    private let maxDataPoints = 1000
    private let chartDisplayWindow = 10.0
    
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
        
        print("🟣 Starting linear acceleration streaming...")
        
        let linearAccel = MWSensorFusion.LinearAcceleration(mode: .ndof)
        
        streamingStartTime = Date()
        isStreaming = true
        resetData()
        startDurationTimer()
        
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
        
        print("🟣 Linear acceleration streaming started successfully")
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
        let acceleration = data.value
        let magnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)
        
        guard let startTime = streamingStartTime else { return }
        let relativeTime = data.time.timeIntervalSince(startTime)
        
        let dataPoint = AccelerationDataPoint(
            timestamp: data.time,
            relativeTime: relativeTime,
            acceleration: acceleration,
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
            
            // Update audio frequency if enabled
            if self.isAudioEnabled {
                self.updateAudioFrequency(magnitude: Double(magnitude))
            }
        }
    }
    
    private func updateAudioFrequency(magnitude: Double) {
        // Map magnitude (0-10g typical range) to frequency (200-2000 Hz)
        let minFreq = 200.0
        let maxFreq = 2000.0
        let normalizedMagnitude = min(magnitude / 10.0, 1.0) // Cap at 10g
        let frequency = minFreq + (normalizedMagnitude * (maxFreq - minFreq))
        
        audioGenerator?.setFrequency(frequency)
        currentAudioFrequency = String(format: "%.0f Hz", frequency)
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
    private var toneGenerator: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    private var isPlaying = false
    private var frequency: Double = 440.0 // Default A4 note
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        toneGenerator = AVAudioPlayerNode()
        
        guard let engine = audioEngine, let player = toneGenerator else { return }
        
        engine.attach(player)
        
        // Set up audio format (44.1kHz, mono)
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        
        guard let format = audioFormat else { return }
        
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    func start() {
        guard !isPlaying, let player = toneGenerator, let format = audioFormat else { return }
        
        isPlaying = true
        
        // Generate a continuous tone buffer
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * 0.1) // 100ms buffer
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        generateToneBuffer(buffer: buffer, frequency: frequency)
        
        player.scheduleBuffer(buffer, at: nil, options: .loops) {
            // Buffer completed
        }
        
        player.play()
        
        print("🔊 Audio tone started at \(frequency) Hz")
    }
    
    func stop() {
        guard isPlaying, let player = toneGenerator else { return }
        
        player.stop()
        isPlaying = false
        
        print("🔇 Audio tone stopped")
    }
    
    func setFrequency(_ newFrequency: Double) {
        guard newFrequency != frequency else { return }
        
        frequency = newFrequency
        
        // If playing, update the tone
        if isPlaying {
            stop()
            start()
        }
    }
    
    private func generateToneBuffer(buffer: AVAudioPCMBuffer, frequency: Double) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let sampleRate = buffer.format.sampleRate
        let frameCount = Int(buffer.frameLength)
        
        for frame in 0..<frameCount {
            let sampleTime = Double(frame) / sampleRate
            let sample = sin(2.0 * Double.pi * frequency * sampleTime)
            channelData[frame] = Float(sample * 0.3) // Reduced volume
        }
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