import Foundation
import SwiftUI
import CoreData

class TaskStore: ObservableObject {
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
        _ = coreDataManager.addTask(task: task)
        loadTasks()
    }
    
    func updateTask(_ task: Task) {
        if let cdTask = coreDataManager.getTask(byID: task.id) {
            coreDataManager.updateTask(cdTask, with: task)
            loadTasks()
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
    }
    
    func toggleTaskCompletion(_ task: Task) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updateTask(updatedTask)
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
            
            completion()
        }
    }
    
    func getBackupFiles() -> [URL] {
        return DataManager.shared.getBackupFiles()
    }
    
    func deleteBackupFile(at url: URL) -> Bool {
        return DataManager.shared.deleteBackupFile(at: url)
    }
} 