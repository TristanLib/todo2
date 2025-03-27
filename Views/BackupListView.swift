import SwiftUI

struct BackupListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.presentationMode) var presentationMode
    @State private var backupFiles: [URL] = []
    @State private var showingAlert = false
    @State private var selectedBackupURL: URL?
    @State private var alertType: AlertType = .restore
    @State private var isLoading = false
    @State private var showingShareSheet = false
    @State private var messageText = ""
    @State private var showingMessage = false
    
    enum AlertType {
        case restore, delete
    }
    
    var body: some View {
        List {
            if backupFiles.isEmpty {
                Text("暂无备份文件")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(backupFiles, id: \.self) { file in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(file.lastPathComponent)
                                .fontWeight(.medium)
                            
                            Text(formattedDate(from: file.lastPathComponent))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Menu {
                            Button(action: {
                                selectedBackupURL = file
                                alertType = .restore
                                showingAlert = true
                            }) {
                                Label("恢复备份", systemImage: "arrow.clockwise")
                            }
                            
                            Button(action: {
                                selectedBackupURL = file
                                showingShareSheet = true
                            }) {
                                Label("分享", systemImage: "square.and.arrow.up")
                            }
                            
                            Button(action: {
                                selectedBackupURL = file
                                alertType = .delete
                                showingAlert = true
                            }) {
                                Label("删除", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("备份管理")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: createBackup) {
                    Label("新建备份", systemImage: "plus")
                }
            }
        }
        .onAppear {
            refreshBackupList()
        }
        .alert(isPresented: $showingAlert) {
            switch alertType {
            case .restore:
                return Alert(
                    title: Text("恢复备份"),
                    message: Text("确定要恢复此备份吗？当前的所有任务数据将被替换。"),
                    primaryButton: .destructive(Text("恢复")) {
                        restoreBackup()
                    },
                    secondaryButton: .cancel()
                )
            case .delete:
                return Alert(
                    title: Text("删除备份"),
                    message: Text("确定要删除此备份吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("删除")) {
                        deleteBackup()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            Text("请稍候...")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.7))
                        .cornerRadius(10)
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
        )
        .sheet(isPresented: $showingShareSheet) {
            if let url = selectedBackupURL {
                ActivityViewController(activityItems: [url])
            }
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
    
    private func refreshBackupList() {
        backupFiles = taskStore.getBackupFiles().sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
    
    private func formattedDate(from filename: String) -> String {
        // 从文件名 TodoBackup_YYYY-MM-DD_HH-MM-SS.json 提取日期
        let components = filename
            .replacingOccurrences(of: "TodoBackup_", with: "")
            .replacingOccurrences(of: ".json", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: "/")
        
        return components
    }
    
    private func createBackup() {
        isLoading = true
        
        taskStore.backupData { result in
            isLoading = false
            
            switch result {
            case .success(_):
                showMessage("备份创建成功")
                refreshBackupList()
            case .failure(let error):
                showMessage("备份失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func restoreBackup() {
        guard let url = selectedBackupURL else { return }
        
        isLoading = true
        
        taskStore.restoreData(from: url) { result in
            isLoading = false
            
            switch result {
            case .success(_):
                showMessage("数据恢复成功")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            case .failure(let error):
                showMessage("恢复失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteBackup() {
        guard let url = selectedBackupURL else { return }
        
        if taskStore.deleteBackupFile(at: url) {
            showMessage("备份已删除")
            refreshBackupList()
        } else {
            showMessage("删除备份失败")
        }
    }
    
    private func showMessage(_ message: String) {
        messageText = message
        showingMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingMessage = false
        }
    }
}

// 用于分享文件的UIViewControllerRepresentable
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

struct BackupListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BackupListView()
                .environmentObject(TaskStore())
        }
    }
} 