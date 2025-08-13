# High-Frequency Motion Recording Implementation Guide

## 🎯 Feature Overview

Create a new dashboard tab for high-frequency motion recording that:
- Logs accelerometer, gyroscope, and magnetometer data to device memory at maximum sample rates
- Provides simple start/stop recording interface
- Downloads and visualizes the recorded data after stopping
- Optimized for capturing rapid movements (throws, swings, etc.)

## 📊 Technical Specifications

### Target Sample Rates
- **Accelerometer**: 800Hz (maximum available)
- **Gyroscope**: 3200Hz (maximum available) 
- **Magnetometer**: 30Hz (maximum available)

### Data Storage
- **Device Memory**: Log to MetaWear internal memory during recording
- **Transfer Method**: Download logs after recording stops
- **Data Format**: Timestamped sensor data with X, Y, Z values

### Recording Duration
- **Target**: 10-30 seconds for throw analysis
- **Memory Capacity**: ~8MB available on MetaMotionRL
- **Data Size**: ~2-3MB for 30 seconds at max rates

## 🏗️ Implementation Architecture

### 1. New Dashboard Tab Structure
```
TabView {
    // Existing tabs...
    
    Tab("Motion Recording") {
        MotionRecordingView()
    }
}
```

### 2. Core Components

#### MotionRecordingView.swift
- Main UI for the recording interface
- Start/Stop controls
- Recording status display
- Data visualization after download

#### MotionRecordingManager.swift
- Handles device logging operations
- Manages recording state
- Coordinates data download
- Processes downloaded data

#### MotionDataProcessor.swift
- Processes downloaded sensor data
- Calculates motion statistics
- Prepares data for visualization

#### MotionDataVisualizer.swift
- Charts and graphs for data display
- Time-series visualization
- 3D motion plots

## 🔧 Implementation Steps

### Phase 1: Basic Recording Interface

#### Step 1: Create MotionRecordingView
```swift
struct MotionRecordingView: View {
    @StateObject private var recordingManager = MotionRecordingManager()
    
    var body: some View {
        VStack {
            // Recording controls
            // Status display
            // Data visualization
        }
    }
}
```

#### Step 2: Create MotionRecordingManager
```swift
class MotionRecordingManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var downloadedData: MotionRecordingData?
    
    private var cancellables = Set<AnyCancellable>()
    private var recordingTimer: Timer?
    
    func startRecording() {
        // Implementation
    }
    
    func stopRecording() {
        // Implementation
    }
    
    func downloadData() {
        // Implementation
    }
}
```

### Phase 2: Device Logging Implementation

#### Step 3: Configure High-Frequency Sensors
```swift
// Accelerometer: 800Hz, ±16g range
let accelerometer = MWAccelerometer(rate: .hz800, gravity: .g16)

// Gyroscope: 3200Hz, ±2000°/s range  
let gyroscope = MWGyroscope(rate: .hz3200, range: .dps2000)

// Magnetometer: 30Hz (maximum available)
let magnetometer = MWMagnetometer(freq: .hz30)
```

#### Step 4: Implement Logging Operations
```swift
func startLogging() {
    guard let device = metawearManager.metawear else { return }
    
    // Start logging all sensors
    device.publish()
        .log(accelerometer)
        .sink { identifier in
            print("📊 Accelerometer logging started: \(identifier)")
        }
        .store(in: &cancellables)
    
    device.publish()
        .log(gyroscope)
        .sink { identifier in
            print("🔄 Gyroscope logging started: \(identifier)")
        }
        .store(in: &cancellables)
    
    device.publish()
        .log(magnetometer)
        .sink { identifier in
            print("🧲 Magnetometer logging started: \(identifier)")
        }
        .store(in: &cancellables)
}

func stopLogging() {
    guard let device = metawearManager.metawear else { return }
    
    device.publish()
        .stopLogging()
        .sink { _ in
            print("⏹️ Logging stopped")
        }
        .store(in: &cancellables)
}
```

### Phase 3: Data Download and Processing

#### Step 5: Download Logged Data
```swift
func downloadLoggedData() {
    guard let device = metawearManager.metawear else { return }
    
    device.publish()
        .downloadLogs()
        .sink { data in
            self.processDownloadedData(data)
        }
        .store(in: &cancellables)
}

func processDownloadedData(_ data: [MWDataTableEntry]) {
    var accelerometerData: [Timestamped<SIMD3<Float>>] = []
    var gyroscopeData: [Timestamped<SIMD3<Float>>] = []
    var magnetometerData: [Timestamped<SIMD3<Float>>] = []
    
    for entry in data {
        switch entry.signalName {
        case .acceleration:
            if let accelData = entry.valueAs() as? Timestamped<SIMD3<Float>> {
                accelerometerData.append(accelData)
            }
        case .gyroscope:
            if let gyroData = entry.valueAs() as? Timestamped<SIMD3<Float>> {
                gyroscopeData.append(gyroData)
            }
        case .magnetometer:
            if let magData = entry.valueAs() as? Timestamped<SIMD3<Float>> {
                magnetometerData.append(magData)
            }
        default:
            break
        }
    }
    
    let recordingData = MotionRecordingData(
        accelerometer: accelerometerData,
        gyroscope: gyroscopeData,
        magnetometer: magnetometerData,
        recordingDuration: calculateDuration(from: data)
    )
    
    DispatchQueue.main.async {
        self.downloadedData = recordingData
    }
}
```

### Phase 4: Data Visualization

#### Step 6: Create Data Models
```swift
struct MotionRecordingData {
    let accelerometer: [Timestamped<SIMD3<Float>>]
    let gyroscope: [Timestamped<SIMD3<Float>>]
    let magnetometer: [Timestamped<SIMD3<Float>>]
    let recordingDuration: TimeInterval
    
    var totalSamples: Int {
        accelerometer.count + gyroscope.count + magnetometer.count
    }
    
    var averageSampleRates: SampleRates {
        SampleRates(
            accelerometer: Double(accelerometer.count) / recordingDuration,
            gyroscope: Double(gyroscope.count) / recordingDuration,
            magnetometer: Double(magnetometer.count) / recordingDuration
        )
    }
}

struct SampleRates {
    let accelerometer: Double
    let gyroscope: Double
    let magnetometer: Double
}
```

#### Step 7: Implement Visualization
```swift
struct MotionDataVisualizer: View {
    let data: MotionRecordingData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Recording summary
                RecordingSummaryView(data: data)
                
                // Time-series charts
                AccelerometerChart(data: data.accelerometer)
                GyroscopeChart(data: data.gyroscope)
                MagnetometerChart(data: data.magnetometer)
                
                // Motion analysis
                MotionAnalysisView(data: data)
            }
        }
    }
}
```

## 🎨 User Interface Design

### Recording Controls
```
┌─────────────────────────────────────┐
│ 🎯 Motion Recording                 │
├─────────────────────────────────────┤
│                                     │
│  [▶️ Start Recording] [⏹️ Stop]     │
│                                     │
│  Recording Time: 00:15.3            │
│  Samples: 45,230                    │
│                                     │
│  [📊 Download & Analyze]            │
│                                     │
└─────────────────────────────────────┘
```

### Data Visualization
```
┌─────────────────────────────────────┐
│ 📊 Recording Analysis               │
├─────────────────────────────────────┤
│                                     │
│ Duration: 15.3 seconds              │
│ Total Samples: 45,230               │
│                                     │
│ Accelerometer: 2,400 samples (160Hz)│
│ Gyroscope: 48,000 samples (3,200Hz) │
│ Magnetometer: 450 samples (30Hz)    │
│                                     │
│ [📈 View Charts] [💾 Export Data]   │
│                                     │
└─────────────────────────────────────┘
```

## 🔄 Workflow Implementation

### Recording Workflow
1. **User clicks "Start Recording"**
   - Configure sensors at maximum sample rates
   - Start logging to device memory
   - Begin recording timer
   - Update UI to show recording state

2. **User performs motion (throw, swing, etc.)**
   - Device logs all sensor data internally
   - No real-time transmission (efficient)
   - Recording continues until user stops

3. **User clicks "Stop Recording"**
   - Stop all sensor logging
   - End recording timer
   - Update UI to show completion
   - Enable download button

4. **User clicks "Download & Analyze"**
   - Download all logged data from device
   - Process and organize the data
   - Calculate motion statistics
   - Display visualization

## 📈 Data Analysis Features

### Motion Statistics
- **Peak Acceleration**: Maximum acceleration during recording
- **Peak Angular Velocity**: Maximum rotation speed
- **Motion Duration**: Total time of significant motion
- **Motion Intensity**: RMS of acceleration over time
- **Throw Analysis**: Peak velocity, release timing, trajectory

### Visualization Options
- **Time-Series Charts**: Raw sensor data over time
- **3D Motion Plots**: Trajectory visualization
- **Spectrum Analysis**: Frequency domain analysis
- **Motion Heatmaps**: Intensity visualization

## 🛠️ Technical Considerations

### Memory Management
- **Device Memory**: ~8MB available on MetaMotionRL
- **Data Efficiency**: Use maximum compression
- **Overflow Protection**: Monitor memory usage
- **Cleanup**: Clear logs after successful download

### Error Handling
- **Connection Loss**: Handle during recording
- **Memory Full**: Stop recording automatically
- **Download Failures**: Retry mechanism
- **Invalid Data**: Data validation and filtering

### Performance Optimization
- **Sample Rate Selection**: Balance quality vs memory
- **Data Processing**: Efficient algorithms for large datasets
- **UI Responsiveness**: Background processing for heavy operations
- **Memory Cleanup**: Proper disposal of large data arrays

## 🧪 Testing Strategy

### Unit Testing
- **Sensor Configuration**: Verify correct sample rates
- **Logging Operations**: Test start/stop functionality
- **Data Processing**: Validate data parsing and calculations
- **Error Handling**: Test edge cases and failures

### Integration Testing
- **Device Communication**: Test with real MetaMotionRL
- **Data Flow**: End-to-end recording and download
- **Memory Management**: Test with long recordings
- **UI Responsiveness**: Test with large datasets

### User Testing
- **Recording Workflow**: Test complete user journey
- **Data Quality**: Verify accuracy of recorded data
- **Performance**: Test with maximum sample rates
- **Usability**: Test interface intuitiveness

## 📋 Implementation Checklist

### Phase 1: Basic Interface
- [ ] Create MotionRecordingView
- [ ] Add tab to main dashboard
- [ ] Implement basic start/stop controls
- [ ] Add recording status display

### Phase 2: Device Logging
- [ ] Create MotionRecordingManager
- [ ] Implement sensor configuration
- [ ] Add logging start/stop functionality
- [ ] Test with real device

### Phase 3: Data Download
- [ ] Implement download functionality
- [ ] Create data processing pipeline
- [ ] Add data validation
- [ ] Test download reliability

### Phase 4: Visualization
- [ ] Create data models
- [ ] Implement basic charts
- [ ] Add motion statistics
- [ ] Create export functionality

### Phase 5: Polish
- [ ] Add error handling
- [ ] Optimize performance
- [ ] Add user documentation
- [ ] Final testing and validation

## 🎯 Success Criteria

### Functional Requirements
- [ ] Record accelerometer at 800Hz
- [ ] Record gyroscope at 3200Hz
- [ ] Record magnetometer at 30Hz
- [ ] Download data reliably
- [ ] Display meaningful visualizations

### Performance Requirements
- [ ] Handle 30-second recordings
- [ ] Process 50,000+ samples efficiently
- [ ] Maintain responsive UI
- [ ] Complete download in <10 seconds

### User Experience Requirements
- [ ] Simple start/stop interface
- [ ] Clear recording status
- [ ] Intuitive data visualization
- [ ] Reliable operation

---

**This implementation guide provides a comprehensive roadmap for building the high-frequency motion recording feature. Follow the phases sequentially and test thoroughly at each step.**
