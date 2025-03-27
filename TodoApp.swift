import SwiftUI

@main
struct TodoApp: App {
    @StateObject private var taskStore = TaskStore()
    @StateObject private var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskStore)
                .environmentObject(appSettings)
                .preferredColorScheme(colorScheme)
                .accentColor(appSettings.accentColor.color)
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appSettings.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
} 