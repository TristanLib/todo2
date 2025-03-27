import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var focusDuration: Double = 25
    @State private var shortBreakDuration: Double = 5
    @State private var longBreakDuration: Double = 15
    @State private var showNotifications = true
    @State private var showCompletedTasks = true
    @State private var darkModeEnabled = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Focus Timer")) {
                    VStack {
                        Text("Focus Duration: \(Int(focusDuration)) minutes")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Slider(value: $focusDuration, in: 5...60, step: 5)
                    }
                    
                    VStack {
                        Text("Short Break: \(Int(shortBreakDuration)) minutes")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Slider(value: $shortBreakDuration, in: 1...15, step: 1)
                    }
                    
                    VStack {
                        Text("Long Break: \(Int(longBreakDuration)) minutes")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Slider(value: $longBreakDuration, in: 5...30, step: 5)
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                    
                    Toggle("Show Completed Tasks", isOn: $showCompletedTasks)
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $showNotifications)
                }
                
                Section(header: Text("Data Management")) {
                    Button(action: exportData) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: importData) {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: confirmClearData) {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: openDeveloperWebsite) {
                        Text("Developer Website")
                    }
                    
                    Button(action: contactSupport) {
                        Text("Contact Support")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Helper Methods
    
    private func exportData() {
        // Implement data export functionality in future update
    }
    
    private func importData() {
        // Implement data import functionality in future update
    }
    
    private func confirmClearData() {
        // Implement confirmation alert and data clearing in future update
    }
    
    private func openDeveloperWebsite() {
        // Implement website opening in future update
    }
    
    private func contactSupport() {
        // Implement contact support functionality in future update
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(TaskStore())
    }
} 