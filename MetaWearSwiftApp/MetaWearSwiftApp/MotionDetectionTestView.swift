import SwiftUI
import MetaWear

/// Simple test view for motion detection
/// Tests Step 1: Streaming motion detection
struct MotionDetectionTestView: View {
    @StateObject private var motionDetector = MotionDetector()
    @ObservedObject var metawearManager: MetaWearManager
    @State private var threshold: Double = 0.1
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Motion Detection Test")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Step 1: Test streaming motion detection")
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
                
                // Motion Status Card
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .font(.title2)
                        Text("Motion Status")
                            .font(.headline)
                        Spacer()
                    }
                    
                    // Motion Indicator
                    HStack {
                        Circle()
                            .fill(motionDetector.isMotionDetected ? Color.green : Color.red)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(motionDetector.isMotionDetected ? "Motion Detected!" : "No Motion")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(motionDetector.isMotionDetected ? .green : .red)
                            
                            Text(motionDetector.formattedMotionStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Acceleration Display
                    VStack(spacing: 8) {
                        Text("Current Acceleration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(motionDetector.formattedAcceleration)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
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
                        if motionDetector.isActive {
                            motionDetector.stopMotionDetection()
                        } else if let device = metawearManager.metawear {
                            motionDetector.startMotionDetection(device: device)
                        }
                    }) {
                        HStack {
                            Image(systemName: motionDetector.isActive ? "stop.circle.fill" : "play.circle.fill")
                            Text(motionDetector.isActive ? "Stop Detection" : "Start Detection")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(motionDetector.isActive ? Color.red : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(metawearManager.metawear == nil || !metawearManager.isConnected)
                    
                    // Threshold Slider
                    VStack(spacing: 8) {
                        HStack {
                            Text("Motion Threshold")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.2f g's", threshold))
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $threshold, in: 0.05...0.5, step: 0.01) { _ in
                            motionDetector.setMotionThreshold(threshold)
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
                        InstructionRow(number: "2", text: "Start motion detection")
                        InstructionRow(number: "3", text: "Wave hand with sensor")
                        InstructionRow(number: "4", text: "Watch for 'Motion Detected!'")
                        InstructionRow(number: "5", text: "Adjust threshold if needed")
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
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct MotionDetectionTestView_Previews: PreviewProvider {
    static var previews: some View {
        MotionDetectionTestView(metawearManager: MetaWearManager())
    }
} 