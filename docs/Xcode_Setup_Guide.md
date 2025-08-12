# 🛠️ Xcode Setup Guide

Complete step-by-step instructions for creating a MetaWear macOS app in Xcode.

## 📋 Prerequisites

- **macOS** (10.15 or later)
- **Xcode** (13.0 or later)
- **MetaMotionRL sensor** (powered on and discoverable)

## 🚀 Step-by-Step Setup

### 1. Create New Xcode Project

1. **Open Xcode**
2. **Click "Create a new Xcode project"**
3. **Choose template:**
   - Platform: **macOS**
   - Template: **App**
   - Click **Next**

4. **Configure project:**
   - Product Name: `MetaWearSwiftApp`
   - Team: Your personal team (or None)
   - Organization Identifier: `com.yourname` (or `com.mbientlabs`)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Use Core Data: ❌ (uncheck)
   - Include Tests: ❌ (uncheck)
   - Click **Next**

5. **Choose location:**
   - Save in your preferred directory
   - Click **Create**

### 2. Add MetaWear SDK

1. **In Xcode menu:**
   - File → Add Package Dependencies

2. **Enter package URL:**
   ```
   https://github.com/mbientlab/MetaWear-Swift-Combine-SDK
   ```

3. **Click "Add Package"**

4. **Select target:**
   - Choose your `MetaWearSwiftApp` target
   - Click **Add Package**

### 3. Replace ContentView.swift

1. **In Xcode navigator:**
   - Click on `ContentView.swift`

2. **Select all content:**
   - Cmd+A to select all
   - Delete the default content

3. **Paste new code:**
   - Copy code from `Working_Code.swift`
   - Paste into ContentView.swift

### 4. Build and Test

1. **Build project:**
   - Cmd+B or Product → Build

2. **Run app:**
   - Cmd+R or Product → Run

3. **Expected result:**
   - App should launch
   - Shows "Not Connected" status
   - Connect button should be enabled

## 🔧 Project Structure

After setup, your project should look like:

```
MetaWearSwiftApp/
├── MetaWearSwiftAppApp.swift    # App entry point (don't change)
├── ContentView.swift            # Main UI (replaced with our code)
├── Assets.xcassets/             # App icons and images
├── Preview Content/             # SwiftUI preview assets
└── Package Dependencies/        # MetaWear SDK (auto-added)
```

## ✅ Verification Checklist

- [ ] Xcode project created successfully
- [ ] MetaWear SDK package added
- [ ] ContentView.swift replaced with working code
- [ ] Project builds without errors
- [ ] App runs and shows UI
- [ ] No compilation warnings

## 🐛 Common Issues

### SDK Not Found
- **Problem**: `import MetaWear` fails
- **Solution**: Ensure package dependency is added to the correct target

### Build Errors
- **Problem**: Swift syntax errors
- **Solution**: Check Xcode version compatibility (Xcode 13+ required)

### Permission Issues
- **Problem**: Bluetooth access denied
- **Solution**: Grant Bluetooth permissions in System Preferences

## 🎯 Next Steps After Setup

1. **Test basic UI** - Verify app launches correctly
2. **Research MetaWear API** - Check SDK documentation
3. **Implement real connection** - Replace simulation code
4. **Add accelerometer streaming** - Use official SDK functions

## 📚 Additional Resources

- [Xcode Documentation](https://developer.apple.com/xcode/)
- [SwiftUI Tutorial](https://developer.apple.com/tutorials/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)

---

**Your Xcode project is now ready for MetaWear development! 🍎✨** 