import SwiftUI
import MetaWear
import Combine

/// Example integration showing how to add speed tracking to your existing MetaWear app
struct SpeedIntegrationExample: View {
    @StateObject private var speedCalculator = SpeedCalculator()
    @State private var showingSpeedView = false
    
    // Your existing MetaWear connection (replace with your actual connection)
    #if canImport(MetaWear)
    @State private var metawear: MetaWear?
    #else
    @State private var metawear: Any?
    #endif
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Speed Tracking Integration")
                .font(.title)
                .fontWeight(.bold)
            
            // Speed display card
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Speed")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(speedCalculator.formattedSpeed)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(speedCalculator.isTracking ? .primary : .secondary)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    VStack {
                        Circle()
                            .fill(speedCalculator.isTracking ? Color.green : Color.red)
                            .frame(width: 16, height: 16)
                        Text(speedCalculator.isTracking ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Control buttons
                HStack(spacing: 15) {
                    Button(action: {
                        if speedCalculator.isTracking {
                            speedCalculator.stopSpeedTracking()
                        } else {
                            #if canImport(MetaWear)
                            if let device = metawear {
                                speedCalculator.startSpeedTracking(device: device)
                            }
                            #endif
                        }
                    }) {
                        HStack {
                            Image(systemName: speedCalculator.isTracking ? "stop.circle.fill" : "play.circle.fill")
                            Text(speedCalculator.isTracking ? "Stop" : "Start")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(speedCalculator.isTracking ? Color.red : Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(metawear == nil)
                    
                    Button(action: {
                        speedCalculator.resetSpeed()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(!speedCalculator.isTracking)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // Full speed view button
            Button(action: {
                showingSpeedView = true
            }) {
                HStack {
                    Image(systemName: "speedometer")
                    Text("Open Full Speed View")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // Integration instructions
            VStack(alignment: .leading, spacing: 10) {
                Text("Integration Steps:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    IntegrationStep(number: "1", text: "Add SpeedCalculator to your ContentView")
                    IntegrationStep(number: "2", text: "Connect to your existing MetaWear device")
                    IntegrationStep(number: "3", text: "Start tracking with sensor fusion")
                    IntegrationStep(number: "4", text: "Display speed in mph")
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingSpeedView) {
            // Note: This example needs to be updated to use MetaWearManager
            // For now, we'll use a simplified approach
            VStack {
                Text("Speed Tracking Example")
                    .font(.title)
                Text("This example needs to be updated to use MetaWearManager")
                    .foregroundColor(.secondary)
                Text("See ContentView.swift for the proper implementation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct IntegrationStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - ContentView Integration Example

/// Example showing how to integrate speed tracking into your existing ContentView
/// This is the OLD way - see ContentViewWithSpeedNew below for the proper way
struct ContentViewWithSpeed: View {
    @StateObject private var speedCalculator = SpeedCalculator()
    @State private var selectedTab = 0
    
    // Your existing MetaWear connection
    @State private var metawear: MetaWear?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Your existing accelerometer view
            VStack {
                Text("Accelerometer Data")
                    .font(.title)
                
                // Your existing accelerometer content here
                // ...
                
                // Add speed display
                SpeedDisplayCard(speedCalculator: speedCalculator, metawear: metawear)
            }
            .tabItem {
                Image(systemName: "sensor.tag.radiowaves.forward")
                Text("Sensors")
            }
            .tag(0)
            
            // Dedicated speed tracking tab
            // Note: This example needs to be updated to use MetaWearManager
            VStack {
                Text("Speed Tracking Tab")
                    .font(.title)
                Text("This example needs to be updated to use MetaWearManager")
                    .foregroundColor(.secondary)
                Text("See ContentView.swift for the proper implementation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("Speed")
                }
                .tag(1)
        }
        .onAppear {
            // Initialize your MetaWear connection here
            // metawear = yourMetaWearDevice
        }
    }
}

// SpeedDisplayCard is defined in ContentView.swift

// MARK: - Proper Integration Example

/// Example showing the PROPER way to integrate speed tracking with MetaWearManager
struct ContentViewWithSpeedNew: View {
    @StateObject private var metawearManager = MetaWearManager()
    @StateObject private var speedCalculator = SpeedCalculator()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Connection tab
            ConnectionView(metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Connection")
                }
                .tag(0)
            
            // Speed tracking tab
            SpeedTrackingView(speedCalculator: speedCalculator, metawearManager: metawearManager)
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("Speed")
                }
                .tag(1)
        }
        .onChange(of: metawearManager.isConnected) { isConnected in
            if !isConnected {
                // Stop speed tracking when disconnected
                speedCalculator.stopSpeedTracking()
            }
        }
        .onChange(of: speedCalculator.isTracking) { isTracking in
            if !isTracking {
                // Refresh connection state when tracking stops
                metawearManager.refreshConnectionState()
            }
        }
    }
}

// MARK: - Preview
struct SpeedIntegrationExample_Previews: PreviewProvider {
    static var previews: some View {
        SpeedIntegrationExample()
    }
}

struct ContentViewWithSpeedNew_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewWithSpeedNew()
    }
} 