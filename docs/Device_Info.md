# 📱 Device Information

Technical specifications and details for the MetaMotionRL sensor.

## 🎯 Device Overview

### MetaMotionRL
- **Manufacturer**: MbientLab
- **Model**: MetaMotionRL
- **Type**: Wearable motion sensor
- **Protocol**: Bluetooth Low Energy (BLE)
- **MAC Address**: `ea:78:c3:d3:f0:8a`

## 📊 Sensor Specifications

### Accelerometer
- **Range**: ±2g, ±4g, ±8g, ±16g (configurable)
- **Resolution**: 16-bit
- **Sample Rate**: 1Hz - 1000Hz (configurable)
- **Units**: g-force (9.8 m/s²)
- **Data Format**: X, Y, Z values

### Gyroscope
- **Range**: ±125°/s, ±250°/s, ±500°/s, ±1000°/s, ±2000°/s
- **Resolution**: 16-bit
- **Sample Rate**: 1Hz - 1000Hz (configurable)
- **Units**: degrees per second (°/s)

### Magnetometer
- **Range**: ±4900 μT
- **Resolution**: 16-bit
- **Sample Rate**: 1Hz - 1000Hz (configurable)
- **Units**: microtesla (μT)

## 🔧 Technical Details

### Hardware
- **Processor**: ARM Cortex-M4
- **Memory**: 512KB Flash, 128KB RAM
- **Battery**: 3.7V LiPo (rechargeable)
- **Connectivity**: Bluetooth 4.0/5.0
- **Operating Temperature**: -40°C to +85°C

### Firmware
- **Version**: Latest MetaWear firmware
- **Update Method**: Over-the-air (OTA)
- **Compatibility**: MetaWear SDK v3.0+

## 📡 Communication Protocol

### Bluetooth Low Energy (BLE)
- **Service UUID**: `326a9000-85cb-9195-d9dd-464cfbbae75a`
- **Command UUID**: `326a9001-85cb-9195-d9dd-464cfbbae75a`
- **Notify UUID**: `326a9006-85cb-9195-d9dd-464cfbbae75a`

### Data Format
- **Raw Data**: 16-bit signed integers
- **Calibration**: Factory calibrated
- **Scaling**: Handled by MetaWear SDK

## 🎯 Use Cases

### Motion Tracking
- **Activity Recognition**: Walking, running, sitting
- **Gesture Detection**: Hand movements, gestures
- **Orientation**: Device orientation in 3D space

### Sports & Fitness
- **Throw Analysis**: Baseball, football, etc.
- **Golf Swing**: Club head tracking
- **Running**: Gait analysis, stride length

### Research & Development
- **Biomechanics**: Human movement analysis
- **Robotics**: Motion control systems
- **VR/AR**: Motion tracking for virtual environments

## 🔋 Power Management

### Battery Life
- **Typical Usage**: 8-12 hours continuous streaming
- **Standby Mode**: 30+ days
- **Charging Time**: 2-3 hours

### Power Modes
- **Active**: Full sensor operation
- **Standby**: Low power, wake on motion
- **Sleep**: Minimal power consumption

## 🛠️ Development Notes

### What We Learned
- **Official SDK Required**: Manual BLE communication is complex
- **Data Scaling**: SDK handles calibration and scaling automatically
- **Platform Support**: Swift SDK works natively on macOS
- **Real-time Streaming**: Combine framework provides reactive data flow

### Key Insights
- **Use Official Functions**: Let MbientLab handle the complex parts
- **Proper Initialization**: Device setup is crucial for reliable operation
- **Error Handling**: BLE connections can be unstable
- **Data Processing**: SDK provides clean, calibrated data

## 📈 Performance Characteristics

### Data Quality
- **Accuracy**: ±2% typical
- **Precision**: 16-bit resolution
- **Latency**: <10ms typical
- **Jitter**: <1ms typical

### Reliability
- **Connection Stability**: 99%+ uptime
- **Data Integrity**: CRC protected
- **Error Recovery**: Automatic reconnection
- **Firmware Updates**: OTA capability

## 🎯 Project Goals

### Primary Objectives
1. **Connect to MetaMotionRL** using official Swift SDK
2. **Stream accelerometer data** in real-time
3. **Display data** in macOS GUI
4. **Use official functions** for all sensor operations

### Success Criteria
- [ ] Stable BLE connection
- [ ] Real-time data streaming
- [ ] Accurate sensor readings
- [ ] Responsive UI updates
- [ ] Error-free operation

---

**This device information helps guide our implementation approach and ensures we use the correct API methods.** 