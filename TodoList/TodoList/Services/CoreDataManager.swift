import Foundation
import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    private let persistenceController = PersistenceController.shared
    
    private init() {}
    
    var viewContext: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    // MARK: - Task Management
    
    func addTask(task: Task) -> CDTask {
        let cdTask = CDTask(context: viewContext)
        updateCDTask(cdTask, with: task)
        saveContext()
        return cdTask
    }
    
    func updateTask(_ cdTask: CDTask, with task: Task) {
        updateCDTask(cdTask, with: task)
        saveContext()
    }
    
    private func updateCDTask(_ cdTask: CDTask, with task: Task) {
        cdTask.id = task.id
        cdTask.title = task.title
        cdTask.descriptionText = task.description
        cdTask.category = task.category?.rawValue
        cdTask.dueDate = task.dueDate
        cdTask.priority = task.priority.rawValue
        cdTask.isCompleted = task.isCompleted
        cdTask.createdAt = task.createdAt
        
        // 删除所有现有的子任务
        if let existingSubtasks = cdTask.subtasks as? Set<CDSubtask> {
            for subtask in existingSubtasks {
                viewContext.delete(subtask)
            }
        }
        
        // 添加新的子任务
        for subtask in task.subtasks {
            let cdSubtask = CDSubtask(context: viewContext)
            cdSubtask.id = subtask.id
            cdSubtask.title = subtask.title
            cdSubtask.isCompleted = subtask.isCompleted
            cdSubtask.task = cdTask
        }
    }
    
    func deleteTask(_ task: CDTask) {
        viewContext.delete(task)
        saveContext()
    }
    
    func getAllTasks() -> [CDTask] {
        let fetchRequest: NSFetchRequest<CDTask> = CDTask.fetchRequest()
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("无法获取任务: \(error)")
            return []
        }
    }
    
    func getTask(byID id: UUID) -> CDTask? {
        let fetchRequest: NSFetchRequest<CDTask> = CDTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("无法通过ID获取任务: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Migration
    
    func migrateFromUserDefaults() {
        // 检查是否已经迁移
        let migrationKey = "coreDataMigrationCompleted"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }
        
        // 从UserDefaults加载任务
        if let tasksData = UserDefaults.standard.data(forKey: "tasks"),
           let tasks = try? JSONDecoder().decode([Task].self, from: tasksData) {
            
            // 迁移到Core Data
            for task in tasks {
                _ = addTask(task: task)
            }
            saveContext()
            
            // 标记迁移已完成
            UserDefaults.standard.set(true, forKey: migrationKey)
        }
    }
    
    // MARK: - Context Management
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("保存上下文失败: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // 转换CDTask为Task模型
    func convertToTaskModel(_ cdTask: CDTask) -> Task {
        // 转换子任务
        var subtasks: [Subtask] = []
        if let cdSubtasks = cdTask.subtasks as? Set<CDSubtask> {
            for cdSubtask in cdSubtasks {
                if let id = cdSubtask.id, let title = cdSubtask.title {
                    let subtask = Subtask(
                        id: id,
                        title: title,
                        isCompleted: cdSubtask.isCompleted
                    )
                    subtasks.append(subtask)
                }
            }
        }
        
        // 转换类别和优先级
        let category = cdTask.category.flatMap { TaskCategory(rawValue: $0) }
        let priority = TaskPriority(rawValue: cdTask.priority ?? TaskPriority.medium.rawValue) ?? .medium
        
        // 创建并返回Task模型
        return Task(
            id: cdTask.id ?? UUID(),
            title: cdTask.title ?? "",
            description: cdTask.descriptionText ?? "",
            category: category,
            dueDate: cdTask.dueDate,
            priority: priority,
            isCompleted: cdTask.isCompleted,
            subtasks: subtasks,
            createdAt: cdTask.createdAt ?? Date()
        )
    }
} 