# 📚 MetaWear API Reference

Essential documentation and resources for the MetaWear Swift Combine SDK.

## 🔗 Official Documentation

### Primary Resources
- **[MetaWear Swift Combine SDK](https://github.com/mbientlab/MetaWear-Swift-Combine-SDK)** - Main repository
- **[MetaWear Documentation](https://mbientlab.com/docs/)** - Official docs
- **[Swift Combine Framework](https://developer.apple.com/documentation/combine)** - Apple's reactive framework

### SDK Examples
- **[Swift SDK Examples](https://github.com/mbientlab/MetaWear-Swift-Combine-SDK/tree/main/Examples)** - Code samples
- **[Accelerometer Example](https://github.com/mbientlab/MetaWear-Swift-Combine-SDK/blob/main/Examples/AccelerometerExample.swift)** - Specific to our use case

## 🎯 Key API Concepts

### Core Classes
- **`MetaWear`** - Main device class
- **`MetaWearScanner`** - Device discovery
- **`Accelerometer`** - Accelerometer sensor module
- **`Publisher`** - Combine framework for data streaming

### Common Patterns
```swift
// Device connection
let metawear = MetaWear(deviceAddress: "ea:78:c3:d3:f0:8a")

// Accelerometer setup
let accelerometer = metawear.accelerometer

// Data streaming with Combine
accelerometer.acceleration
    .sink { data in
        // Handle accelerometer data
    }
```

## 📊 Device Specifications

### MetaMotionRL
- **Model**: MetaMotionRL
- **MAC Address**: `ea:78:c3:d3:f0:8a`
- **Sensors**: Accelerometer, Gyroscope, Magnetometer
- **Protocol**: Bluetooth Low Energy (BLE)
- **Data Rate**: Configurable (typically 100Hz)

### Accelerometer Details
- **Range**: ±2g, ±4g, ±8g, ±16g
- **Resolution**: 16-bit
- **Units**: g-force (9.8 m/s²)
- **Data Format**: X, Y, Z values

## 🔧 Implementation Notes

### What We Need to Research
1. **Device Connection API** - How to properly connect to MetaMotionRL
2. **Accelerometer Configuration** - Setting up data rate and range
3. **Data Streaming** - Using Combine publishers for real-time data
4. **Error Handling** - Managing connection failures and timeouts

### Expected API Flow
```swift
// 1. Create MetaWear instance
let metawear = MetaWear(deviceAddress: deviceAddress)

// 2. Connect to device
await metawear.connect()

// 3. Configure accelerometer
metawear.accelerometer.configure(range: .g4, sampleRate: .hz100)

// 4. Start streaming
metawear.accelerometer.acceleration
    .sink { data in
        // Process accelerometer data
    }
```

## 🐛 Common Issues & Solutions

### Connection Problems
- **Device not found**: Ensure MetaMotionRL is powered on
- **Permission denied**: Grant Bluetooth permissions in macOS
- **Timeout**: Check device is in range and discoverable

### Data Issues
- **No data streaming**: Verify accelerometer is configured and started
- **Incorrect values**: Check accelerometer range configuration
- **High latency**: Adjust sample rate settings

## 📈 Next Steps

1. **Study Swift SDK Examples** - Understand the API patterns
2. **Implement Real Connection** - Replace simulation with actual SDK calls
3. **Add Accelerometer Streaming** - Use official data processing
4. **Handle Errors** - Implement proper error handling
5. **Optimize Performance** - Fine-tune data rates and processing

## 🎯 Success Metrics

- [ ] Connect to MetaMotionRL using official SDK
- [ ] Stream real accelerometer data
- [ ] Display data in real-time UI
- [ ] Handle connection errors gracefully
- [ ] Achieve stable data streaming

---

**This reference will be updated as we implement the actual MetaWear functionality.** 