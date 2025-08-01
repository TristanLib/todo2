//
//  TodoListApp.swift
//  TodoList
//
//  Created by TristanLee on 2025/3/31.
//

import SwiftUI
import UserNotifications

@main
struct TodoListApp: App {
    let persistenceController = PersistenceController.shared
    
    @StateObject private var taskStore = TaskStore()
    @StateObject private var appSettings = AppSettings()
    @StateObject private var categoryManager = CategoryManager()
    @StateObject private var quoteManager = QuoteManager.shared
    private let coreDataManager = CoreDataManager.shared
    
    // 系统管理器
    private let notificationManager = NotificationManager.shared
    private let soundManager = SoundManager.shared
    private let focusTimerManager = FocusTimerManager.shared
    private let streakManager = StreakManager.shared
    
    init() {
        // 应用程序启动时初始化
        print("🚀 TodoListApp: 应用启动，初始化各个管理器")
        
        // 如果启用了通知，请求权限
        if appSettings.notificationSettings.enableNotifications {
            requestNotificationPermission()
        }
        
        // 初始化所有管理器
        soundManager.setEnabled(appSettings.focusSettings.enableSound)
        focusTimerManager.updateSettings(from: appSettings.focusSettings)
        
        // 初始化StreakManager（这会触发状态检查和数据加载）
        _ = streakManager
        print("🚀 TodoListApp: StreakManager 已初始化")
        
        // 配置后台运行支持
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(taskStore)
                .environmentObject(appSettings)
                .environmentObject(categoryManager)
                .environmentObject(quoteManager)
                .preferredColorScheme(colorScheme)
                .accentColor(appSettings.accentColor.color)
                .onAppear {
                    // 在这里注入 CategoryManager 到 CoreDataManager
                    coreDataManager.setup(categoryManager: categoryManager)
                    // 确保 TaskStore 也加载了任务（它内部会使用 CoreDataManager）
                    taskStore.loadTasks()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // 应用程序回到前台时，刷新任务状态
                    taskStore.loadTasks()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // 应用程序进入后台时，保存数据
                    taskStore.saveTasks()
                    appSettings.saveSettings()
                }
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
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
}

// 通知代理，处理通知接收
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    // 前台显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 允许在前台显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    // 处理通知点击
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 获取通知的userInfo内容
        let userInfo = response.notification.request.content.userInfo
        
        // 根据通知类型处理
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "focusStart", "focusEnd", "breakStart", "breakEnd":
                // 打开专注页面
                openFocusView()
            case "taskReminder":
                // 打开任务详情页面
                if let taskId = userInfo["taskId"] as? String {
                    openTaskDetails(taskId: taskId)
                }
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    // 打开专注页面
    private func openFocusView() {
        // 通过NotificationCenter发送通知以切换到专注页面
        NotificationCenter.default.post(name: .openFocusView, object: nil)
    }
    
    // 打开任务详情
    private func openTaskDetails(taskId: String) {
        // 通过NotificationCenter发送通知以打开特定任务
        NotificationCenter.default.post(name: .openTaskDetails, object: nil, userInfo: ["taskId": taskId])
    }
}

// 通知名称扩展
extension Notification.Name {
    static let openFocusView = Notification.Name("openFocusView")
    static let openTaskDetails = Notification.Name("openTaskDetails")
}
