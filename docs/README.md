# 🍎 MetaWear macOS App

A native macOS application for connecting to and streaming data from MbientLab MetaWear sensors using the official Swift Combine SDK.

## 🎯 Project Overview

**Goal**: Create a simple, working macOS app that connects to MetaMotionRL sensors and streams accelerometer data using MbientLab's official functions and methods.

**Status**: ✅ Basic UI working, 🔄 Real MetaWear connection in progress

## 🔧 Technical Stack

- **Platform**: macOS (native)
- **Framework**: SwiftUI + Combine
- **SDK**: [MetaWear Swift Combine SDK]()https://github.com/mbientlab/MetaWear-Swift-Combine-SDK
- **IDE**: Xcode
- **Device**: MetaMotionRL sensor

## 📁 Project Structure

```
MetaWear_macOS_App/
├── MetaWearSwiftApp/                 # Xcode project and app sources (canonical)
│   ├── MetaWearSwiftApp.xcodeproj/
│   └── MetaWearSwiftApp/
├── docs/                             # Documentation
└── README.md                         # This file
```

## 🚀 Quick Start

### 1. Open the Xcode Project
1. Open Xcode
2. File → Open…
3. Select `MetaWearSwiftApp/MetaWearSwiftApp.xcodeproj`

### 2. Add MetaWear SDK
1. File → Add Package Dependencies
2. URL: `https://github.com/mbientlab/MetaWear-Swift-Combine-SDK`
3. Add to your target

### 3. Sources
All sources live in `MetaWearSwiftApp/MetaWearSwiftApp/`

### 4. Build and Run
- Should compile without errors
- Shows basic UI with connection simulation

## 📊 Current Features

- ✅ Basic SwiftUI interface
- ✅ Connection status display
- ✅ Device address input
- ✅ Connect/Disconnect buttons
- ✅ Error-free compilation
- 🔄 Real MetaWear connection (in progress)

## 🎯 Next Steps

1. **Research MetaWear Swift SDK API** - Find correct connection methods
2. **Implement real device connection** - Replace simulation with actual SDK calls
3. **Add accelerometer streaming** - Use official SDK functions
4. **Data visualization** - Charts for real-time sensor data
5. **Advanced features** - Velocity calculation, data logging

## 🔗 Key Resources

### Official Documentation
- [MetaWear Swift Combine SDK](https://github.com/mbientlab/MetaWear-Swift-Combine-SDK)
- [MetaWear Documentation](https://mbientlab.com/docs/)
- [Swift Combine Framework](https://developer.apple.com/documentation/combine)

### Device Information
- **Model**: MetaMotionRL
- **MAC Address**: `ea:78:c3:d3:f0:8a`
- **Protocol**: Bluetooth Low Energy (BLE)
- **Data**: Accelerometer, Gyroscope, Magnetometer

### Previous Work
- **Web Bluetooth Approach**: Worked but limited by manual scaling
- **Python SDK**: Linux-only, not suitable for macOS
- **Node.js SDK**: Linux-only, Node.js 12 specific

## 🛠️ Development Notes

### What We Learned
- ✅ Swift SDK works natively on macOS
- ✅ Xcode provides better development experience than command line
- ✅ SwiftUI + Combine is the right approach for reactive data
- ❌ Web Bluetooth requires manual data processing
- ❌ Other SDKs have platform limitations

### Key Insights
- **Official SDK Approach**: Use high-level API calls, not raw GATT commands
- **Platform Choice**: macOS native app is the best path forward
- **Data Processing**: Let the SDK handle scaling and calibration
- **UI Framework**: SwiftUI provides modern, reactive interface

## 🐛 Troubleshooting

### Common Issues
1. **SDK not found**: Ensure package dependency is added correctly
2. **Compilation errors**: Check Swift version compatibility
3. **Bluetooth permissions**: macOS may require permission for BLE access
4. **Device not found**: Ensure MetaMotionRL is powered on and discoverable

### Debug Commands
```bash
# Check Bluetooth status (macOS)
system_profiler SPBluetoothDataType

# Check Xcode version
xcodebuild -version

# Check Swift version
swift --version
```

## 📈 Success Criteria

- [x] Create working macOS app
- [x] Compile without errors
- [x] Basic UI functionality
- [ ] Connect to MetaMotionRL device
- [ ] Stream real accelerometer data
- [ ] Display data in real-time
- [ ] Use official MbientLab functions

## 🎉 Project Goals

**Primary**: Working MetaWear connection using official SDK
**Secondary**: Real-time accelerometer data streaming
**Tertiary**: Data visualization and analysis

---

**This project demonstrates a native macOS approach to MetaWear development, providing a solid foundation for sensor applications on Apple platforms.** 