import Foundation
import SwiftUI

// 应用主题
enum AppTheme: String, CaseIterable, Codable {
    case system = "system"  // 跟随系统
    case light = "light"    // 浅色
    case dark = "dark"      // 深色
    
    var icon: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "浅色模式"
        case .dark:
            return "深色模式"
        }
    }
}

// 主色调
enum AppAccentColor: String, CaseIterable, Codable {
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case teal = "teal"
    
    var color: Color {
        switch self {
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .teal:
            return .teal
        }
    }
    
    var displayName: String {
        switch self {
        case .blue:
            return "蓝色"
        case .purple:
            return "紫色"
        case .pink:
            return "粉色"
        case .red:
            return "红色"
        case .orange:
            return "橙色"
        case .yellow:
            return "黄色"
        case .green:
            return "绿色"
        case .teal:
            return "青色"
        }
    }
}

// 任务排序方式
enum TaskSortOption: String, CaseIterable, Codable {
    case dueDate = "dueDate"        // 按截止日期
    case priority = "priority"      // 按优先级
    case createdAt = "createdAt"    // 按创建日期
    case title = "title"            // 按标题字母顺序
    
    var displayName: String {
        switch self {
        case .dueDate:
            return "截止日期"
        case .priority:
            return "优先级"
        case .createdAt:
            return "创建日期"
        case .title:
            return "标题"
        }
    }
}

// 专注模式设置
struct FocusSettings: Codable {
    var focusDuration: Double = 25      // 专注时长（分钟）
    var shortBreakDuration: Double = 5  // 短休息时长（分钟）
    var longBreakDuration: Double = 15  // 长休息时长（分钟）
    var pomoBeforeBreak: Int = 4        // 进行长休息前的专注次数
    var enableSound: Bool = true        // 启用音效
    var enableNotification: Bool = true // 启用通知
}

// 通知设置结构
struct NotificationSettings: Codable {
    var enableNotifications: Bool = true        // 总通知开关
    var notifyBeforeDueDate: Bool = true        // 在截止时间前通知
    var notifyHoursBeforeDueDate: Int = 24      // 提前多少小时通知
    var enableFocusModeNotifications: Bool = true // 专注模式通知
}

// 应用设置
class AppSettings: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "appSettings"
    
    // UI 设置
    @Published var theme: AppTheme = .system {
        didSet { queueSaveSettings() }
    }
    
    @Published var accentColor: AppAccentColor = .blue {
        didSet { queueSaveSettings() }
    }
    
    @Published var enableAnimations: Bool = true {
        didSet { queueSaveSettings() }
    }
    
    @Published var showCompletedTasks: Bool = true {
        didSet { queueSaveSettings() }
    }
    
    // 任务设置
    @Published var defaultTaskSortOption: TaskSortOption = .dueDate {
        didSet { queueSaveSettings() }
    }
    
    @Published var autoArchiveCompletedTasks: Bool = false {
        didSet { queueSaveSettings() }
    }
    
    @Published var daysBeforeAutoArchive: Int = 7 {
        didSet { queueSaveSettings() }
    }
    
    // 通知设置
    @Published var notificationSettings: NotificationSettings = NotificationSettings() {
        didSet { queueSaveSettings() }
    }
    
    // 专注模式设置
    @Published var focusSettings: FocusSettings = FocusSettings() {
        didSet { queueSaveSettings() }
    }
    
    // 防抖动计时器，避免频繁保存
    private var saveWorkItem: DispatchWorkItem?
    
    init() {
        // 直接加载设置
        loadSettings()
    }
    
    // 使用防抖动延迟保存设置
    private func queueSaveSettings() {
        saveWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveSettings()
        }
        
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    func saveSettings() {
        let encoder = JSONEncoder()
        
        do {
            let settings = SettingsData(
                theme: theme,
                accentColor: accentColor,
                enableAnimations: enableAnimations,
                showCompletedTasks: showCompletedTasks,
                defaultTaskSortOption: defaultTaskSortOption,
                autoArchiveCompletedTasks: autoArchiveCompletedTasks,
                daysBeforeAutoArchive: daysBeforeAutoArchive,
                notificationSettings: notificationSettings,
                focusSettings: focusSettings,
                completedFocusSessions: FocusTimerManager.shared.completedFocusSessions
            )
            
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: settingsKey)
        } catch {
            print("保存设置失败: \(error.localizedDescription)")
        }
    }
    
    // 加载设置
    private func loadSettings() {
        guard let data = userDefaults.data(forKey: settingsKey) else { return }
        
        let decoder = JSONDecoder()
        
        do {
            let settings = try decoder.decode(SettingsData.self, from: data)
            
            // UI 设置
            self.theme = settings.theme
            self.accentColor = settings.accentColor
            self.enableAnimations = settings.enableAnimations
            self.showCompletedTasks = settings.showCompletedTasks
            
            // 任务设置
            self.defaultTaskSortOption = settings.defaultTaskSortOption
            self.autoArchiveCompletedTasks = settings.autoArchiveCompletedTasks
            self.daysBeforeAutoArchive = settings.daysBeforeAutoArchive
            
            // 通知设置
            self.notificationSettings = settings.notificationSettings
            
            // 专注模式设置
            self.focusSettings = settings.focusSettings
            
            // 异步加载专注次数，避免在初始化期间直接修改另一个 ObservableObject
            DispatchQueue.main.async {
                FocusTimerManager.shared.completedFocusSessions = settings.completedFocusSessions ?? 0
            }
        } catch {
            print("加载设置失败: \(error.localizedDescription)")
        }
    }
    
    // 重置为默认设置
    func resetToDefaults() {
        // UI 设置
        self.theme = .system
        self.accentColor = .blue
        self.enableAnimations = true
        self.showCompletedTasks = true
        
        // 任务设置
        self.defaultTaskSortOption = .dueDate
        self.autoArchiveCompletedTasks = false
        self.daysBeforeAutoArchive = 7
        
        // 通知设置
        self.notificationSettings = NotificationSettings()
        
        // 专注模式设置
        self.focusSettings = FocusSettings()
        
        // 重置专注次数
        FocusTimerManager.shared.completedFocusSessions = 0
        
        saveSettings()
    }
}

// 用于存储和解码的数据结构
private struct SettingsData: Codable {
    // UI 设置
    let theme: AppTheme
    let accentColor: AppAccentColor
    let enableAnimations: Bool
    let showCompletedTasks: Bool
    
    // 任务设置
    let defaultTaskSortOption: TaskSortOption
    let autoArchiveCompletedTasks: Bool
    let daysBeforeAutoArchive: Int
    
    // 通知设置
    let notificationSettings: NotificationSettings
    
    // 专注模式设置
    let focusSettings: FocusSettings
    
    // 专注次数
    let completedFocusSessions: Int?
} 