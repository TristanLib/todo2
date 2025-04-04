import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    // Use localized string for display
    var localizedString: String {
        switch self {
        case .low:
            return NSLocalizedString("Low", comment: "Task priority low")
        case .medium:
            return NSLocalizedString("Medium", comment: "Task priority medium")
        case .high:
            return NSLocalizedString("High", comment: "Task priority high")
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "priorityLow"
        case .medium:
            return "priorityMedium"
        case .high:
            return "priorityHigh"
        }
    }
}

// 保留枚举以支持向后兼容
enum TaskCategory: String, Codable, CaseIterable {
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
    case important = "Important"
    
    // Use localized string for display
    var localizedString: String {
        switch self {
        case .work:
            return NSLocalizedString("Work", comment: "Task category work")
        case .personal:
            return NSLocalizedString("Personal", comment: "Task category personal")
        case .health:
            return NSLocalizedString("Health", comment: "Task category health")
        case .important:
            return NSLocalizedString("Important", comment: "Task category important")
        }
    }
    
    var color: String {
        switch self {
        case .work:
            return "categoryWork"
        case .personal:
            return "categoryPersonal"
        case .health:
            return "categoryHealth"
        case .important:
            return "categoryImportant"
        }
    }
}

// 新的自定义分类结构体
struct CustomCategory: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String // For user-created categories, the name itself is the source of truth
    var colorName: String
    
    // Computed property for display name, especially for default categories
    var localizedName: String {
        // If it's a default category, return the localized version
        // We need a way to identify default categories reliably. Maybe check against static instances?
        // Or store a localization key instead of the name for default categories.
        // For now, we assume 'name' for user-created ones is already what should be displayed.
        // Let's refine this: We should store a key for default categories.
        if let defaultKey = Self.defaultCategoryKey(forName: self.name, colorName: self.colorName) {
             return NSLocalizedString(defaultKey, comment: "Default category name")
         }
         // For user-created categories, return the stored name
         return name
    }
    
    private static func defaultCategoryKey(forName name: String, colorName: String) -> String? {
         if name == Self.work.name && colorName == Self.work.colorName { return "Work" }
         if name == Self.personal.name && colorName == Self.personal.colorName { return "Personal" }
         if name == Self.health.name && colorName == Self.health.colorName { return "Health" }
         if name == Self.important.name && colorName == Self.important.colorName { return "Important" }
         return nil
     }

    init(id: UUID = UUID(), name: String, colorName: String = "blue") {
        self.id = id
        self.name = name // Store the potentially non-localized name
        self.colorName = colorName
    }
    
    // 从TaskCategory获取预设分类 (可能需要调整，或者不再使用TaskCategory直接创建)
    // static func fromTaskCategory(_ category: TaskCategory) -> CustomCategory {
    //     // This needs careful handling. Maybe store a localization key?
    //     return CustomCategory(
    //         name: category.localizedString, // Use localized string temporarily, but ideally store a key
    //         colorName: category.colorNameFromMapping // Need a mapping for TaskCategory -> colorName
    //     )
    // }
    
    // Use localization keys for default category names
    static let work = CustomCategory(name: NSLocalizedString("Work", comment: "Default category name Work"), colorName: "blue")
    static let personal = CustomCategory(name: NSLocalizedString("Personal", comment: "Default category name Personal"), colorName: "purple")
    static let health = CustomCategory(name: NSLocalizedString("Health", comment: "Default category name Health"), colorName: "green")
    static let important = CustomCategory(name: NSLocalizedString("Important", comment: "Default category name Important"), colorName: "red")

    static let defaultCategories: [CustomCategory] = [
        .work, .personal, .health, .important
    ]
    
    // Helper to map old TaskCategory color to new color names if needed
    static func colorName(for taskCategory: TaskCategory) -> String {
        switch taskCategory {
        case .work: return "blue"
        case .personal: return "purple"
        case .health: return "green"
        case .important: return "red"
        }
    }
}

// // 扩展TaskCategory以提供本地化名称和颜色名称 (现在由 localizedString 提供)
// extension TaskCategory {
//     var localizedName: String { // 使用 localizedString 替代
//         // ...
//     }
    
//     var colorName: String { // 这个映射可能仍然有用，或者移到 CustomCategory
//         // ...
//     }
// }

struct Subtask: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String
    var category: TaskCategory?
    var customCategory: CustomCategory?
    var dueDate: Date?
    var priority: TaskPriority
    var isCompleted: Bool
    var subtasks: [Subtask]
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        category: TaskCategory? = nil,
        customCategory: CustomCategory? = nil,
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        isCompleted: Bool = false,
        subtasks: [Subtask] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.customCategory = customCategory
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.subtasks = subtasks
        self.createdAt = createdAt
    }
    
    // 辅助方法：获取分类显示名称
    var categoryDisplayName: String? {
         // Prioritize CustomCategory, using its localizedName
         if let customCategory = customCategory {
             return customCategory.localizedName
         }
         // Fallback to legacy TaskCategory, using its localizedString
         return category?.localizedString
     }
    
    // 辅助方法：获取分类颜色名称
    var categoryColorName: String? {
         if let customCategory = customCategory {
             return customCategory.colorName
         }
         // Fallback for legacy TaskCategory
         if let category = category {
            return CustomCategory.colorName(for: category) // Use helper to get color name
         }
        return nil
    }
} 