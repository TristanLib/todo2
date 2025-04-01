import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var taskStore: TaskStore
    @State private var showClearConfirmation = false
    @State private var showBackupView = false
    @State private var showProfileView = false
    @State private var showPreferencesView = false
    @State private var showAppColorPicker = false
    @State private var showReminderTimePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 标题
                    Text("设置")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // 外观设置
                    settingsSection(title: "外观") {
                        // 深色模式切换
                        settingsRow(
                            icon: "moon.fill",
                            iconBackground: Color.purple.opacity(0.2),
                            iconColor: .purple,
                            title: "深色模式",
                            subtitle: "启用深色主题",
                            trailingView: {
                                Toggle("", isOn: Binding(
                                    get: { appSettings.theme == .dark },
                                    set: { newValue in
                                        appSettings.theme = newValue ? .dark : .light
                                    }
                                ))
                                .labelsHidden()
                            }
                        )
                        
                        // 应用主题色
                        Button(action: { showAppColorPicker = true }) {
                            settingsRow(
                                icon: "paintbrush.fill",
                                iconBackground: Color.blue.opacity(0.2),
                                iconColor: .blue,
                                title: "应用颜色",
                                subtitle: "自定义应用强调色",
                                trailingView: {
                                    HStack {
                                        Circle()
                                            .fill(appSettings.accentColor.color)
                                            .frame(width: 20, height: 20)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // 通知设置
                    settingsSection(title: "通知") {
                        // 任务提醒
                        settingsRow(
                            icon: "bell.fill",
                            iconBackground: Color.red.opacity(0.2),
                            iconColor: .red,
                            title: "任务提醒",
                            subtitle: "启用任务通知",
                            trailingView: {
                                Toggle("", isOn: $appSettings.notificationSettings.enableNotifications)
                                    .labelsHidden()
                            }
                        )
                        
                        // 提醒时间
                        Button(action: { showReminderTimePicker = true }) {
                            settingsRow(
                                icon: "clock.fill",
                                iconBackground: Color.orange.opacity(0.2),
                                iconColor: .orange,
                                title: "提醒时间",
                                subtitle: "设置默认提醒时间",
                                trailingView: {
                                    HStack {
                                        Text("\(appSettings.notificationSettings.notifyHoursBeforeDueDate)小时前")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // 账户设置
                    settingsSection(title: "账户") {
                        // 个人资料
                        Button(action: { showProfileView = true }) {
                            settingsRow(
                                icon: "person.fill",
                                iconBackground: Color.green.opacity(0.2),
                                iconColor: .green,
                                title: "个人资料",
                                subtitle: "张三 • user@example.com",
                                trailingView: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 偏好设置
                        Button(action: { showPreferencesView = true }) {
                            settingsRow(
                                icon: "gearshape.fill",
                                iconBackground: Color.gray.opacity(0.2),
                                iconColor: .gray,
                                title: "偏好设置",
                                subtitle: "应用语言、时间格式",
                                trailingView: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // 数据管理
                    settingsSection(title: "数据管理") {
                        // 备份与恢复
                        NavigationLink(destination: BackupListView()) {
                            settingsRow(
                                icon: "arrow.clockwise.icloud",
                                iconBackground: Color.blue.opacity(0.2),
                                iconColor: .blue,
                                title: "备份与恢复",
                                subtitle: "管理您的数据备份",
                                trailingView: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 清除所有任务
                        Button(action: { showClearConfirmation = true }) {
                            settingsRow(
                                icon: "trash.fill",
                                iconBackground: Color.red.opacity(0.2),
                                iconColor: .red,
                                title: "清除所有任务",
                                subtitle: "删除所有待办事项数据",
                                trailingView: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // 退出登录按钮
                    Button(action: {}) {
                        HStack {
                            Spacer()
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("退出登录")
                            }
                            .foregroundColor(.red)
                            .padding()
                            Spacer()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 版本信息
                    HStack {
                        Spacer()
                        Text("版本 1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                }
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .alert(isPresented: $showClearConfirmation) {
                Alert(
                    title: Text("确认清除"),
                    message: Text("这将删除所有任务数据，此操作无法撤销。"),
                    primaryButton: .destructive(Text("删除")) {
                        taskStore.clearAllData {}
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
            .sheet(isPresented: $showAppColorPicker) {
                ColorPickerView(selectedColor: $appSettings.accentColor)
            }
            .sheet(isPresented: $showReminderTimePicker) {
                ReminderTimePickerView(
                    hours: $appSettings.notificationSettings.notifyHoursBeforeDueDate
                )
            }
        }
    }
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 1) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    private func settingsRow<TrailingContent: View>(
        icon: String,
        iconBackground: Color,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder trailingView: () -> TrailingContent
    ) -> some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // 标题和副标题
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 尾部视图（开关、箭头等）
            trailingView()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// 颜色选择器视图
struct ColorPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedColor: AppAccentColor
    
    var body: some View {
        NavigationView {
            List {
                ForEach(AppAccentColor.allCases, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                            
                            Text(color.displayName)
                                .padding(.leading, 8)
                            
                            Spacer()
                            
                            if selectedColor == color {
                                Image(systemName: "checkmark")
                                    .foregroundColor(color.color)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("选择应用颜色")
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// 提醒时间选择器视图
struct ReminderTimePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var hours: Int
    @State private var tempHours: Int
    
    init(hours: Binding<Int>) {
        self._hours = hours
        self._tempHours = State(initialValue: hours.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("提前小时数", selection: $tempHours) {
                    ForEach([1, 2, 3, 6, 12, 24, 48, 72], id: \.self) { hour in
                        Text("\(hour) 小时前").tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
            .navigationTitle("提醒时间")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    hours = tempHours
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct BackupListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var backupFiles: [URL] = []
    @State private var isBackingUp = false
    @State private var backupResult: Result<URL, Error>? = nil
    @State private var showBackupResult = false
    @State private var selectedRestoreFile: URL? = nil
    @State private var isRestoring = false
    @State private var restoreResult: Result<Void, Error>? = nil
    @State private var showRestoreResult = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 创建备份按钮
                Button(action: createBackup) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.headline)
                        Text(isBackingUp ? "备份中..." : "创建新备份")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                }
                .disabled(isBackingUp)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 可用备份列表
                VStack(alignment: .leading, spacing: 16) {
                    Text("可用备份")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if backupFiles.isEmpty {
                        Text("没有可用的备份")
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 1) {
                            ForEach(backupFiles, id: \.absoluteString) { file in
                                BackupFileRow(
                                    file: file,
                                    isSelected: selectedRestoreFile == file,
                                    onSelect: {
                                        self.selectedRestoreFile = file
                                    },
                                    onDelete: {
                                        deleteBackup(file)
                                    }
                                )
                                if file != backupFiles.last {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
                
                // 恢复按钮
                if selectedRestoreFile != nil {
                    Button(action: restoreBackup) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.headline)
                            Text(isRestoring ? "恢复中..." : "恢复所选备份")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                        .foregroundColor(.green)
                    }
                    .disabled(isRestoring)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("备份与恢复")
        .onAppear(perform: loadBackups)
        .alert(isPresented: $showBackupResult) {
            if let result = backupResult {
                switch result {
                case .success(let url):
                    return Alert(
                        title: Text("备份成功"),
                        message: Text("备份已保存到: \(url.lastPathComponent)"),
                        dismissButton: .default(Text("好的"))
                    )
                case .failure(let error):
                    return Alert(
                        title: Text("备份失败"),
                        message: Text(error.localizedDescription),
                        dismissButton: .default(Text("好的"))
                    )
                }
            } else {
                return Alert(
                    title: Text("错误"),
                    message: Text("未知错误"),
                    dismissButton: .default(Text("好的"))
                )
            }
        }
        .alert(isPresented: $showRestoreResult) {
            if let result = restoreResult {
                switch result {
                case .success:
                    return Alert(
                        title: Text("恢复成功"),
                        message: Text("您的数据已成功恢复"),
                        dismissButton: .default(Text("好的"))
                    )
                case .failure(let error):
                    return Alert(
                        title: Text("恢复失败"),
                        message: Text(error.localizedDescription),
                        dismissButton: .default(Text("好的"))
                    )
                }
            } else {
                return Alert(
                    title: Text("错误"),
                    message: Text("未知错误"),
                    dismissButton: .default(Text("好的"))
                )
            }
        }
    }
    
    private func loadBackups() {
        backupFiles = taskStore.getBackupFiles().sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
    
    private func createBackup() {
        isBackingUp = true
        
        taskStore.backupData { result in
            isBackingUp = false
            backupResult = result
            showBackupResult = true
            
            // 刷新备份列表
            loadBackups()
        }
    }
    
    private func deleteBackup(_ file: URL) {
        if taskStore.deleteBackupFile(at: file) {
            if selectedRestoreFile == file {
                selectedRestoreFile = nil
            }
            loadBackups()
        }
    }
    
    private func restoreBackup() {
        guard let fileURL = selectedRestoreFile else { return }
        
        isRestoring = true
        
        taskStore.restoreData(from: fileURL) { result in
            isRestoring = false
            restoreResult = result
            showRestoreResult = true
        }
    }
}

struct BackupFileRow: View {
    let file: URL
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.lastPathComponent)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                       let size = attributes[.size] as? NSNumber,
                       let date = attributes[.creationDate] as? Date {
                        Text("\(formatDate(date)) • \(formatSize(size.intValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatSize(_ size: Int) -> String {
        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = [.useKB, .useMB]
        byteFormatter.countStyle = .file
        return byteFormatter.string(fromByteCount: Int64(size))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppSettings())
            .environmentObject(TaskStore())
    }
} 