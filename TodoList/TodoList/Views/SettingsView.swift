import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var taskStore: TaskStore
    @State private var showClearConfirmation = false
    @State private var showBackupView = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("外观")) {
                    Picker("主题", selection: $appSettings.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.displayName)
                            }
                            .tag(theme)
                        }
                    }
                    
                    Picker("主色调", selection: $appSettings.accentColor) {
                        ForEach(AppAccentColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                                Text(color.displayName)
                            }
                            .tag(color)
                        }
                    }
                    
                    Toggle("启用动画", isOn: $appSettings.enableAnimations)
                }
                
                Section(header: Text("任务")) {
                    Toggle("显示已完成任务", isOn: $appSettings.showCompletedTasks)
                    
                    Picker("默认排序方式", selection: $appSettings.defaultTaskSortOption) {
                        ForEach(TaskSortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    
                    Toggle("自动归档已完成任务", isOn: $appSettings.autoArchiveCompletedTasks)
                    
                    if appSettings.autoArchiveCompletedTasks {
                        Stepper("归档等待时间: \(appSettings.daysBeforeAutoArchive) 天", 
                                value: $appSettings.daysBeforeAutoArchive, 
                                in: 1...30)
                    }
                }
                
                Section(header: Text("数据管理")) {
                    NavigationLink(destination: BackupListView()) {
                        HStack {
                            Image(systemName: "arrow.clockwise.icloud")
                            Text("备份和恢复")
                        }
                    }
                    
                    Button(action: {
                        showClearConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("清除所有任务")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    Button("重置所有设置") {
                        appSettings.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
        }
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
        List {
            Section(header: Text("创建备份")) {
                Button(action: createBackup) {
                    Label(
                        isBackingUp ? "备份中..." : "创建新备份",
                        systemImage: "square.and.arrow.down"
                    )
                }
                .disabled(isBackingUp)
            }
            
            Section(header: Text("可用备份")) {
                if backupFiles.isEmpty {
                    Text("没有可用的备份")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
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
                    }
                }
            }
            
            if selectedRestoreFile != nil {
                Section {
                    Button(action: restoreBackup) {
                        Label(
                            isRestoring ? "恢复中..." : "恢复所选备份",
                            systemImage: "arrow.clockwise"
                        )
                    }
                    .foregroundColor(.blue)
                    .disabled(isRestoring)
                }
            }
        }
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
            HStack {
                VStack(alignment: .leading) {
                    Text(file.lastPathComponent)
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
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
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