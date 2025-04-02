import Foundation

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
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
    var name: String
    var colorName: String
    
    init(id: UUID = UUID(), name: String, colorName: String = "blue") {
        self.id = id
        self.name = name
        self.colorName = colorName
    }
    
    // 从TaskCategory获取预设分类
    static func fromTaskCategory(_ category: TaskCategory) -> CustomCategory {
        return CustomCategory(
            name: category.localizedName,
            colorName: category.colorName
        )
    }
    
    // 预设分类
    static let work = CustomCategory(name: "工作", colorName: "blue")
    static let personal = CustomCategory(name: "个人", colorName: "purple")
    static let health = CustomCategory(name: "健康", colorName: "green")
    static let important = CustomCategory(name: "重要", colorName: "red")
    
    static let defaultCategories: [CustomCategory] = [
        .work, .personal, .health, .important
    ]
}

// 扩展TaskCategory以提供本地化名称和颜色名称
extension TaskCategory {
    var localizedName: String {
        switch self {
        case .work:
            return "工作"
        case .personal:
            return "个人"
        case .health:
            return "健康"
        case .important:
            return "重要"
        }
    }
    
    var colorName: String {
        switch self {
        case .work:
            return "blue"
        case .personal:
            return "purple"
        case .health:
            return "green"
        case .important:
            return "red"
        }
    }
}

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
    var customCategory: CustomCategory?  // 新增自定义分类字段
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
        if let customCategory = customCategory {
            return customCategory.name
        }
        return category?.localizedName
    }
    
    // 辅助方法：获取分类颜色名称
    var categoryColorName: String? {
        if let customCategory = customCategory {
            return customCategory.colorName
        }
        return category?.colorName
    }
} 