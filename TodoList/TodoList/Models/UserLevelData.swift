import Foundation

/// 用户等级数据模型
struct UserLevelData: Codable {
    var currentLevel: Int
    var currentExperience: Int
    var totalExperience: Int
    var totalPoints: Int
    var lastUpdated: Date
    
    init() {
        self.currentLevel = 1
        self.currentExperience = 0
        self.totalExperience = 0
        self.totalPoints = 0
        self.lastUpdated = Date()
    }
    
    /// 获取当前等级需要的总经验值
    var experienceForCurrentLevel: Int {
        return UserLevelData.experienceRequired(for: currentLevel)
    }
    
    /// 获取下一级需要的总经验值
    var experienceForNextLevel: Int {
        return UserLevelData.experienceRequired(for: currentLevel + 1)
    }
    
    /// 获取到下一级还需要的经验值
    var experienceToNextLevel: Int {
        return experienceForNextLevel - totalExperience
    }
    
    /// 获取当前等级的进度百分比 (0.0 到 1.0)
    var levelProgress: Double {
        let currentLevelExp = experienceForCurrentLevel
        let nextLevelExp = experienceForNextLevel
        let levelRange = nextLevelExp - currentLevelExp
        
        if levelRange <= 0 {
            return 1.0
        }
        
        let progressInLevel = totalExperience - currentLevelExp
        return Double(progressInLevel) / Double(levelRange)
    }
    
    /// 获取等级标题
    var levelTitle: String {
        switch currentLevel {
        case 1...5:
            return NSLocalizedString("新手", comment: "Level title for levels 1-5")
        case 6...10:
            return NSLocalizedString("学徒", comment: "Level title for levels 6-10")
        case 11...20:
            return NSLocalizedString("熟练者", comment: "Level title for levels 11-20")
        case 21...35:
            return NSLocalizedString("专家", comment: "Level title for levels 21-35")
        case 36...50:
            return NSLocalizedString("大师", comment: "Level title for levels 36-50")
        case 51...75:
            return NSLocalizedString("宗师", comment: "Level title for levels 51-75")
        case 76...100:
            return NSLocalizedString("传奇", comment: "Level title for levels 76-100")
        default:
            return NSLocalizedString("至尊", comment: "Level title for levels 100+")
        }
    }
    
    /// 获取等级颜色
    var levelColor: String {
        switch currentLevel {
        case 1...5:
            return "green"
        case 6...10:
            return "blue"
        case 11...20:
            return "purple"
        case 21...35:
            return "orange"
        case 36...50:
            return "red"
        case 51...75:
            return "pink"
        case 76...100:
            return "yellow"
        default:
            return "rainbow"
        }
    }
    
    /// 计算指定等级需要的总经验值
    static func experienceRequired(for level: Int) -> Int {
        if level <= 1 {
            return 0
        }
        
        // 使用指数增长公式: baseExp * (level - 1)^1.5
        let baseExp = 100
        let adjustedLevel = Double(level - 1)
        return Int(Double(baseExp) * pow(adjustedLevel, 1.5))
    }
    
    /// 检查是否可以升级
    func canLevelUp() -> Bool {
        return totalExperience >= experienceForNextLevel
    }
}

/// 积分行为类型
enum PointAction: String, CaseIterable, Codable {
    case completeTask = "complete_task"
    case createTask = "create_task"
    case completeFocusSession = "complete_focus_session"
    case reachMilestone = "reach_milestone"
    case unlockAchievement = "unlock_achievement"
    case perfectDay = "perfect_day"
    case longFocusSession = "long_focus_session"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    
    /// 获取积分值
    var points: Int {
        switch self {
        case .completeTask:
            return 10
        case .createTask:
            return 5
        case .completeFocusSession:
            return 20
        case .reachMilestone:
            return 100
        case .unlockAchievement:
            return 50
        case .perfectDay:
            return 200
        case .longFocusSession:
            return 50
        case .earlyBird:
            return 30
        case .nightOwl:
            return 30
        }
    }
    
    /// 获取经验值 (通常是积分的1.5倍)
    var experience: Int {
        return Int(Double(points) * 1.5)
    }
    
    /// 获取行为描述
    var description: String {
        switch self {
        case .completeTask:
            return NSLocalizedString("完成任务", comment: "Point action: complete task")
        case .createTask:
            return NSLocalizedString("创建任务", comment: "Point action: create task")
        case .completeFocusSession:
            return NSLocalizedString("完成专注", comment: "Point action: complete focus session")
        case .reachMilestone:
            return NSLocalizedString("达成里程碑", comment: "Point action: reach milestone")
        case .unlockAchievement:
            return NSLocalizedString("解锁成就", comment: "Point action: unlock achievement")
        case .perfectDay:
            return NSLocalizedString("完美一天", comment: "Point action: perfect day")
        case .longFocusSession:
            return NSLocalizedString("长时间专注", comment: "Point action: long focus session")
        case .earlyBird:
            return NSLocalizedString("早起鸟", comment: "Point action: early bird")
        case .nightOwl:
            return NSLocalizedString("夜猫子", comment: "Point action: night owl")
        }
    }
}

/// 积分获得记录
struct PointRecord: Identifiable, Codable {
    let id: UUID
    let action: PointAction
    let points: Int
    let experience: Int
    let timestamp: Date
    let details: String?
    
    init(action: PointAction, details: String? = nil) {
        self.id = UUID()
        self.action = action
        self.points = action.points
        self.experience = action.experience
        self.timestamp = Date()
        self.details = details
    }
}