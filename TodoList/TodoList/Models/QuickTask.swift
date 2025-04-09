import Foundation
import SwiftUI

// 快捷任务模型
struct QuickTask: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var category: CustomCategory?
    var priority: TaskPriority
    var iconName: String
    var colorName: String
    
    init(id: UUID = UUID(), title: String, category: CustomCategory? = nil, priority: TaskPriority = .medium, iconName: String = "star.fill", colorName: String = "blue") {
        self.id = id
        self.title = title
        self.category = category
        self.priority = priority
        self.iconName = iconName
        self.colorName = colorName
    }
    
    // 创建任务实例
    func createTask() -> Task {
        return Task(
            title: title,
            description: "",
            customCategory: category,
            dueDate: Date(), // 默认为当天
            priority: priority,
            isCompleted: false,
            subtasks: []
        )
    }
    
    // 预设的快捷任务
    static let defaultQuickTasks: [QuickTask] = [
        QuickTask(title: NSLocalizedString("冥想", comment: "Quick task meditation"), iconName: "brain.head.profile", colorName: "purple"),
        QuickTask(title: NSLocalizedString("健身", comment: "Quick task workout"), iconName: "figure.strengthtraining.traditional", colorName: "green"),
        QuickTask(title: NSLocalizedString("学习", comment: "Quick task study"), iconName: "book.fill", colorName: "blue"),
        QuickTask(title: NSLocalizedString("跑步", comment: "Quick task running"), iconName: "figure.run", colorName: "orange")
    ]
}

// 快捷任务管理器
class QuickTaskManager: ObservableObject {
    static let shared = QuickTaskManager()
    
    @Published var quickTasks: [QuickTask] = []
    
    private let userDefaultsKey = "quickTasks"
    
    init() {
        loadQuickTasks()
    }
    
    // 加载快捷任务
    private func loadQuickTasks() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                let decoder = JSONDecoder()
                let tasks = try decoder.decode([QuickTask].self, from: data)
                self.quickTasks = tasks
            } catch {
                print("无法解码快捷任务: \(error.localizedDescription)")
                // 如果无法解码，使用默认快捷任务
                self.quickTasks = QuickTask.defaultQuickTasks
            }
        } else {
            // 首次使用，设置默认快捷任务
            self.quickTasks = QuickTask.defaultQuickTasks
            saveQuickTasks()
        }
    }
    
    // 保存快捷任务
    private func saveQuickTasks() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(quickTasks)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("无法编码快捷任务: \(error.localizedDescription)")
        }
    }
    
    // 添加快捷任务
    func addQuickTask(_ task: QuickTask) {
        quickTasks.append(task)
        saveQuickTasks()
    }
    
    // 删除快捷任务
    func deleteQuickTask(_ task: QuickTask) {
        if let index = quickTasks.firstIndex(where: { $0.id == task.id }) {
            quickTasks.remove(at: index)
            saveQuickTasks()
        }
    }
    
    // 更新快捷任务
    func updateQuickTask(_ task: QuickTask) {
        if let index = quickTasks.firstIndex(where: { $0.id == task.id }) {
            quickTasks[index] = task
            saveQuickTasks()
        }
    }
    
    // 重置为默认快捷任务
    func resetToDefault() {
        quickTasks = QuickTask.defaultQuickTasks
        saveQuickTasks()
    }
}
