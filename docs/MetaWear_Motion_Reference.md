# MetaWear Motion & Movement Reference

This document focuses specifically on motion-related functionality in the MetaWear Swift Combine SDK. It covers all sensors, data processing methods, and analysis techniques relevant for motion tracking, movement detection, and activity analysis.

## Table of Contents
1. [Motion Sensors](#motion-sensors)
2. [Motion Detection & Analysis](#motion-detection--analysis)
3. [Activity Recognition](#activity-recognition)
4. [Motion Data Processing](#motion-data-processing)
5. [Orientation & Position](#orientation--position)
6. [Motion-Based Feedback](#motion-based-feedback)
7. [Motion Data Logging](#motion-data-logging)
8. [Motion Analysis Examples](#motion-analysis-examples)

---

## Motion Sensors

### Accelerometer (Primary Motion Sensor)
```swift
// Basic acceleration data (X, Y, Z in g's)
.accelerometer(rate: .hz100, gravity: .g8)

// Motion detection with built-in algorithms
.accelerometerMotion(rate: .hz100, gravity: .g8)

// Step detection and counting
.stepDetector(sensitivity: .normal)
.stepCounter(sensitivity: .normal)

// Orientation detection
.accelerometerOrientation(rate: .hz100, gravity: .g8)
```

**Available Rates:** `.hz0_78125`, `.hz1_5625`, `.hz3_125`, `.hz6_25`, `.hz12_5`, `.hz25`, `.hz50`, `.hz100`, `.hz200`, `.hz400`, `.hz800`, `.hz1600`  
**Available Ranges:** `.g2`, `.g4`, `.g8`, `.g16`  
**Step Sensitivity:** `.sensitive`, `.normal`, `.robust`

### Gyroscope (Rotation & Angular Motion)
```swift
// Angular velocity (rotation) in deg/s
.gyroscope(rate: .hz100, range: .dps2000)
```

**Available Rates:** `.hz25`, `.hz50`, `.hz100`, `.hz200`, `.hz400`, `.hz800`, `.hz1600`, `.hz3200`  
**Available Ranges:** `.dps125`, `.dps250`, `.dps500`, `.dps1000`, `.dps2000`

### Magnetometer (Heading & Direction)
```swift
// Magnetic field strength (useful for heading)
.magnetometer(rate: .hz100, range: .uT4900)
```

**Available Rates:** `.hz25`, `.hz50`, `.hz100`, `.hz200`, `.hz400`, `.hz800`, `.hz1600`, `.hz3200`  
**Available Ranges:** `.uT2000`, `.uT4000`, `.uT8000`, `.uT16000`

### Sensor Fusion (Advanced Motion Analysis)
```swift
// Euler angles (pitch, roll, yaw in degrees)
.eulerAngles(mode: .ndof)

// Quaternion (WXYZ) - most accurate orientation
.quaternion(mode: .ndof)

// Gravity vector (XYZ in g's) - filtered gravity
.gravity(mode: .ndof)

// Linear acceleration (XYZ in g's) - motion without gravity
.linearAcceleration(mode: .ndof)
```

**Available Modes:** `.ndof` (9 degrees of freedom), `.imu` (6 degrees of freedom), `.compass`, `.m4g`

---

## Motion Detection & Analysis

### Built-in Motion Detection
```swift
// Detect any motion (movement above threshold)
.accelerometerMotion(rate: .hz100, gravity: .g8)

// Detect specific motion patterns
.motionDetection(sensitivity: .normal)
```

### Step Analysis
```swift
// Detect individual steps (fires on each step)
.stepDetector(sensitivity: .normal)

// Count total steps (reports every ~20 steps)
.stepCounter(sensitivity: .normal)

// Step sensitivity levels
.sensitive   // Detects subtle movements
.normal      // Standard step detection
.robust      // Only strong steps
```

### Orientation Detection
```swift
// Detect device orientation changes
.accelerometerOrientation(rate: .hz100, gravity: .g8)

// Get current orientation
.orientation()

// Orientation states
.portrait
.landscape
.faceUp
.faceDown
```

---

## Activity Recognition

### Walking Detection
```swift
// Detect walking motion
metawear.publishWhenConnected()
    .stream(.stepDetector())
    .sink { step in
        // Step detected - user is walking
    }
```

### Running Detection
```swift
// Detect running (higher acceleration patterns)
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g8))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .filter(.greaterThan, reference: 15.0) // High acceleration threshold
    .average(size: 5) // Smooth the signal
    .sink { acceleration in
        // High acceleration detected - likely running
    }
```

### Stationary Detection
```swift
// Detect when device is stationary
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz50, gravity: .g8))
    .average(size: 10) // Average over 10 samples
    .filter(.lessThan, reference: 0.5) // Low movement threshold
    .sink { acceleration in
        // Device is relatively stationary
    }
```

### Fall Detection
```swift
// Basic fall detection (high acceleration followed by low)
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g16))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .threshold(mode: .absolute, boundary: 20.0) // High acceleration threshold
    .sink { acceleration in
        // Potential fall detected
    }
```

---

## Motion Data Processing

### Speed Calculation
```swift
// Calculate speed from acceleration
metawear.publishWhenConnected()
    .stream(.linearAcceleration(mode: .ndof))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .runningSum() // Integrate to get velocity
    .math(operation: .abs) // Get magnitude
    .average(size: 5) // Smooth the result
    .sink { speed in
        // Speed in m/s
    }
```

### Distance Calculation
```swift
// Calculate distance from acceleration
metawear.publishWhenConnected()
    .stream(.linearAcceleration(mode: .ndof))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .runningSum() // First integration: velocity
    .runningSum() // Second integration: distance
    .math(operation: .abs) // Get magnitude
    .sink { distance in
        // Distance in meters
    }
```

### Motion Intensity
```swift
// Calculate motion intensity (overall movement level)
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g8))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .rms() // Root mean square for intensity
    .average(size: 10) // Smooth over time
    .sink { intensity in
        // Motion intensity level
    }
```

### Motion Direction
```swift
// Determine motion direction
metawear.publishWhenConnected()
    .stream(.linearAcceleration(mode: .ndof))
    .sink { acceleration in
        let (timestamp, xyz) = acceleration
        let direction = determineDirection(xyz)
        // direction: forward, backward, left, right, up, down
    }
```

### Motion Patterns
```swift
// Detect specific motion patterns
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g8))
    .buffer() // Buffer recent data
    .sample(size: 50) // Sample pattern
    .sink { pattern in
        // Analyze pattern for specific movements
        // e.g., shaking, tapping, waving
    }
```

---

## Orientation & Position

### Device Orientation
```swift
// Get current device orientation
metawear.publishWhenConnected()
    .stream(.eulerAngles(mode: .ndof))
    .sink { orientation in
        let (timestamp, pitchRollYaw) = orientation
        let (pitch, roll, yaw) = pitchRollYaw
        // Use pitch, roll, yaw for orientation analysis
    }
```

### Heading Direction
```swift
// Get heading direction (compass)
metawear.publishWhenConnected()
    .stream(.magnetometer(rate: .hz10, range: .uT4900))
    .sink { magneticField in
        let (timestamp, xyz) = magneticField
        let heading = calculateHeading(xyz)
        // heading in degrees (0-360)
    }
```

### Tilt Detection
```swift
// Detect device tilt
metawear.publishWhenConnected()
    .stream(.eulerAngles(mode: .ndof))
    .sink { orientation in
        let (timestamp, pitchRollYaw) = orientation
        let (pitch, roll, yaw) = pitchRollYaw
        
        if abs(pitch) > 45 || abs(roll) > 45 {
            // Device is significantly tilted
        }
    }
```

### Upside Down Detection
```swift
// Detect if device is upside down
metawear.publishWhenConnected()
    .stream(.gravity(mode: .ndof))
    .sink { gravity in
        let (timestamp, xyz) = gravity
        let (x, y, z) = xyz
        
        if z < -0.5 {
            // Device is upside down
        }
    }
```

---

## Motion-Based Feedback

### Haptic Feedback on Motion
```swift
// Trigger haptic feedback on step detection
metawear.publishWhenConnected()
    .stream(.stepDetector())
    .sink { _ in
        metawear.publishIfConnected()
            .hapticMotor(pattern: .single)
            .sink { _ in }
    }
```

### LED Feedback on Movement
```swift
// Flash LED when motion detected
metawear.publishWhenConnected()
    .stream(.accelerometerMotion(rate: .hz50, gravity: .g8))
    .sink { _ in
        metawear.publishIfConnected()
            .ledFlash(color: .green, pattern: .blink)
            .sink { _ in }
    }
```

### Motion Alerts
```swift
// Alert on excessive motion
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g8))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .filter(.greaterThan, reference: 30.0) // High threshold
    .sink { _ in
        // Excessive motion detected - trigger alert
        metawear.publishIfConnected()
            .hapticMotor(pattern: .burst)
            .ledFlash(color: .red, pattern: .pulse)
            .sink { _ in }
    }
```

---

## Motion Data Logging

### Log Motion Data
```swift
// Log accelerometer data for later analysis
metawear.publishWhenConnected()
    .log(.accelerometer(rate: .hz100, gravity: .g8))
    .sink { identifier in
        // Motion logging started
    }
```

### Log Step Data
```swift
// Log step counter data
metawear.publishWhenConnected()
    .log(.stepCounter())
    .sink { identifier in
        // Step logging started
    }
```

### Log Orientation Data
```swift
// Log orientation changes
metawear.publishWhenConnected()
    .log(.eulerAngles(mode: .ndof))
    .sink { identifier in
        // Orientation logging started
    }
```

### Download Motion Logs
```swift
// Download logged motion data
metawear.publishIfConnected()
    .downloadLogs()
    .sink { data in
        // Process downloaded motion data
        for entry in data {
            // Analyze motion patterns
        }
    }
```

---

## Motion Analysis Examples

### Basic Motion Monitoring
```swift
// Monitor overall motion level
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz50, gravity: .g8))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .rms() // Get motion intensity
    .average(size: 10) // Smooth over time
    .sink { motionLevel in
        let (timestamp, intensity) = motionLevel
        print("Motion intensity: \(intensity) m/s² at \(timestamp)")
    }
```

### Step Counting with Feedback
```swift
// Count steps and provide feedback
metawear.publishWhenConnected()
    .stream(.stepCounter())
    .sink { stepData in
        let (timestamp, count) = stepData
        print("Step count: \(count) at \(timestamp)")
        
        // Provide haptic feedback every 10 steps
        if count % 10 == 0 {
            metawear.publishIfConnected()
                .hapticMotor(pattern: .double)
                .sink { _ in }
        }
    }
```

### Activity Classification
```swift
// Classify activity based on motion patterns
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g8))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .average(size: 20) // 200ms window
    .sink { acceleration in
        let (timestamp, xyz) = acceleration
        let magnitude = sqrt(xyz.x*xyz.x + xyz.y*xyz.y + xyz.z*xyz.z)
        
        let activity = classifyActivity(magnitude)
        // activity: stationary, walking, running, etc.
    }
```

### Motion Gesture Recognition
```swift
// Recognize motion gestures
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g8))
    .buffer() // Buffer recent data
    .sample(size: 100) // 1 second of data
    .sink { gestureData in
        let gesture = recognizeGesture(gestureData)
        // gesture: shake, tap, wave, etc.
    }
```

### Fall Detection System
```swift
// Comprehensive fall detection
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g16))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .threshold(mode: .absolute, boundary: 25.0) // High acceleration
    .sink { _ in
        // Potential fall detected
        // Trigger alert system
        metawear.publishIfConnected()
            .hapticMotor(pattern: .burst)
            .ledFlash(color: .red, pattern: .pulse)
            .sink { _ in }
    }
```

### Motion-Based Game Control
```swift
// Use motion for game control
metawear.publishWhenConnected()
    .stream(.eulerAngles(mode: .ndof))
    .sink { orientation in
        let (timestamp, pitchRollYaw) = orientation
        let (pitch, roll, yaw) = pitchRollYaw
        
        // Use pitch for forward/backward control
        // Use roll for left/right control
        // Use yaw for rotation control
        
        updateGameControls(pitch: pitch, roll: roll, yaw: yaw)
    }
```

### Motion Data Export
```swift
// Export motion data for analysis
metawear.publishIfConnected()
    .downloadLogs()
    .sink { data in
        // Export to CSV for external analysis
        exportMotionDataToCSV(data, filename: "motion_data.csv")
    }
```

---

## Motion Sensor Configuration Tips

### For Walking Detection
- **Accelerometer Rate:** `.hz50` (sufficient for walking)
- **Range:** `.g8` (covers normal walking acceleration)
- **Use:** `.stepDetector()` or `.stepCounter()`

### For Running Detection
- **Accelerometer Rate:** `.hz100` (higher frequency needed)
- **Range:** `.g16` (running has higher acceleration)
- **Use:** Raw accelerometer with threshold filtering

### For Gesture Recognition
- **Accelerometer Rate:** `.hz100` (high frequency for detail)
- **Range:** `.g8` (sufficient for gestures)
- **Use:** Buffer + pattern recognition

### For Fall Detection
- **Accelerometer Rate:** `.hz100` (high frequency for accuracy)
- **Range:** `.g16` (falls have high acceleration)
- **Use:** Threshold detection with confirmation

### For Orientation Tracking
- **Sensor Fusion Mode:** `.ndof` (9 degrees of freedom)
- **Use:** `.eulerAngles()` or `.quaternion()`

This motion-focused reference covers all the essential functionality for motion tracking, analysis, and detection with MetaWear devices. Use these methods to build sophisticated motion-aware applications without reinventing the wheel! 