import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var focusDuration: Double = 25
    @State private var shortBreakDuration: Double = 5
    @State private var longBreakDuration: Double = 15
    @State private var showNotifications = true
    @State private var showCompletedTasks = true
    @State private var darkModeEnabled = false
    @State private var showingClearDataAlert = false
    @State private var messageText = ""
    @State private var showingMessage = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("专注模式")) {
                    VStack {
                        Text("专注时长: \(Int(focusDuration)) 分钟")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Slider(value: $focusDuration, in: 5...60, step: 5)
                    }
                    
                    VStack {
                        Text("短休息: \(Int(shortBreakDuration)) 分钟")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Slider(value: $shortBreakDuration, in: 1...15, step: 1)
                    }
                    
                    VStack {
                        Text("长休息: \(Int(longBreakDuration)) 分钟")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Slider(value: $longBreakDuration, in: 5...30, step: 5)
                    }
                }
                
                Section(header: Text("外观")) {
                    Toggle("深色模式", isOn: $darkModeEnabled)
                    
                    Toggle("显示已完成任务", isOn: $showCompletedTasks)
                }
                
                Section(header: Text("通知")) {
                    Toggle("启用通知", isOn: $showNotifications)
                }
                
                Section(header: Text("数据管理")) {
                    NavigationLink(destination: BackupListView()) {
                        Label("备份和恢复", systemImage: "arrow.clockwise.icloud")
                    }
                    
                    Button(action: { showingClearDataAlert = true }) {
                        Label("清除所有数据", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: openDeveloperWebsite) {
                        Text("开发者网站")
                    }
                    
                    Button(action: contactSupport) {
                        Text("联系支持")
                    }
                }
            }
            .navigationTitle("设置")
            .alert(isPresented: $showingClearDataAlert) {
                Alert(
                    title: Text("清除所有数据"),
                    message: Text("您确定要删除所有任务数据吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("清除")) {
                        clearAllData()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
            .overlay(
                ZStack {
                    if showingMessage {
                        VStack {
                            Text(messageText)
                                .padding()
                                .background(Color.secondary.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom))
                    }
                }
                .animation(.easeInOut, value: showingMessage)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func clearAllData() {
        taskStore.clearAllData {
            showMessage("所有数据已清除")
        }
    }
    
    private func showMessage(_ message: String) {
        messageText = message
        showingMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingMessage = false
        }
    }
    
    private func openDeveloperWebsite() {
        if let url = URL(string: "https://developer.example.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func contactSupport() {
        if let url = URL(string: "mailto:support@example.com") {
            UIApplication.shared.open(url)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(TaskStore())
    }
} 