import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    
    @State private var showAppearanceSettings = false
    @State private var showFocusSettings = false
    @State private var showNotificationSettings = false
    @State private var showTaskSettings = false
    @State private var showResetConfirmation = false
    @State private var messageText = ""
    @State private var showingMessage = false
    
    var body: some View {
        NavigationView {
            Form {
                // 外观设置
                Section(header: SettingsSectionHeader(title: "外观", systemImage: "paintbrush.fill", tintColor: appSettings.accentColor.color)) {
                    Button(action: { showAppearanceSettings = true }) {
                        SettingsRow(title: "主题和颜色", icon: "circle.lefthalf.filled", iconColor: appSettings.accentColor.color, hasNavigation: true) {
                            Text(appSettings.theme.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ToggleSettingRow(
                        title: "显示已完成任务",
                        description: "在任务列表中显示已完成的任务",
                        isOn: $appSettings.showCompletedTasks,
                        accentColor: appSettings.accentColor.color
                    )
                    
                    ToggleSettingRow(
                        title: "启用动画效果",
                        description: "界面切换和交互的动画效果",
                        isOn: $appSettings.enableAnimations,
                        accentColor: appSettings.accentColor.color
                    )
                }
                
                // 专注模式设置
                Section(header: SettingsSectionHeader(title: "专注模式", systemImage: "timer", tintColor: appSettings.accentColor.color)) {
                    Button(action: { showFocusSettings = true }) {
                        SettingsRow(title: "时间设置", icon: "clock.fill", iconColor: appSettings.accentColor.color, hasNavigation: true) {
                            Text("\(Int(appSettings.focusSettings.focusDuration))分钟专注")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ToggleSettingRow(
                        title: "专注结束提示音",
                        isOn: Binding(
                            get: { appSettings.focusSettings.enableSound },
                            set: { newValue in
                                var updatedSettings = appSettings.focusSettings
                                updatedSettings.enableSound = newValue
                                appSettings.focusSettings = updatedSettings
                            }
                        ),
                        accentColor: appSettings.accentColor.color
                    )
                }
                
                // 通知设置
                Section(header: SettingsSectionHeader(title: "通知", systemImage: "bell.badge.fill", tintColor: appSettings.accentColor.color)) {
                    Button(action: { showNotificationSettings = true }) {
                        SettingsRow(title: "通知设置", icon: "bell.fill", iconColor: appSettings.accentColor.color, hasNavigation: true) {
                            Text(appSettings.enableNotifications ? "已启用" : "已禁用")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 数据管理
                Section(header: SettingsSectionHeader(title: "数据管理", systemImage: "externaldrive.fill", tintColor: appSettings.accentColor.color)) {
                    NavigationLink(destination: BackupListView()) {
                        SettingsRow(title: "备份与恢复", icon: "arrow.clockwise.icloud", iconColor: .blue)
                    }
                    
                    Button(action: confirmClearData) {
                        SettingsRow(title: "清除所有数据", icon: "trash", iconColor: .red)
                    }
                }
                
                // 其他设置
                Section(header: SettingsSectionHeader(title: "其他", systemImage: "gearshape.fill", tintColor: appSettings.accentColor.color)) {
                    Button(action: { showResetConfirmation = true }) {
                        SettingsRow(title: "重置所有设置", icon: "arrow.counterclockwise", iconColor: .orange)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(title: "关于", icon: "info.circle.fill", iconColor: .blue)
                    }
                }
            }
            .navigationTitle("设置")
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
            .sheet(isPresented: $showAppearanceSettings) {
                AppearanceSettingsView(appSettings: appSettings)
                    .environmentObject(appSettings)
            }
            .sheet(isPresented: $showFocusSettings) {
                FocusSettingsView(originalSettings: appSettings.focusSettings)
                    .environmentObject(appSettings)
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView(appSettings: appSettings)
                    .environmentObject(appSettings)
            }
            .alert(isPresented: $showResetConfirmation) {
                Alert(
                    title: Text("重置所有设置"),
                    message: Text("确定要将所有设置恢复为默认值吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("重置")) {
                        resetSettings()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func confirmClearData() {
        let alert = UIAlertController(title: "清除所有数据", message: "确定要删除所有任务数据吗？此操作无法撤销。", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清除", style: .destructive) { _ in
            clearAllData()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func clearAllData() {
        taskStore.clearAllData {
            showMessage("所有数据已清除")
        }
    }
    
    private func resetSettings() {
        appSettings.resetToDefaults()
        showMessage("所有设置已重置")
    }
    
    private func showMessage(_ message: String) {
        messageText = message
        showingMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingMessage = false
        }
    }
}

struct SettingsRow<Content: View>: View {
    var title: String
    var icon: String
    var iconColor: Color
    var hasNavigation: Bool = false
    var content: Content?
    
    init(title: String, icon: String, iconColor: Color, hasNavigation: Bool = false, @ViewBuilder content: () -> Content? = { nil }) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.hasNavigation = hasNavigation
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .cornerRadius(6)
            
            Text(title)
            
            Spacer()
            
            if let content = content {
                content
            }
            
            if hasNavigation {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

struct AboutView: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("待办事项")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("版本 1.0.0")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            Section(header: Text("联系我们")) {
                Button(action: contactSupport) {
                    HStack {
                        Text("技术支持")
                        Spacer()
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Button(action: visitWebsite) {
                    HStack {
                        Text("访问网站")
                        Spacer()
                        Image(systemName: "safari.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text("法律信息")) {
                NavigationLink(destination: Text("隐私政策内容").padding()) {
                    Text("隐私政策")
                }
                
                NavigationLink(destination: Text("使用条款内容").padding()) {
                    Text("使用条款")
                }
                
                NavigationLink(destination: licenseView) {
                    Text("开源许可")
                }
            }
        }
        .navigationTitle("关于")
        .listStyle(InsetGroupedListStyle())
    }
    
    private var licenseView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("开源许可")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Group {
                    Text("本应用使用了以下开源组件：")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text("SwiftUI - Apple 开发的用户界面框架")
                    Text("CoreData - Apple 开发的数据持久化框架")
                    
                    Text("MIT 许可证")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text("特此免费授予任何获得本软件和相关文档文件（"软件"）副本的人无限制地处理本软件的权利，包括无限制地使用、复制、修改、合并、发布、分发、再许可和/或销售本软件的副本，并允许本软件的使用者这样做，但须符合以下条件...")
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationTitle("开源许可")
    }
    
    private func contactSupport() {
        openURL(URL(string: "mailto:support@example.com")!)
    }
    
    private func visitWebsite() {
        openURL(URL(string: "https://example.com")!)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
    }
} 
} 