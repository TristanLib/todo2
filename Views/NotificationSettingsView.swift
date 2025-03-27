import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode
    
    @State private var enableNotifications: Bool
    @State private var notifyBeforeDueDate: Bool
    @State private var notifyHoursBeforeDueDate: Int
    @State private var showPermissionAlert = false
    
    init(appSettings: AppSettings) {
        _enableNotifications = State(initialValue: appSettings.enableNotifications)
        _notifyBeforeDueDate = State(initialValue: appSettings.notifyBeforeDueDate)
        _notifyHoursBeforeDueDate = State(initialValue: appSettings.notifyHoursBeforeDueDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: SettingsSectionHeader(title: "通知设置", systemImage: "bell.badge.fill", tintColor: appSettings.accentColor.color)) {
                    ToggleSettingRow(
                        title: "启用通知",
                        description: "接收关于任务的重要提醒",
                        isOn: $enableNotifications,
                        accentColor: appSettings.accentColor.color
                    )
                    .onChange(of: enableNotifications) { newValue in
                        if newValue {
                            checkNotificationPermission()
                        }
                    }
                }
                
                if enableNotifications {
                    Section(header: Text("任务提醒")) {
                        ToggleSettingRow(
                            title: "到期前提醒",
                            description: "在任务到期前收到提醒",
                            isOn: $notifyBeforeDueDate,
                            accentColor: appSettings.accentColor.color
                        )
                        
                        if notifyBeforeDueDate {
                            StepperSettingRow(
                                title: "提前提醒时间",
                                value: $notifyHoursBeforeDueDate,
                                range: 1...72,
                                unit: "小时",
                                accentColor: appSettings.accentColor.color
                            )
                        }
                    }
                    
                    Section(header: Text("提示")) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(appSettings.accentColor.color)
                            
                            Text("请确保在系统设置中允许应用发送通知，否则您将无法收到提醒")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("通知设置")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveSettings()
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showPermissionAlert) {
                Alert(
                    title: Text("需要通知权限"),
                    message: Text("请在系统设置中允许应用发送通知以接收任务提醒"),
                    primaryButton: .default(Text("去设置")) {
                        openSettings()
                    },
                    secondaryButton: .cancel(Text("取消")) {
                        enableNotifications = false
                    }
                )
            }
        }
    }
    
    private func saveSettings() {
        appSettings.enableNotifications = enableNotifications
        appSettings.notifyBeforeDueDate = notifyBeforeDueDate
        appSettings.notifyHoursBeforeDueDate = notifyHoursBeforeDueDate
    }
    
    private func checkNotificationPermission() {
        // 这里应该实际检查通知权限
        // 在本示例中，我们只显示一个模拟的提示
        showPermissionAlert = true
    }
    
    private func openSettings() {
        // 在实际应用中，这里应该打开系统设置
        // 因为这是一个示例，我们不做实际操作
        print("打开系统设置")
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView(appSettings: AppSettings())
            .environmentObject(AppSettings())
    }
} 