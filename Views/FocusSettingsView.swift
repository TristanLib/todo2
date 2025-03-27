import SwiftUI

struct FocusSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode
    
    @State private var focusSettings: FocusSettings
    
    init(originalSettings: FocusSettings) {
        _focusSettings = State(initialValue: originalSettings)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: SettingsSectionHeader(title: "时间设置", systemImage: "timer", tintColor: appSettings.accentColor.color)) {
                    SliderSettingRow(
                        title: "专注时长",
                        value: $focusSettings.focusDuration,
                        range: 5...60,
                        step: 5,
                        unit: "分钟",
                        accentColor: appSettings.accentColor.color
                    )
                    
                    SliderSettingRow(
                        title: "短休息时长",
                        value: $focusSettings.shortBreakDuration,
                        range: 1...15,
                        step: 1,
                        unit: "分钟",
                        accentColor: appSettings.accentColor.color
                    )
                    
                    SliderSettingRow(
                        title: "长休息时长",
                        value: $focusSettings.longBreakDuration,
                        range: 5...30,
                        step: 5,
                        unit: "分钟",
                        accentColor: appSettings.accentColor.color
                    )
                    
                    StepperSettingRow(
                        title: "长休息前的专注次数",
                        value: Binding(
                            get: { Int(focusSettings.pomoBeforeBreak) },
                            set: { focusSettings.pomoBeforeBreak = $0 }
                        ),
                        range: 2...6,
                        unit: "次",
                        accentColor: appSettings.accentColor.color
                    )
                }
                
                Section(header: SettingsSectionHeader(title: "提醒", systemImage: "bell.fill", tintColor: appSettings.accentColor.color)) {
                    ToggleSettingRow(
                        title: "启用音效",
                        description: "专注结束时播放提示音",
                        isOn: $focusSettings.enableSound,
                        accentColor: appSettings.accentColor.color
                    )
                    
                    ToggleSettingRow(
                        title: "启用通知",
                        description: "专注结束时显示系统通知",
                        isOn: $focusSettings.enableNotification,
                        accentColor: appSettings.accentColor.color
                    )
                }
                
                Section(header: SettingsSectionHeader(title: "关于专注模式", systemImage: "info.circle", tintColor: appSettings.accentColor.color)) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("专注模式 (番茄工作法)")
                            .font(.headline)
                        
                        Text("番茄工作法是一种时间管理方法，它将工作时间分为25分钟的专注时段和5分钟的休息时段。每完成4个专注时段后，可以进行一次较长的休息。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("专注模式设置")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    appSettings.focusSettings = focusSettings
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FocusSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        FocusSettingsView(originalSettings: FocusSettings())
            .environmentObject(AppSettings())
    }
} 