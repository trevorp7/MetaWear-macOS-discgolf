# Speed Tracking with MetaWear

This solution provides device speed tracking in mph using **MbientLab's recommended sensor fusion approach**. It follows their best practices for motion tracking and gravity compensation.

## 🎯 Key Features

- **Real-time speed calculation** in mph
- **Gravity-compensated motion tracking** using sensor fusion
- **Configurable sensitivity** for different use cases
- **Clean SwiftUI interface** with modern design
- **Follows MbientLab's methods** for optimal accuracy

## 🚀 How It Works

### MbientLab's Recommended Approach

Instead of using raw accelerometer data (which includes gravity), this solution uses **sensor fusion linear acceleration**:

1. **Sensor Fusion**: Combines accelerometer, gyroscope, and magnetometer data
2. **Linear Acceleration**: Provides gravity-compensated motion data
3. **Integration**: Converts acceleration to velocity through mathematical integration
4. **Speed Calculation**: Converts velocity magnitude to mph

### Why This Approach?

- ✅ **Gravity Compensation**: Automatically removes gravity effects
- ✅ **Better Accuracy**: Uses multiple sensors for robust tracking
- ✅ **MbientLab Recommended**: Follows their official SDK patterns
- ✅ **No Manual Calibration**: Sensor fusion handles calibration internally

## 📁 Files Included

### Core Components
- `SpeedCalculator.swift` - Main speed calculation logic
- `SpeedTrackingView.swift` - Full-featured SwiftUI interface
- `SpeedIntegrationExample.swift` - Integration examples

### Key Classes

#### SpeedCalculator
```swift
class SpeedCalculator: ObservableObject {
    @Published var currentSpeed: Double = 0.0 // mph
    @Published var isTracking: Bool = false
    @Published var status: String = "Not started"
    
    func startSpeedTracking(device: MetaWear)
    func stopSpeedTracking()
    func resetSpeed()
}
```

#### SpeedTrackingView
```swift
struct SpeedTrackingView: View {
    // Complete speed tracking interface
    // - Large speed display
    // - Start/Stop controls
    // - Sensitivity settings
    // - Status indicators
}
```

## 🔧 Integration Steps

### 1. Add to Your Project
Copy these files to your Xcode project:
- `SpeedCalculator.swift`
- `SpeedTrackingView.swift`
- `SpeedIntegrationExample.swift`

### 2. Basic Integration
```swift
import SwiftUI
import MetaWear

struct YourContentView: View {
    @StateObject private var speedCalculator = SpeedCalculator()
    @State private var metawear: MetaWear?
    
    var body: some View {
        VStack {
            // Your existing content
            
            // Add speed display
            SpeedDisplayCard(speedCalculator: speedCalculator, metawear: metawear)
        }
    }
}
```

### 3. Full Integration with Tabs
```swift
struct ContentViewWithSpeed: View {
    @StateObject private var speedCalculator = SpeedCalculator()
    
    var body: some View {
        TabView {
            // Your existing accelerometer view
            YourExistingView()
                .tabItem { 
                    Image(systemName: "sensor.tag.radiowaves.forward")
                    Text("Sensors") 
                }
            
            // Dedicated speed tracking
            SpeedTrackingView()
                .tabItem { 
                    Image(systemName: "speedometer")
                    Text("Speed") 
                }
        }
    }
}
```

## ⚙️ Configuration Options

### Sensitivity Settings
```swift
// Apply preset sensitivity levels
speedCalculator.applyThresholdPreset(.low)      // 0.02 g - Very sensitive
speedCalculator.applyThresholdPreset(.medium)   // 0.05 g - Default
speedCalculator.applyThresholdPreset(.high)     // 0.10 g - Less sensitive

// Custom threshold
speedCalculator.setMovementThreshold(0.03)
```

### Sensor Fusion Modes
The solution uses `.ndof` (9-DOF) mode by default, which provides the best accuracy:
- **NDoF**: 9-DOF (accelerometer + gyroscope + magnetometer)
- **IMUPlus**: 6-DOF (accelerometer + gyroscope)
- **Compass**: 6-DOF with compass
- **M4G**: 6-DOF with magnetometer

## 📊 Technical Details

### Speed Calculation Process
1. **Linear Acceleration**: Get gravity-compensated acceleration in g's
2. **Unit Conversion**: Convert g's to m/s² (× 9.80665)
3. **Integration**: v = v₀ + a × dt (Euler integration)
4. **Magnitude**: Calculate 3D velocity magnitude
5. **Conversion**: Convert m/s to mph (× 2.23694)

### Noise Reduction
- **Movement Threshold**: Only track when acceleration > threshold
- **Low-pass Filter**: Smooth velocity calculations
- **Auto-reset**: Reset velocity when motion stops

### Performance Considerations
- **Sample Rate**: Uses sensor fusion's optimal rate
- **Memory Efficient**: Minimal state storage
- **Battery Friendly**: Leverages hardware sensor fusion

## 🎨 UI Components

### SpeedDisplayCard
Compact speed display for integration into existing views:
```swift
SpeedDisplayCard(speedCalculator: speedCalculator, metawear: metawear)
```

### SpeedTrackingView
Full-featured speed tracking interface with:
- Large speed display
- Start/Stop controls
- Sensitivity settings
- Status indicators
- Information section

## 🔍 Troubleshooting

### Common Issues

**Speed shows 0.0 mph**
- Check if MetaWear is connected
- Verify sensor fusion is working
- Adjust sensitivity threshold

**Inaccurate readings**
- Ensure device is moving above threshold
- Check for magnetic interference
- Try different sensitivity settings

**Connection issues**
- Verify MetaWear SDK is properly imported
- Check Bluetooth permissions
- Ensure device is in range

### Debug Information
```swift
// Get detailed status
print(speedCalculator.detailedStatus)

// Check current threshold
print(speedCalculator.currentMovementThreshold)

// Monitor tracking state
print(speedCalculator.isTracking)
```

## 📈 Best Practices

### For Accurate Speed Tracking
1. **Mount Securely**: Attach device firmly to avoid vibration
2. **Avoid Magnetic Interference**: Keep away from magnets/metal
3. **Calibrate Environment**: Use in open spaces when possible
4. **Test Sensitivity**: Start with medium, adjust as needed

### For Integration
1. **Use Sensor Fusion**: Always prefer linear acceleration over raw accelerometer
2. **Handle Disconnections**: Implement proper error handling
3. **Update UI Responsively**: Use @Published properties for real-time updates
4. **Reset Appropriately**: Clear speed when tracking stops

## 🚀 Next Steps

### Enhancements You Can Add
- **Speed History**: Track and display speed over time
- **GPS Integration**: Compare with GPS speed for validation
- **Activity Detection**: Different thresholds for walking/running/driving
- **Data Logging**: Save speed data for analysis
- **Custom Units**: Add km/h, m/s options

### Advanced Features
- **Kalman Filtering**: More sophisticated noise reduction
- **Machine Learning**: Activity classification
- **Cloud Sync**: Upload speed data
- **Social Features**: Share speed achievements

## 📚 References

- [MetaWear Swift SDK Documentation](https://mbientlab.com/docs/metawear/swift/latest/)
- [Sensor Fusion Guide](https://mbientlab.com/docs/metawear/swift/latest/sensor_fusion.html)
- [Linear Acceleration Tutorial](https://mbientlab.com/docs/metawear/swift/latest/accelerometer.html)

## 🤝 Support

This solution follows MbientLab's official recommendations and patterns. For additional support:
- Check the MetaWear documentation
- Review the example code files
- Test with different sensitivity settings
- Validate with known speed references

---

**Note**: This solution provides relative speed tracking. For absolute speed (like GPS), additional sensors or external references may be needed. 