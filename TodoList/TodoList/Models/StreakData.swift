import Foundation

/// 连续使用天数相关数据
struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalActiveDays: Int = 0
    var lastActiveDate: Date?
    var graceEndDate: Date?
    
    /// 检查是否在宽限期内
    var isInGracePeriod: Bool {
        guard let graceEnd = graceEndDate else { return false }
        return Date() <= graceEnd
    }
}

/// 连续状态枚举
enum StreakStatus: String, CaseIterable {
    case continuing = "continuing"     // 连续进行中
    case gracePeriod = "gracePeriod"   // 宽限期
    case broken = "broken"             // 已中断
    case newStart = "newStart"         // 新开始
    
    var localizedDescription: String {
        switch self {
        case .continuing:
            return NSLocalizedString("进行中", comment: "Streak status continuing")
        case .gracePeriod:
            return NSLocalizedString("宽限期", comment: "Streak status grace period")
        case .broken:
            return NSLocalizedString("已中断", comment: "Streak status broken")
        case .newStart:
            return NSLocalizedString("新开始", comment: "Streak status new start")
        }
    }
}

/// 里程碑数据
struct StreakMilestone: Identifiable {
    let id = UUID()
    let days: Int
    let title: String
    let description: String
    let rewardPoints: Int
    var isUnlocked: Bool = false
    
    var localizedTitle: String {
        return NSLocalizedString(title, comment: "Streak milestone title")
    }
    
    var localizedDescription: String {
        return NSLocalizedString(description, comment: "Streak milestone description")
    }
}