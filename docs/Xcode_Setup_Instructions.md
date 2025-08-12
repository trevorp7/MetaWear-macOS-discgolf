# Xcode Setup Instructions - Adding MetaWear SDK

## Problem
Your Xcode project is showing compilation errors because the `MetaWear` module cannot be found. This happens because the MetaWear Swift Combine SDK hasn't been added as a dependency to your project.

## Solution: Add MetaWear SDK as Swift Package Dependency

### Step 1: Open Your Xcode Project
1. Open Xcode
2. Open your project: `~/Desktop/MetaWearSwiftApp/MetaWearSwiftApp.xcodeproj`

### Step 2: Add Swift Package Dependency
1. In Xcode, go to **File** → **Add Package Dependencies...**
2. In the search field, enter the GitHub URL: `https://github.com/mbientlab/MetaWear-Swift-Combine-SDK`
3. Click **Add Package**
4. Select your target (MetaWearSwiftApp) when prompted
5. Click **Add Package**

### Alternative: Add Local Package (if GitHub method doesn't work)
1. In Xcode, go to **File** → **Add Package Dependencies...**
2. Click **Add Local...**
3. Navigate to: `/Users/trevorparker/Documents/MetaWear_macOS_App/MetaWear-Swift-Combine-SDK`
4. Click **Add Package**
5. Select your target when prompted

### Step 3: Verify Package Addition
1. In the Project Navigator, you should see a new section called **Package Dependencies**
2. You should see **MetaWear** listed under your project
3. The package should show as resolved (no red error indicators)

### Step 4: Build and Test
1. Clean the build folder: **Product** → **Clean Build Folder**
2. Build the project: **Product** → **Build**
3. The compilation errors should now be resolved

## Troubleshooting

### If you still see "No such module 'MetaWear'" errors:

1. **Check Package Resolution:**
   - Go to **File** → **Packages** → **Resolve Package Versions**
   - Wait for the resolution to complete

2. **Check Target Dependencies:**
   - Select your project in the navigator
   - Select your target (MetaWearSwiftApp)
   - Go to the **General** tab
   - Scroll down to **Frameworks, Libraries, and Embedded Content**
   - Make sure **MetaWear** is listed there

3. **Check Build Settings:**
   - Select your target
   - Go to **Build Settings**
   - Search for "Framework Search Paths"
   - Make sure the MetaWear framework path is included

4. **Restart Xcode:**
   - Sometimes Xcode needs a restart to recognize new packages
   - Close Xcode completely and reopen

### If the GitHub package doesn't work:

1. **Use the local package method** (described above)
2. **Check your internet connection**
3. **Try a different network** (some corporate networks block GitHub)

## Expected Result

After following these steps:
- ✅ No more "No such module 'MetaWear'" errors
- ✅ `AccelerometerManager.swift` compiles successfully
- ✅ `AccelerometerExample.swift` compiles successfully
- ✅ Your app can import and use the MetaWear SDK

## Next Steps

Once the SDK is successfully added:

1. **Test the Accelerometer Interface:**
   - The app will show simulated data until you connect a real device
   - You can test the UI and functionality

2. **Connect to Real Device:**
   - Update the `MetaWearManager.connect()` method to use the actual SDK
   - Test with your MetaWear hardware

3. **Add More Features:**
   - Implement data logging
   - Add data visualization
   - Create gesture recognition

## Files to Check

After adding the package, these files should compile without errors:
- `AccelerometerManager.swift`
- `AccelerometerExample.swift`
- `ContentView.swift` (if it uses the accelerometer manager)

## Support

If you continue to have issues:
1. Check the [MetaWear Swift Combine SDK documentation](https://github.com/mbientlab/MetaWear-Swift-Combine-SDK)
2. Ensure your Xcode version is compatible (Xcode 12.0+ recommended)
3. Make sure your macOS version supports the SDK (macOS 10.15+) 