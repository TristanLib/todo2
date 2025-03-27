import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode
    
    @State private var theme: AppTheme
    @State private var accentColor: AppAccentColor
    @State private var enableAnimations: Bool
    @State private var showCompletedTasks: Bool
    
    init(appSettings: AppSettings) {
        _theme = State(initialValue: appSettings.theme)
        _accentColor = State(initialValue: appSettings.accentColor)
        _enableAnimations = State(initialValue: appSettings.enableAnimations)
        _showCompletedTasks = State(initialValue: appSettings.showCompletedTasks)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: SettingsSectionHeader(title: "主题", systemImage: "paintpalette.fill", tintColor: accentColor.color)) {
                    ThemePickerRow(selectedTheme: $theme, accentColor: accentColor.color)
                }
                
                Section(header: SettingsSectionHeader(title: "强调色", systemImage: "circle.fill", tintColor: accentColor.color)) {
                    ColorPickerRow(selectedColor: $accentColor)
                }
                
                Section(header: SettingsSectionHeader(title: "界面选项", systemImage: "slider.horizontal.3", tintColor: accentColor.color)) {
                    ToggleSettingRow(
                        title: "启用动画",
                        description: "界面过渡和交互动画效果",
                        isOn: $enableAnimations,
                        accentColor: accentColor.color
                    )
                    
                    ToggleSettingRow(
                        title: "显示已完成任务",
                        description: "在任务列表中显示已完成任务",
                        isOn: $showCompletedTasks,
                        accentColor: accentColor.color
                    )
                }
                
                previewSection
            }
            .navigationTitle("外观设置")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveSettings()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .accentColor(accentColor.color)
    }
    
    var previewSection: some View {
        Section(header: SettingsSectionHeader(title: "预览", systemImage: "eye.fill", tintColor: accentColor.color)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("当前样式预览")
                    .font(.headline)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 12) {
                        Text("强调色示例")
                            .font(.headline)
                            .foregroundColor(accentColor.color)
                        
                        Divider()
                        
                        HStack(spacing: 10) {
                            Button(action: {}) {
                                Text("按钮")
                            }
                            .buttonStyle(.bordered)
                            
                            Toggle("", isOn: .constant(true))
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: accentColor.color))
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("进度示例")
                            Spacer()
                            Text("75%")
                        }
                        
                        ProgressView(value: 0.75)
                            .accentColor(accentColor.color)
                    }
                    .padding()
                }
                .frame(height: 160)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func saveSettings() {
        appSettings.theme = theme
        appSettings.accentColor = accentColor
        appSettings.enableAnimations = enableAnimations
        appSettings.showCompletedTasks = showCompletedTasks
    }
}

struct AppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSettingsView(appSettings: AppSettings())
            .environmentObject(AppSettings())
    }
} 