import Foundation

// MARK: - Achievement Models

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let rewardPoints: Int
    var isUnlocked: Bool = false
    var unlockedDate: Date? = nil
    
    init(id: String, title: String, description: String, icon: String, category: AchievementCategory, rewardPoints: Int) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.rewardPoints = rewardPoints
    }
}

enum AchievementCategory: String, CaseIterable, Codable {
    case focus = "focus"
    case tasks = "tasks"
    case habits = "habits"
    case special = "special"
    
    var localizedName: String {
        switch self {
        case .focus:
            return NSLocalizedString("专注大师", comment: "Focus category")
        case .tasks:
            return NSLocalizedString("任务管理", comment: "Tasks category")
        case .habits:
            return NSLocalizedString("习惯养成", comment: "Habits category")
        case .special:
            return NSLocalizedString("特殊成就", comment: "Special category")
        }
    }
    
    var icon: String {
        switch self {
        case .focus:
            return "brain.head.profile"
        case .tasks:
            return "checklist"
        case .habits:
            return "calendar.badge.plus"
        case .special:
            return "star.circle"
        }
    }
}

struct AchievementData: Codable {
    var achievements: [Achievement] = []
    var totalUnlocked: Int = 0
    var lastUpdated: Date = Date()
    
    mutating func unlockAchievement(id: String) -> Bool {
        guard let index = achievements.firstIndex(where: { $0.id == id }),
              !achievements[index].isUnlocked else {
            return false
        }
        
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        totalUnlocked += 1
        lastUpdated = Date()
        return true
    }
    
    func getAchievements(for category: AchievementCategory) -> [Achievement] {
        return achievements.filter { $0.category == category }
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    var progressPercentage: Double {
        guard !achievements.isEmpty else { return 0.0 }
        return Double(totalUnlocked) / Double(achievements.count)
    }
}