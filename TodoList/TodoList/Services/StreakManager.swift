import Foundation
import Combine

class StreakManager: ObservableObject {
    static let shared = StreakManager()
    
    // MARK: - Published Properties
    @Published var streakData = StreakData()
    @Published var todayMarkedActive = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let streakDataKey = "streakData_v1"
    private let calendar = Calendar.current
    private let gracePeriodHours: Int = 24
    
    // MARK: - Milestone Configuration
    private let milestones = [
        StreakMilestone(days: 3, title: "新的开始", description: "连续使用3天", rewardPoints: 100),
        StreakMilestone(days: 7, title: "小有成就", description: "连续使用7天", rewardPoints: 200),
        StreakMilestone(days: 30, title: "习惯初成", description: "连续使用30天", rewardPoints: 500),
        StreakMilestone(days: 100, title: "终身习惯", description: "连续使用100天", rewardPoints: 1000)
    ]
    
    // MARK: - Initialization
    private init() {
        print("🔥 StreakManager: 初始化开始")
        loadStreakData()
        checkStreakStatusOnLaunch()
        print("🔥 StreakManager: 初始化完成 - 当前连续天数: \(streakData.currentStreak)")
    }
    
    // MARK: - Public Methods
    
    /// 标记今天为活跃状态
    func markTodayAsActive() {
        let today = calendar.startOfDay(for: Date())
        print("🔥 StreakManager: 尝试标记今日活跃 - \(formatDate(today))")
        
        // 避免重复标记同一天
        if let lastActiveDate = streakData.lastActiveDate,
           calendar.isDate(lastActiveDate, inSameDayAs: today) {
            print("🔥 StreakManager: 今日已标记过活跃，跳过")
            return
        }
        
        let previousStreak = streakData.currentStreak
        updateStreakForToday()
        
        print("🔥 StreakManager: 连续天数更新 - 从 \(previousStreak) 到 \(streakData.currentStreak)")
        checkForMilestoneUnlock()
        saveStreakData()
        
        // 通知其他系统用户今日活跃
        NotificationCenter.default.post(name: .userMarkedActiveToday, object: nil)
    }
    
    /// 获取当前连续状态
    func getCurrentStatus() -> StreakStatus {
        let today = calendar.startOfDay(for: Date())
        
        guard let lastActiveDate = streakData.lastActiveDate else {
            print("🔥 StreakManager: 无历史活跃记录，状态为新开始")
            return .newStart
        }
        
        let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDate, to: today).day ?? 0
        print("🔥 StreakManager: 距离上次活跃 \(daysSinceLastActive) 天")
        
        switch daysSinceLastActive {
        case 0:
            print("🔥 StreakManager: 状态 - 连续进行中")
            return .continuing
        case 1:
            let status: StreakStatus = streakData.isInGracePeriod ? .gracePeriod : .broken
            print("🔥 StreakManager: 状态 - \(status.rawValue)")
            return status
        default:
            print("🔥 StreakManager: 状态 - 已中断")
            return .broken
        }
    }
    
    /// 获取下一个里程碑
    func getNextMilestone() -> StreakMilestone? {
        let next = milestones.first { $0.days > streakData.currentStreak }
        print("🔥 StreakManager: 下一个里程碑 - \(next?.localizedTitle ?? "无")")
        return next
    }
    
    /// 获取已解锁的里程碑
    func getUnlockedMilestones() -> [StreakMilestone] {
        let unlocked = milestones.filter { $0.days <= streakData.currentStreak }
        print("🔥 StreakManager: 已解锁里程碑数量 - \(unlocked.count)")
        return unlocked
    }
    
    /// 获取详细状态信息（用于调试）
    func getStatusInfo() -> String {
        let status = getCurrentStatus()
        let next = getNextMilestone()
        
        return """
        === Streak Status ===
        当前连续天数: \(streakData.currentStreak)
        最长连续记录: \(streakData.longestStreak)
        总活跃天数: \(streakData.totalActiveDays)
        当前状态: \(status.localizedDescription)
        上次活跃: \(formatDate(streakData.lastActiveDate))
        宽限期结束: \(formatDate(streakData.graceEndDate))
        下一里程碑: \(next?.localizedTitle ?? "无") (\(next?.days ?? 0)天)
        今日已标记: \(todayMarkedActive)
        ===================
        """
    }
    
    // MARK: - Private Methods
    
    private func loadStreakData() {
        print("🔥 StreakManager: 开始加载持久化数据")
        
        if let data = userDefaults.data(forKey: streakDataKey),
           let decoded = try? JSONDecoder().decode(StreakData.self, from: data) {
            self.streakData = decoded
            print("🔥 StreakManager: 成功加载数据 - 连续天数: \(decoded.currentStreak)")
        } else {
            print("🔥 StreakManager: 无持久化数据，使用默认值")
        }
        
        // 检查今日是否已标记活跃
        let today = calendar.startOfDay(for: Date())
        if let lastActiveDate = streakData.lastActiveDate,
           calendar.isDate(lastActiveDate, inSameDayAs: today) {
            todayMarkedActive = true
            print("🔥 StreakManager: 今日已标记活跃")
        } else {
            todayMarkedActive = false
            print("🔥 StreakManager: 今日尚未标记活跃")
        }
    }
    
    private func saveStreakData() {
        print("🔥 StreakManager: 保存数据到持久化存储")
        
        if let encoded = try? JSONEncoder().encode(streakData) {
            userDefaults.set(encoded, forKey: streakDataKey)
            print("🔥 StreakManager: 数据保存成功")
        } else {
            print("🔥 StreakManager: 数据保存失败")
        }
    }
    
    private func checkStreakStatusOnLaunch() {
        print("🔥 StreakManager: 检查应用启动时的连续状态")
        let status = getCurrentStatus()
        
        switch status {
        case .broken:
            print("🔥 StreakManager: 连续已中断，重置连续天数")
            resetStreak()
        case .gracePeriod:
            print("🔥 StreakManager: 当前在宽限期内")
            // 可以在这里安排宽限期提醒
        case .continuing:
            print("🔥 StreakManager: 连续状态良好")
        case .newStart:
            print("🔥 StreakManager: 准备开始新的连续记录")
        }
    }
    
    private func updateStreakForToday() {
        let today = calendar.startOfDay(for: Date())
        print("🔥 StreakManager: 更新今日活跃状态")
        
        if let lastActiveDate = streakData.lastActiveDate {
            let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDate, to: today).day ?? 0
            
            switch daysSinceLastActive {
            case 0:
                // 同一天，不需要更新
                print("🔥 StreakManager: 同一天重复标记，跳过")
                return
            case 1:
                // 连续的下一天
                streakData.currentStreak += 1
                print("🔥 StreakManager: 连续天数+1")
            default:
                // 中断了，重新开始
                streakData.currentStreak = 1
                print("🔥 StreakManager: 连续中断，重新开始计数")
            }
        } else {
            // 首次使用
            streakData.currentStreak = 1
            print("🔥 StreakManager: 首次使用，开始计数")
        }
        
        streakData.lastActiveDate = today
        streakData.totalActiveDays += 1
        streakData.graceEndDate = calendar.date(byAdding: .hour, value: gracePeriodHours, to: Date())
        
        // 更新最长连续记录
        if streakData.currentStreak > streakData.longestStreak {
            streakData.longestStreak = streakData.currentStreak
            print("🔥 StreakManager: 创造新的最长记录! \(streakData.longestStreak) 天")
        }
        
        todayMarkedActive = true
    }
    
    private func resetStreak() {
        print("🔥 StreakManager: 重置连续天数")
        streakData.currentStreak = 0
        streakData.graceEndDate = nil
        saveStreakData()
    }
    
    private func checkForMilestoneUnlock() {
        let newlyUnlockedMilestones = milestones.filter { milestone in
            milestone.days == streakData.currentStreak
        }
        
        for milestone in newlyUnlockedMilestones {
            print("🎉 StreakManager: 解锁新里程碑! \(milestone.localizedTitle) (\(milestone.days)天)")
            
            // 触发里程碑解锁事件
            NotificationCenter.default.post(
                name: .streakMilestoneUnlocked,
                object: milestone
            )
            
            // 这里将来可以给用户奖励积分
            // UserLevelManager.shared.addPoints(milestone.rewardPoints, for: .streakMilestone)
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "无" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userMarkedActiveToday = Notification.Name("userMarkedActiveToday")
    static let streakMilestoneUnlocked = Notification.Name("streakMilestoneUnlocked")
}