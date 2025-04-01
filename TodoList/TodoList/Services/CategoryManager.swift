import Foundation
import SwiftUI

class CategoryManager: ObservableObject {
    @Published var categories: [CustomCategory] = []
    
    private let userDefaultsKey = "userCustomCategories"
    
    init() {
        loadCategories()
    }
    
    // 加载分类
    private func loadCategories() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedCategories = try? JSONDecoder().decode([CustomCategory].self, from: savedData) {
                categories = decodedCategories
                return
            }
        }
        
        // 如果没有已保存的分类或解码失败，使用默认分类
        categories = CustomCategory.defaultCategories
    }
    
    // 保存分类
    private func saveCategories() {
        if let encodedData = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsKey)
        }
    }
    
    // 添加新分类
    func addCategory(name: String, colorName: String) {
        // 检查是否已存在同名分类
        guard !categories.contains(where: { $0.name == name }) else {
            return
        }
        
        let newCategory = CustomCategory(name: name, colorName: colorName)
        categories.append(newCategory)
        saveCategories()
    }
    
    // 删除分类
    func deleteCategory(at indices: IndexSet) {
        // 从数组中删除指定索引的分类
        categories.remove(atOffsets: indices)
        saveCategories()
    }
    
    // 更新分类
    func updateCategory(id: UUID, name: String? = nil, colorName: String? = nil) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            var updatedCategory = categories[index]
            
            if let name = name {
                updatedCategory.name = name
            }
            
            if let colorName = colorName {
                updatedCategory.colorName = colorName
            }
            
            categories[index] = updatedCategory
            saveCategories()
        }
    }
    
    // 根据ID获取分类
    func getCategory(by id: UUID) -> CustomCategory? {
        return categories.first(where: { $0.id == id })
    }
    
    // 获取可用的颜色
    static var availableColors: [String: Color] = [
        "red": .red,
        "orange": .orange,
        "yellow": .yellow,
        "green": .green,
        "blue": .blue,
        "purple": .purple,
        "pink": .pink,
        "indigo": .indigo,
        "teal": .teal,
        "gray": .gray
    ]
    
    // 根据颜色名称获取颜色
    static func color(for name: String) -> Color {
        return availableColors[name] ?? .blue
    }
} 