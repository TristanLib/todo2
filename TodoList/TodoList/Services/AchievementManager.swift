import Foundation
import Combine

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    // MARK: - Published Properties
    @Published var achievementData = AchievementData()
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let achievementDataKey = "achievementData_v1"
    
    // MARK: - Initialization
    private init() {
        print("🏆 AchievementManager: 初始化开始")
        loadAchievementData()
        setupDefaultAchievements()
        setupNotificationObservers()
        print("🏆 AchievementManager: 初始化完成 - 已解锁成就: \(achievementData.totalUnlocked)/\(achievementData.achievements.count)")
    }
    
    // MARK: - Public Methods
    
    /// 解锁指定成就
    func unlockAchievement(id: String) {
        guard achievementData.unlockAchievement(id: id) else {
            print("🏆 AchievementManager: 成就 \(id) 已解锁或不存在")
            return
        }
        
        if let achievement = achievementData.achievements.first(where: { $0.id == id }) {
            print("🏆 AchievementManager: 成就解锁成功 - \(achievement.title)")
            
            // 发送通知
            NotificationCenter.default.post(
                name: .achievementUnlocked,
                object: achievement
            )
        }
        
        saveAchievementData()
    }
    
    /// 检查并解锁连续天数相关成就
    func checkStreakAchievements(currentStreak: Int) {
        let streakAchievements = [
            (3, "streak_3_days"),
            (7, "streak_7_days"),
            (30, "streak_30_days"),
            (100, "streak_100_days")
        ]
        
        for (requiredDays, achievementId) in streakAchievements {
            if currentStreak >= requiredDays {
                unlockAchievement(id: achievementId)
            }
        }
    }
    
    /// 检查任务相关成就
    func checkTaskAchievements(tasksCompleted: Int, totalTasks: Int, isFirstTask: Bool = false, totalCompletedEver: Int = 0) {
        print("🏆 AchievementManager: 检查任务成就 - 今日完成:\(tasksCompleted), 总任务:\(totalTasks), 首个任务:\(isFirstTask), 累计完成:\(totalCompletedEver)")
        
        // 第一个任务 (首次创建任务时)
        if isFirstTask {
            unlockAchievement(id: "first_task")
        }
        
        // 单日10个任务
        if tasksCompleted >= 10 {
            unlockAchievement(id: "daily_10_tasks")
        }
        
        // 100%完成率 (单日)
        if totalTasks > 0 && tasksCompleted == totalTasks && totalTasks >= 3 {
            unlockAchievement(id: "perfect_day")
        }
        
        // 累计100个任务
        if totalCompletedEver >= 100 {
            unlockAchievement(id: "task_master_100")
        }
        
        // 计划大师：连续7天每天都有计划 (需要额外检查)
        checkPlanningMasterAchievement()
    }
    
    /// 检查专注相关成就
    func checkFocusAchievements(sessionsCompleted: Int, totalFocusMinutes: Int, isFirstSession: Bool = false, totalFocusMinutesEver: Int = 0, currentHour: Int = -1) {
        print("🏆 AchievementManager: 检查专注成就 - 今日会话:\(sessionsCompleted), 今日分钟:\(totalFocusMinutes), 首次:\(isFirstSession), 累计分钟:\(totalFocusMinutesEver), 当前时间:\(currentHour)")
        
        // 第一个番茄钟
        if isFirstSession || sessionsCompleted >= 1 {
            unlockAchievement(id: "first_pomodoro")
        }
        
        // 专注时长成就 (累计)
        if totalFocusMinutesEver >= 600 { // 10小时
            unlockAchievement(id: "focus_10_hours")
        }
        
        if totalFocusMinutesEver >= 3000 { // 50小时
            unlockAchievement(id: "focus_50_hours")
        }
        
        // 单日8小时专注
        if totalFocusMinutes >= 480 {
            unlockAchievement(id: "workaholic")
        }
        
        // 时间相关成就
        if currentHour >= 0 {
            // 夜猫子：23:00后专注
            if currentHour >= 23 || currentHour <= 2 {
                unlockAchievement(id: "night_owl")
            }
            
            // 早起鸟：6:00前专注  
            if currentHour >= 5 && currentHour <= 7 {
                unlockAchievement(id: "early_bird")
            }
        }
    }
    
    /// 获取分类成就
    func getAchievements(for category: AchievementCategory) -> [Achievement] {
        return achievementData.getAchievements(for: category)
    }
    
    /// 获取所有成就
    func getAllAchievements() -> [Achievement] {
        return achievementData.achievements
    }
    
    /// 获取已解锁成就
    func getUnlockedAchievements() -> [Achievement] {
        return achievementData.getUnlockedAchievements()
    }
    
    /// 检查分类成就（自定义达人）
    func checkCategoryAchievements(customCategoriesCount: Int) {
        print("🏆 AchievementManager: 检查分类成就 - 自定义分类数:\(customCategoriesCount)")
        
        if customCategoriesCount >= 10 {
            unlockAchievement(id: "category_master")
        }
    }
    
    /// 检查特殊成就（早期用户）
    func checkEarlyAdopterAchievement() {
        print("🏆 AchievementManager: 检查早期用户成就")
        unlockAchievement(id: "early_adopter")
    }
    
    /// 计划大师成就检查（需要检查连续7天有计划）
    private func checkPlanningMasterAchievement() {
        // 这个需要更复杂的逻辑来检查连续天数
        // 暂时简化处理
        print("🏆 AchievementManager: 计划大师成就检查（待实现复杂逻辑）")
    }
    
    /// 重置所有成就 (仅调试用)
    func resetAllAchievements() {
        print("🏆 AchievementManager: 重置所有成就")
        for index in achievementData.achievements.indices {
            achievementData.achievements[index].isUnlocked = false
            achievementData.achievements[index].unlockedDate = nil
        }
        achievementData.totalUnlocked = 0
        achievementData.lastUpdated = Date()
        saveAchievementData()
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultAchievements() {
        // 如果已有成就数据，不重复设置
        if !achievementData.achievements.isEmpty {
            return
        }
        
        print("🏆 AchievementManager: 设置默认成就")
        
        var achievements: [Achievement] = []
        
        // 专注大师系列
        achievements.append(Achievement(id: "first_pomodoro", title: "初试身手", description: "完成第一个番茄钟", icon: "timer", category: .focus, rewardPoints: 50))
        achievements.append(Achievement(id: "focus_10_hours", title: "专注新手", description: "累计专注10小时", icon: "clock", category: .focus, rewardPoints: 100))
        achievements.append(Achievement(id: "focus_50_hours", title: "专注能手", description: "累计专注50小时", icon: "target", category: .focus, rewardPoints: 200))
        achievements.append(Achievement(id: "night_owl", title: "夜猫子", description: "深夜23:00后专注", icon: "moon.stars", category: .focus, rewardPoints: 150))
        achievements.append(Achievement(id: "early_bird", title: "早起鸟", description: "早上6:00前专注", icon: "sunrise", category: .focus, rewardPoints: 150))
        
        // 任务管理系列
        achievements.append(Achievement(id: "first_task", title: "任务新手", description: "创建第一个任务", icon: "plus.circle", category: .tasks, rewardPoints: 50))
        achievements.append(Achievement(id: "daily_10_tasks", title: "高效达人", description: "单日完成10个任务", icon: "bolt", category: .tasks, rewardPoints: 200))
        achievements.append(Achievement(id: "planning_master", title: "计划大师", description: "连续7天每天都有计划", icon: "calendar", category: .tasks, rewardPoints: 250))
        achievements.append(Achievement(id: "perfect_day", title: "完美主义", description: "单日完成率100%", icon: "star", category: .tasks, rewardPoints: 300))
        achievements.append(Achievement(id: "task_master_100", title: "清单杀手", description: "累计完成100个任务", icon: "trophy", category: .tasks, rewardPoints: 500))
        
        // 习惯养成系列
        achievements.append(Achievement(id: "streak_3_days", title: "新的开始", description: "连续使用3天", icon: "leaf", category: .habits, rewardPoints: 100))
        achievements.append(Achievement(id: "streak_7_days", title: "小有成就", description: "连续使用7天", icon: "hand.thumbsup", category: .habits, rewardPoints: 200))
        achievements.append(Achievement(id: "streak_30_days", title: "习惯初成", description: "连续使用30天", icon: "flame", category: .habits, rewardPoints: 500))
        achievements.append(Achievement(id: "streak_100_days", title: "终身习惯", description: "连续使用100天", icon: "crown", category: .habits, rewardPoints: 1000))
        
        // 特殊成就系列
        achievements.append(Achievement(id: "workaholic", title: "工作狂", description: "单日专注超过8小时", icon: "laptopcomputer", category: .special, rewardPoints: 400))
        achievements.append(Achievement(id: "category_master", title: "自定义达人", description: "创建10个自定义分类", icon: "folder.badge.plus", category: .special, rewardPoints: 300))
        achievements.append(Achievement(id: "early_adopter", title: "早期用户", description: "首批使用用户", icon: "person.badge.key", category: .special, rewardPoints: 200))
        
        achievementData.achievements = achievements
        achievementData.lastUpdated = Date()
        saveAchievementData()
        
        print("🏆 AchievementManager: 默认成就設定完成，共\(achievements.count)个成就")
    }
    
    private func loadAchievementData() {
        guard let data = userDefaults.data(forKey: achievementDataKey),
              let decoded = try? JSONDecoder().decode(AchievementData.self, from: data) else {
            print("🏆 AchievementManager: 未找到保存的成就数据，使用默认数据")
            return
        }
        
        achievementData = decoded
        print("🏆 AchievementManager: 成就数据加载成功 - 已解锁: \(decoded.totalUnlocked)")
    }
    
    private func saveAchievementData() {
        do {
            let encoded = try JSONEncoder().encode(achievementData)
            userDefaults.set(encoded, forKey: achievementDataKey)
            print("🏆 AchievementManager: 成就数据保存成功")
        } catch {
            print("🏆 AchievementManager: 保存成就数据失败 - \(error)")
        }
    }
    
    private func setupNotificationObservers() {
        print("🏆 AchievementManager: 设置通知监听器")
        
        // 监听连续天数里程碑解锁事件
        NotificationCenter.default.addObserver(
            forName: .streakMilestoneUnlocked,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let milestone = notification.object as? StreakMilestone {
                self?.handleStreakMilestoneUnlocked(milestone)
            }
        }
        
        // 监听用户今日活跃事件
        NotificationCenter.default.addObserver(
            forName: .userMarkedActiveToday,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleUserMarkedActiveToday()
        }
    }
    
    private func handleStreakMilestoneUnlocked(_ milestone: Any) {
        guard let streakMilestone = milestone as? StreakMilestone else {
            print("🏆 AchievementManager: 里程碑类型转换失败")
            return
        }
        
        print("🏆 AchievementManager: 收到里程碑解锁通知 - \(streakMilestone.days)天")
        
        // 根据里程碑天数解锁对应成就
        let achievementId: String
        switch streakMilestone.days {
        case 3:
            achievementId = "streak_3_days"
        case 7:
            achievementId = "streak_7_days"
        case 30:
            achievementId = "streak_30_days"
        case 100:
            achievementId = "streak_100_days"
        default:
            print("🏆 AchievementManager: 未知里程碑天数 - \(streakMilestone.days)")
            return
        }
        
        unlockAchievement(id: achievementId)
    }
    
    private func handleUserMarkedActiveToday() {
        print("🏆 AchievementManager: 用户今日活跃，检查相关成就")
        
        // 这里可以检查一些基于活跃的成就
        // 比如连续活跃天数、特定时间段活跃等
        
        // 获取当前连续天数，检查是否需要解锁成就
        let currentStreak = StreakManager.shared.streakData.currentStreak
        checkStreakAchievements(currentStreak: currentStreak)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("🏆 AchievementManager: 清理通知监听器")
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}