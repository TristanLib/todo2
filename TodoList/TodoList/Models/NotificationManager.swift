import Foundation
import UserNotifications

// 通知类型枚举
enum NotificationType {
    case focusStart
    case focusEnd
    case breakStart
    case breakEnd
    case taskReminder(taskId: UUID, taskTitle: String)
}

class NotificationManager {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isEnabled = true
    
    private init() {}
    
    // 请求通知权限
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
            
            if let error = error {
                print("通知权限请求错误: \(error.localizedDescription)")
            }
        }
    }
    
    // 检查通知权限
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized
                completion(isAuthorized)
            }
        }
    }
    
    // 设置是否启用通知
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    // 发送通知
    func scheduleNotification(for type: NotificationType, timeInterval: TimeInterval? = nil) {
        guard isEnabled else { return }
        
        // 检查权限状态
        checkAuthorizationStatus { [weak self] granted in
            guard let self = self, granted else { return }
            
            let content = UNMutableNotificationContent()
            var request: UNNotificationRequest
            
            switch type {
            case .focusStart:
                content.title = NSLocalizedString("专注开始", comment: "Focus start notification title")
                content.body = NSLocalizedString("专注时间已开始，请集中注意力完成任务", comment: "Focus start notification body")
                content.sound = .default
                content.userInfo["type"] = "focusStart"
                
                let trigger = timeInterval.map { UNTimeIntervalNotificationTrigger(timeInterval: $0, repeats: false) }
                request = UNNotificationRequest(
                    identifier: "focus_start_\(UUID().uuidString)",
                    content: content,
                    trigger: trigger
                )
                
            case .focusEnd:
                content.title = NSLocalizedString("专注结束", comment: "Focus end notification title")
                content.body = NSLocalizedString("🌸 专注时间已结束，可以休息一下了", comment: "Focus end notification body")
                content.sound = .default
                content.userInfo["type"] = "focusEnd"
                
                let trigger = timeInterval.map { UNTimeIntervalNotificationTrigger(timeInterval: $0, repeats: false) }
                request = UNNotificationRequest(
                    identifier: "focus_end_\(UUID().uuidString)",
                    content: content,
                    trigger: trigger
                )
                
            case .breakStart:
                content.title = NSLocalizedString("休息开始", comment: "Break start notification title")
                content.body = NSLocalizedString("休息时间已开始，请放松一下", comment: "Break start notification body")
                content.sound = .default
                content.userInfo["type"] = "breakStart"
                
                let trigger = timeInterval.map { UNTimeIntervalNotificationTrigger(timeInterval: $0, repeats: false) }
                request = UNNotificationRequest(
                    identifier: "break_start_\(UUID().uuidString)",
                    content: content,
                    trigger: trigger
                )
                
            case .breakEnd:
                content.title = NSLocalizedString("休息结束", comment: "Break end notification title")
                content.body = NSLocalizedString("休息时间已结束，准备开始下一轮专注", comment: "Break end notification body")
                content.sound = .default
                content.userInfo["type"] = "breakEnd"
                
                let trigger = timeInterval.map { UNTimeIntervalNotificationTrigger(timeInterval: $0, repeats: false) }
                request = UNNotificationRequest(
                    identifier: "break_end_\(UUID().uuidString)",
                    content: content,
                    trigger: trigger
                )
                
            case .taskReminder(let taskId, let taskTitle):
                content.title = NSLocalizedString("任务提醒", comment: "Task reminder notification title")
                content.body = NSLocalizedString("任务「\(taskTitle)」即将到期，请尽快完成", comment: "Task reminder notification body")
                content.sound = .default
                content.userInfo["type"] = "taskReminder"
                content.userInfo["taskId"] = taskId.uuidString
                
                let trigger = timeInterval.map { UNTimeIntervalNotificationTrigger(timeInterval: $0, repeats: false) }
                request = UNNotificationRequest(
                    identifier: "task_reminder_\(taskId.uuidString)",
                    content: content,
                    trigger: trigger
                )
            }
            
            // 添加通知请求
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("添加通知请求失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 取消所有待处理的通知
    func cancelAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // 取消特定类型的通知
    func cancelNotifications(withIdentifierPrefix prefix: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    // 取消特定任务的提醒通知
    func cancelTaskReminder(taskId: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["task_reminder_\(taskId.uuidString)"])
    }
} 