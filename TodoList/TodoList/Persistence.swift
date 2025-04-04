//
//  Persistence.swift
//  TodoList
//
//  Created by TristanLee on 2025/3/31.
//

import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // 预览数据可以在这里创建，但我们暂时不需要
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer
    var isLoaded = false
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TodoList")

        // 获取默认的存储描述
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("###\(#function): Failed to retrieve the persistent store description.")
        }
        // 开启自动轻量级迁移
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        
        // 原有的内存存储逻辑 (现在操作的是已经配置好的 description)
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 使用异步加载避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async {
            self.container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    print("Unresolved Core Data error: \(error), \(error.userInfo)")
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isLoaded = true
                    NotificationCenter.default.post(name: .persistentStoreDidLoad, object: nil)
                }
            })
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.container.viewContext.automaticallyMergesChangesFromParent = true
            }
        }
    }
}

// 添加通知名
extension Notification.Name {
    static let persistentStoreDidLoad = Notification.Name("persistentStoreDidLoad")
}
