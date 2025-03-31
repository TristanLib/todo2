import Foundation

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
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
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
        self.subtasks = subtasks
        self.createdAt = createdAt
    }
} 