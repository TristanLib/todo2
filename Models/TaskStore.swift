import Foundation
import SwiftUI

class TaskStore: ObservableObject {
    @Published var tasks: [Task] = []
    
    private let tasksKey = "tasks"
    
    init() {
        loadTasks()
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    func deleteTask(at indexSet: IndexSet) {
        tasks.remove(atOffsets: indexSet)
        saveTasks()
    }
    
    func deleteTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks.remove(at: index)
            saveTasks()
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
    
    private func saveTasks() {
        if let encodedData = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedData, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let tasksData = UserDefaults.standard.data(forKey: tasksKey),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: tasksData) {
            tasks = decodedTasks
        } else {
            tasks = []
        }
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
                    self.tasks = restoredTasks
                    self.saveTasks()
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
            self.tasks = []
            self.saveTasks()
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