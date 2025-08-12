# MetaWear Swift Combine SDK - Complete Methods Reference

This document provides a comprehensive reference of all available methods and functionality in the MetaWear Swift Combine SDK. Use this as a quick reference to avoid reinventing the wheel when working with MetaWear devices.

## Table of Contents
1. [Device Connection & Management](#device-connection--management)
2. [Sensor Data Collection](#sensor-data-collection)
3. [Data Processing & Analysis](#data-processing--analysis)
4. [Device Commands & Control](#device-commands--control)
5. [Data Logging & Storage](#data-logging--storage)
6. [Device Information & Status](#device-information--status)

---

## Device Connection & Management

### Connection Methods
```swift
// Connect to device
metawear.connect()
metawear.connectPublisher() -> MWPublisher<MetaWear>

// Disconnect from device
metawear.disconnect()

// Check connection state
metawear.connectionState // CBPeripheralState
metawear.connectionStatePublisher // Publisher<CBPeripheralState, Never>

// Device memory management
metawear.remember() // Add to persistent table
metawear.forget() // Remove from persistent table
```

### Device Discovery
```swift
// Get device information
metawear.info // DeviceInformation (MAC, model, serial, firmware)
metawear.name // String
metawear.localBluetoothID // CBPeripheralIdentifier

// Signal strength
metawear.rssi // Int
metawear.rssiPublisher // Publisher<Int, Never>
metawear.rssiMovingAveragePublisher // Publisher<Int, Never>
metawear.updateRSSI() // Manual RSSI refresh

// Advertisement data
metawear.advertisementData // [String: Any]
metawear.advertisementDataPublisher // Publisher<(rssi: Int, advertisementData: [String:Any]), Never>
```

### State Management
```swift
// Serialize/deserialize device state
metawear.stateSerialize() -> [UInt8]
metawear.stateDeserialize(_ data: [UInt8])
metawear.stateLoadFromUniqueURL()
metawear.uniqueURL() -> URL

// Describe available modules
metawear.describeModules() -> MWPublisher<[MWModules.ID:MWModules]>
```

---

## Sensor Data Collection

### Accelerometer
```swift
// Basic acceleration data (X, Y, Z in g's)
.accelerometer(rate: .hz100, gravity: .g8)

// Motion detection
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

### Gyroscope
```swift
// Angular velocity (rotation) in deg/s
.gyroscope(rate: .hz100, range: .dps2000)
```

**Available Rates:** `.hz25`, `.hz50`, `.hz100`, `.hz200`, `.hz400`, `.hz800`, `.hz1600`, `.hz3200`  
**Available Ranges:** `.dps125`, `.dps250`, `.dps500`, `.dps1000`, `.dps2000`

### Magnetometer
```swift
// Magnetic field strength
.magnetometer(rate: .hz100, range: .uT4900)
```

**Available Rates:** `.hz25`, `.hz50`, `.hz100`, `.hz200`, `.hz400`, `.hz800`, `.hz1600`, `.hz3200`  
**Available Ranges:** `.uT2000`, `.uT4000`, `.uT8000`, `.uT16000`

### Barometer
```swift
// Atmospheric pressure (Pascals)
.pressure(standby: .ms125, iir: .off, oversampling: .standard)

// Altitude (meters)
.altitude(standby: .ms125, iir: .off, oversampling: .standard)
```

**Available Standby Times:** `.ms0_5`, `.ms62_5`, `.ms125`, `.ms250`, `.ms500`, `.ms1000`, `.ms2000`, `.ms4000`  
**Available IIR Filters:** `.off`, `.avg2`, `.avg4`, `.avg8`, `.avg16`  
**Available Oversampling:** `.ultraLowPower`, `.lowPower`, `.standard`, `.highResolution`, `.ultraHighResolution`

### Ambient Light
```swift
// Light intensity (lux)
.ambientLight(rate: .ms1000, gain: .x1, integrationTime: .ms100)
```

**Available Rates:** `.ms50`, `.ms100`, `.ms200`, `.ms500`, `.ms1000`, `.ms2000`  
**Available Gains:** `.x1`, `.x2`, `.x4`, `.x8`, `.x48`, `.x96`  
**Available Integration Times:** `.ms50`, `.ms100`, `.ms150`, `.ms200`, `.ms250`, `.ms300`, `.ms350`, `.ms400`

### Thermometer
```swift
// Temperature (Celsius)
.thermometer(type: .onboard, board: board) // Onboard sensor
.thermometer(type: .external, board: board) // External thermistor
.thermometer(type: .bmp280, board: board) // Barometer temperature
```

**Available Types:** `.onboard`, `.external`, `.bmp280`

### Hygrometer
```swift
// Humidity (%)
.hygrometer(rate: .hz1)
```

**Available Rates:** `.hz0_5`, `.hz1`, `.hz2`, `.hz5`, `.hz10`, `.hz20`

### Battery
```swift
// Battery level (0-100%)
.batteryLevel

// Charging status
.chargingStatus
```

**Charging States:** `.charging`, `.notCharging`, `.unknown`

### Sensor Fusion (Advanced)
```swift
// Euler angles (pitch, roll, yaw in degrees)
.eulerAngles(mode: .ndof)

// Quaternion (WXYZ)
.quaternion(mode: .ndof)

// Gravity vector (XYZ in g's)
.gravity(mode: .ndof)

// Linear acceleration (XYZ in g's)
.linearAcceleration(mode: .ndof)
```

**Available Modes:** `.ndof` (9 degrees of freedom), `.imu` (6 degrees of freedom), `.compass`, `.m4g`

### GPIO (General Purpose I/O)
```swift
// Digital input/output
.gpio(pin: 0, mode: .digitalInput)
.gpio(pin: 1, mode: .digitalOutput)
.gpio(pin: 2, mode: .analogInput)
.gpio(pin: 3, mode: .pwmOutput)
```

**Available Modes:** `.digitalInput`, `.digitalOutput`, `.analogInput`, `.pwmOutput`

### Mechanical Button
```swift
// Button press detection
.mechanicalButton()
```

---

## Data Processing & Analysis

### Data Collection Methods
```swift
// Stream continuous data
metawear.publishWhenConnected()
    .stream(sensor)
    .sink { value in
        // Handle streaming data
    }

// Read data once
metawear.publishIfConnected()
    .read(sensor)
    .sink { value in
        // Handle single read
    }

// Poll data at intervals
metawear.publishWhenConnected()
    .stream(pollableSensor)
    .sink { value in
        // Handle polled data
    }
```

### Data Processors
```swift
// Mathematical operations
.math(operation: .add, rhs: 10.0)
.math(operation: .multiply, rhs: 2.0)
.math(operation: .divide, rhs: 3.0)
.math(operation: .subtract, rhs: 5.0)
.math(operation: .power, rhs: 2.0)
.math(operation: .sqrt)
.math(operation: .log)
.math(operation: .ln)
.math(operation: .abs)
.math(operation: .constant, rhs: 42.0)

// Filtering
.filter(.greaterThan, reference: 10.0)
.filter(.lessThan, reference: 100.0)
.filter(.equal, reference: 50.0)
.filter(.notEqual, reference: 0.0)

// Threshold detection
.threshold(mode: .absolute, boundary: 5.0)
.threshold(mode: .binary, boundary: 10.0)

// Delta processing
.computeDelta(mode: .absolute, magnitude: 2.0)
.computeDelta(mode: .differential, magnitude: 1.0)
.computeDelta(mode: .binary, magnitude: 0.5)

// Averaging
.average(size: 10)

// Running sum
.runningSum()

// Root mean square
.rms()

// Root sum square
.rss()

// Pulse detection
.pulse(threshold: 5.0, width: 100)

// Counter
.counted(size: 10)

// Buffer
.buffer()

// Sample collection
.sample(size: 50)

// Throttle (timer-based)
.throttle(period: 1000) // milliseconds

// Packer (combine multiple values)
.packer(count: 4)

// Fuser (combine multiple sources)
.fuser(count: 2)

// Comparator with multiple references
.filter(.greaterThan, mode: .absolute, references: [10.0, 20.0, 30.0])
```

### Data Type Conversions
```swift
// Convert raw data to Swift types
.convert(from: rawData) // Returns Timestamped<DataType>

// Access raw C++ data
.valueAs() as TargetType
```

---

## Device Commands & Control

### LED Control
```swift
// Turn off LED
.ledOff

// Flash LED with pattern
.ledFlash(color: .red, pattern: .solid)
.ledFlash(color: .blue, pattern: .pulse)
.ledFlash(color: .green, pattern: .blink)
```

**Available Patterns:** `.solid`, `.pulse`, `.blink`, `.custom`  
**Available Colors:** Any `NSColor`/`UIColor`

### Haptic Feedback
```swift
// Trigger haptic motor
.hapticMotor(duration: 500) // milliseconds
.hapticMotor(pattern: .single)
.hapticMotor(pattern: .double)
.hapticMotor(pattern: .burst)
```

**Available Patterns:** `.single`, `.double`, `.burst`, `.custom`

### Device Reset
```swift
// Reset device
.reset()

// Reset to factory settings
.resetFactory()

// Reset after delay
.resetAfter(delay: 1000) // milliseconds
```

### Device Naming
```swift
// Change device name
.changeName(to: "MyMetaWear")

// Validate name
MetaWear.isNameValid("ProposedName") // Returns Bool
```

### iBeacon
```swift
// Configure iBeacon
.iBeacon(uuid: UUID(), major: 1, minor: 1, power: -12)
```

### Custom Events
```swift
// Create custom event
.customEvent(identifier: "myEvent")
```

### Stop All Sensor Activity
```swift
// Stop all sensors
.stopSensorActivity()
```

### Macro Programming
```swift
// Execute macro
.macro(executeOnBoot: true) { metawear in
    // Macro commands
}

// Record macro
.recordMacro(identifier: "myMacro") { metawear in
    // Commands to record
}
```

---

## Data Logging & Storage

### Logging Methods
```swift
// Start logging
metawear.publishWhenConnected()
    .log(sensor)
    .sink { identifier in
        // Logging started
    }

// Stop logging
metawear.publishIfConnected()
    .stopLogging()
    .sink { _ in
        // Logging stopped
    }

// Download logged data
metawear.publishIfConnected()
    .downloadLogs()
    .sink { data in
        // Handle downloaded data
    }

// Clear logs
metawear.publishIfConnected()
    .clearLogs()
    .sink { _ in
        // Logs cleared
    }
```

### Data Export
```swift
// Export to CSV
.exportToCSV(filename: "sensor_data.csv")

// Export to JSON
.exportToJSON(filename: "sensor_data.json")
```

---

## Device Information & Status

### Device Details
```swift
// Get device information
metawear.info.mac // MAC address
metawear.info.model // Device model
metawear.info.serial // Serial number
metawear.info.firmware // Firmware version
metawear.info.hardware // Hardware version

// Check if device is in MetaBoot mode
metawear.isMetaBoot // Bool
```

### Module Detection
```swift
// Check available modules
metawear.describeModules() // Returns [MWModules.ID: MWModules]

// Check specific module availability
MWModules.lookup(in: board, .accelerometer) != nil
MWModules.lookup(in: board, .gyroscope) != nil
MWModules.lookup(in: board, .magnetometer) != nil
MWModules.lookup(in: board, .barometer) != nil
MWModules.lookup(in: board, .thermometer) != nil
MWModules.lookup(in: board, .ambientLight) != nil
MWModules.lookup(in: board, .led) != nil
MWModules.lookup(in: board, .hapticMotor) != nil
```

### Error Handling
```swift
// Common error types
MWError.operationFailed("Description")
MWError.connectionFailed("Description")
MWError.deviceNotFound("Description")
MWError.invalidParameter("Description")
MWError.timeout("Description")
```

---

## Usage Examples

### Basic Sensor Streaming
```swift
// Stream accelerometer data
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g8))
    .sink { acceleration in
        let (timestamp, xyz) = acceleration
        print("Acceleration: \(xyz) at \(timestamp)")
    }
```

### Step Counting
```swift
// Count steps
metawear.publishWhenConnected()
    .stream(.stepCounter())
    .sink { stepCount in
        let (timestamp, count) = stepCount
        print("Step count: \(count) at \(timestamp)")
    }
```

### Battery Monitoring
```swift
// Monitor battery level
metawear.publishWhenConnected()
    .read(.batteryLevel)
    .sink { battery in
        let (timestamp, level) = battery
        print("Battery: \(level)% at \(timestamp)")
    }
```

### Data Processing Pipeline
```swift
// Stream and process accelerometer data
metawear.publishWhenConnected()
    .stream(.accelerometer(rate: .hz100, gravity: .g8))
    .math(operation: .multiply, rhs: 9.81) // Convert to m/s²
    .average(size: 10) // 10-sample average
    .filter(.greaterThan, reference: 20.0) // Only values > 20 m/s²
    .sink { processedData in
        print("Processed acceleration: \(processedData)")
    }
```

### LED Feedback
```swift
// Flash LED when step detected
metawear.publishWhenConnected()
    .stream(.stepDetector())
    .sink { _ in
        metawear.publishIfConnected()
            .ledFlash(color: .green, pattern: .blink)
            .sink { _ in }
    }
```

This reference covers the most commonly used methods in the MetaWear Swift Combine SDK. For more advanced usage and edge cases, refer to the official SDK documentation and examples. 