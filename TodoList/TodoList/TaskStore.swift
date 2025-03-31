import Foundation
import SwiftUI
import CoreData

class TaskStore: ObservableObject {
    @Published var tasks: [Task] = []
    private let coreDataManager = CoreDataManager.shared
    
    init() {
        // 首次运行时进行数据迁移
        coreDataManager.migrateFromUserDefaults()
        
        // 加载任务
        loadTasks()
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        // 保存到Core Data
        _ = coreDataManager.addTask(task: task)
        
        // 更新内存中的任务列表
        tasks.append(task)
    }
    
    func updateTask(_ task: Task) {
        // 查找Core Data中对应的任务
        if let cdTask = coreDataManager.getTask(byID: task.id) {
            // 更新Core Data中的任务
            coreDataManager.updateTask(cdTask, with: task)
            
            // 更新内存中的任务
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = task
            }
        }
    }
    
    func deleteTask(at indexSet: IndexSet) {
        // 从indexSet中获取任务ID
        for index in indexSet {
            let taskID = tasks[index].id
            
            // 从Core Data中删除
            if let cdTask = coreDataManager.getTask(byID: taskID) {
                coreDataManager.deleteTask(cdTask)
            }
        }
        
        // 从内存中的数组中删除
        tasks.remove(atOffsets: indexSet)
    }
    
    func deleteTask(id: UUID) {
        // 从Core Data中删除
        if let cdTask = coreDataManager.getTask(byID: id) {
            coreDataManager.deleteTask(cdTask)
        }
        
        // 从内存中删除
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks.remove(at: index)
        }
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
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDateInToday(dueDate)
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
        // 从Core Data加载所有任务
        let cdTasks = coreDataManager.getAllTasks()
        
        // 转换为Task模型
        tasks = cdTasks.map { coreDataManager.convertToTaskModel($0) }
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