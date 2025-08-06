import Foundation
import SwiftUI
import CoreData
import UserNotifications

class TaskStore: ObservableObject {
    // 单例实例
    static let shared = TaskStore()
    
    @Published var tasks: [Task] = []
    private let coreDataManager = CoreDataManager.shared
    
    init() {
        // 仅在 Core Data 准备好时加载任务
        if PersistenceController.shared.isLoaded {
            initializeStore()
        } else {
            // 监听 Core Data 加载完成通知
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePersistentStoreDidLoad),
                name: .persistentStoreDidLoad,
                object: nil
            )
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handlePersistentStoreDidLoad() {
        DispatchQueue.main.async { [weak self] in
            self?.initializeStore()
        }
    }
    
    private func initializeStore() {
        // 首次运行时进行数据迁移
        coreDataManager.migrateFromUserDefaults()
        
        // 加载任务
        loadTasks()
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        let isFirstTask = tasks.isEmpty
        _ = coreDataManager.addTask(task: task)
        loadTasks()
        updateApplicationBadge()
        
        // 标记用户今日活跃 - 创建任务也算活跃行为
        StreakManager.shared.markTodayAsActive()
        
        // 获得创建任务积分
        UserLevelManager.shared.taskCreated()
        
        // 检测是否是第一个任务
        if isFirstTask {
            AchievementManager.shared.checkTaskAchievements(
                tasksCompleted: 0,
                totalTasks: 1,
                isFirstTask: true,
                totalCompletedEver: getTotalCompletedTasksEver()
            )
        }
    }
    
    func updateTask(_ task: Task) {
        if let cdTask = coreDataManager.getTask(byID: task.id) {
            coreDataManager.updateTask(cdTask, with: task)
            loadTasks()
            updateApplicationBadge()
        }
    }
    
    func deleteTask(_ task: Task) {
        print("开始删除任务: \(task.id)")
        if let cdTask = coreDataManager.getTask(byID: task.id) {
            print("找到对应的 Core Data 任务")
            coreDataManager.deleteTask(cdTask)
            print("Core Data 任务已删除")
            loadTasks()
            print("任务列表已重新加载，当前任务数量: \(tasks.count)")
            updateApplicationBadge()
        } else {
            print("未找到对应的 Core Data 任务: \(task.id)")
        }
    }
    
    func deleteAllTasks() {
        let allTasks = coreDataManager.getAllTasks()
        for task in allTasks {
            coreDataManager.deleteTask(task)
        }
        loadTasks()
        updateApplicationBadge()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task
        let wasIncomplete = !updatedTask.isCompleted
        updatedTask.isCompleted.toggle()
        updateTask(updatedTask)
        
        // 如果任务从未完成变为完成，标记用户今日活跃并检测成就
        if wasIncomplete {
            StreakManager.shared.markTodayAsActive()
            print("📋 TaskStore: 任务完成，标记今日活跃")
            
            // 检查是否是完美一天（所有任务都完成）
            let todayTasks = getTasksDueToday()
            let isPerfectDay = !todayTasks.isEmpty && todayTasks.allSatisfy { $0.isCompleted || $0.id == task.id }
            
            // 获得完成任务积分
            UserLevelManager.shared.taskCompleted(
                isFirstTask: getTotalCompletedTasksEver() == 0,
                isPerfectDay: isPerfectDay
            )
            
            // 检测任务相关成就
            checkTaskAchievements()
        }
    }
    
    // MARK: - Task Filtering
    
    func getCompletedTasks() -> [Task] {
        return tasks.filter { $0.isCompleted }
    }
    
    func getIncompleteTasks() -> [Task] {
        return tasks.filter { !$0.isCompleted }
    }
    
    func getTasks(for category: TaskCategory?) -> [Task] {
        if let category = category {
            return tasks.filter { $0.category == category }
        } else {
            return tasks
        }
    }
    
    func getTasks(for priority: TaskPriority) -> [Task] {
        return tasks.filter { $0.priority == priority }
    }
    
    func getTasksDueToday() -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(calendar.startOfDay(for: dueDate), inSameDayAs: today)
            }
            return false
        }
    }
    
    // MARK: - Persistence
    
    func saveTasks() {
        // Core Data会自动保存，这里主要用于兼容性
        coreDataManager.saveContext()
    }
    
    func loadTasks() {
        print("TaskStore: 开始加载任务")
        let cdTasks = coreDataManager.getAllTasks()
        print("TaskStore: 从 Core Data 获取到 \(cdTasks.count) 个任务")
        tasks = cdTasks.map { coreDataManager.convertToTaskModel($0) }
        print("TaskStore: 任务加载完成，当前任务数量: \(tasks.count)")
        updateApplicationBadge()
    }
    
    // MARK: - Backup and Restore
    
    func backupData(completion: @escaping (Result<URL, Error>) -> Void) {
        DataManager.shared.createBackup(tasks: tasks, completion: completion)
    }
    
    func restoreData(from url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        DataManager.shared.restoreFromFile(at: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let restoredTasks):
                DispatchQueue.main.async {
                    // 清除所有现有的任务
                    let allCDTasks = self.coreDataManager.getAllTasks()
                    for cdTask in allCDTasks {
                        self.coreDataManager.deleteTask(cdTask)
                    }
                    
                    // 添加恢复的任务
                    for task in restoredTasks {
                        _ = self.coreDataManager.addTask(task: task)
                    }
                    
                    // 保存并重新加载
                    self.coreDataManager.saveContext()
                    self.loadTasks()
                    
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func clearAllData(completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 清除所有Core Data中的任务
            let allCDTasks = self.coreDataManager.getAllTasks()
            for cdTask in allCDTasks {
                self.coreDataManager.deleteTask(cdTask)
            }
            
            // 清空内存中的任务
            self.tasks = []
            
            // 更新应用图标标记
            self.updateApplicationBadge()
            
            completion()
        }
    }
    
    func getBackupFiles() -> [URL] {
        return DataManager.shared.getBackupFiles()
    }
    
    func deleteBackupFile(at url: URL) -> Bool {
        return DataManager.shared.deleteBackupFile(at: url)
    }
    
    // MARK: - Application Badge
    
    /// 更新应用图标上的标记，显示未完成任务的数量
    func updateApplicationBadge() {
        let incompleteTasks = getIncompleteTasks()
        let count = incompleteTasks.count
        
        // 如果专注模式正在运行，不要覆盖其标记
        let focusManager = FocusTimerManager.shared
        if focusManager.currentState != .idle && focusManager.currentState != .paused {
            return
        }
        
        // 设置应用图标标记为未完成任务数量
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                print("更新应用图标标记失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Achievement Integration
    
    /// 检测任务相关成就
    private func checkTaskAchievements() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTasks = tasks.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: today) }
        let todayCompletedTasks = todayTasks.filter { $0.isCompleted }
        
        let tasksCompletedToday = todayCompletedTasks.count
        let totalTasksToday = todayTasks.count
        let totalCompletedEver = getTotalCompletedTasksEver()
        
        print("📋 TaskStore: 成就检测 - 今日完成:\(tasksCompletedToday), 今日总数:\(totalTasksToday), 累计完成:\(totalCompletedEver)")
        
        AchievementManager.shared.checkTaskAchievements(
            tasksCompleted: tasksCompletedToday,
            totalTasks: totalTasksToday,
            isFirstTask: false,
            totalCompletedEver: totalCompletedEver
        )
    }
    
    /// 获取累计完成的任务总数
    private func getTotalCompletedTasksEver() -> Int {
        return tasks.filter { $0.isCompleted }.count
    }
} 