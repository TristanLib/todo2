import Foundation
import SwiftUI

/// 用户等级管理器，负责管理用户等级、积分和经验值系统
class UserLevelManager: ObservableObject {
    static let shared = UserLevelManager()
    
    @Published var levelData: UserLevelData
    @Published var recentPointsEarned: [PointRecord] = []
    
    private let userDefaults = UserDefaults.standard
    private let levelDataKey = "UserLevelData"
    private let recentPointsKey = "RecentPointRecords"
    
    // 通知名称
    static let levelUpNotification = Notification.Name("UserLevelUp")
    static let pointsEarnedNotification = Notification.Name("PointsEarned")
    
    private init() {
        // 从 UserDefaults 加载数据
        if let data = userDefaults.data(forKey: levelDataKey),
           let savedData = try? JSONDecoder().decode(UserLevelData.self, from: data) {
            self.levelData = savedData
            print("📊 UserLevelManager: 已加载等级数据 - 等级:\(savedData.currentLevel), 积分:\(savedData.totalPoints)")
        } else {
            self.levelData = UserLevelData()
            print("📊 UserLevelManager: 创建新的等级数据")
        }
        
        // 加载最近积分记录
        loadRecentPointRecords()
        
        // 监听成就解锁通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAchievementUnlocked),
            name: .achievementUnlocked,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 积分和经验值管理
    
    /// 添加积分和经验值
    func earnPoints(for action: PointAction, details: String? = nil) {
        let record = PointRecord(action: action, details: details)
        let oldLevel = levelData.currentLevel
        
        // 更新积分和经验值
        levelData.totalPoints += record.points
        levelData.totalExperience += record.experience
        levelData.lastUpdated = Date()
        
        // 检查是否升级
        let newLevel = calculateLevel(for: levelData.totalExperience)
        if newLevel > oldLevel {
            levelData.currentLevel = newLevel
            print("🎉 UserLevelManager: 用户升级! \(oldLevel) -> \(newLevel)")
            
            // 发送升级通知
            NotificationCenter.default.post(
                name: Self.levelUpNotification,
                object: self,
                userInfo: ["oldLevel": oldLevel, "newLevel": newLevel]
            )
        }
        
        // 添加积分记录
        recentPointsEarned.insert(record, at: 0)
        if recentPointsEarned.count > 50 { // 只保留最近50条记录
            recentPointsEarned.removeLast()
        }
        
        print("📊 UserLevelManager: 获得积分 +\(record.points) (+\(record.experience)XP) - \(action.description)")
        
        // 保存数据
        saveData()
        
        // 发送积分获得通知
        NotificationCenter.default.post(
            name: Self.pointsEarnedNotification,
            object: record
        )
    }
    
    /// 根据总经验值计算等级
    private func calculateLevel(for totalExperience: Int) -> Int {
        var level = 1
        while totalExperience >= UserLevelData.experienceRequired(for: level + 1) {
            level += 1
        }
        return level
    }
    
    // MARK: - 快捷方法
    
    /// 任务相关积分
    func taskCompleted(isFirstTask: Bool = false, isPerfectDay: Bool = false) {
        if isFirstTask {
            earnPoints(for: .completeTask, details: "首个任务")
        } else {
            earnPoints(for: .completeTask)
        }
        
        if isPerfectDay {
            earnPoints(for: .perfectDay, details: "今日任务全部完成")
        }
    }
    
    func taskCreated() {
        earnPoints(for: .createTask)
    }
    
    /// 专注相关积分
    func focusSessionCompleted(minutes: Int, isLongSession: Bool = false, isEarlyBird: Bool = false, isNightOwl: Bool = false) {
        earnPoints(for: .completeFocusSession, details: "\(minutes)分钟专注")
        
        if isLongSession {
            earnPoints(for: .longFocusSession, details: "长时间专注 (\(minutes)分钟)")
        }
        
        if isEarlyBird {
            earnPoints(for: .earlyBird, details: "早起专注")
        }
        
        if isNightOwl {
            earnPoints(for: .nightOwl, details: "深夜专注")
        }
    }
    
    /// 里程碑相关积分
    func milestoneReached(days: Int) {
        earnPoints(for: .reachMilestone, details: "\(days)天连续使用")
    }
    
    // MARK: - 数据持久化
    
    private func saveData() {
        // 保存等级数据
        if let encoded = try? JSONEncoder().encode(levelData) {
            userDefaults.set(encoded, forKey: levelDataKey)
        }
        
        // 保存最近积分记录
        if let encoded = try? JSONEncoder().encode(recentPointsEarned) {
            userDefaults.set(encoded, forKey: recentPointsKey)
        }
    }
    
    private func loadRecentPointRecords() {
        if let data = userDefaults.data(forKey: recentPointsKey),
           let records = try? JSONDecoder().decode([PointRecord].self, from: data) {
            self.recentPointsEarned = records
        }
    }
    
    // MARK: - 通知处理
    
    @objc private func handleAchievementUnlocked(_ notification: Notification) {
        if let achievement = notification.object as? Achievement {
            earnPoints(for: .unlockAchievement, details: achievement.title)
        }
    }
    
    // MARK: - 统计方法
    
    /// 获取今日获得的积分
    func getTodayPoints() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return recentPointsEarned
            .filter { $0.timestamp >= today && $0.timestamp < tomorrow }
            .reduce(0) { $0 + $1.points }
    }
    
    /// 获取今日获得的经验值
    func getTodayExperience() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return recentPointsEarned
            .filter { $0.timestamp >= today && $0.timestamp < tomorrow }
            .reduce(0) { $0 + $1.experience }
    }
    
    /// 获取最近7天的积分统计
    func getWeeklyPointsStats() -> [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var stats: [Int] = []
        
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: -i, to: today)!
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            
            let dayPoints = recentPointsEarned
                .filter { $0.timestamp >= day && $0.timestamp < nextDay }
                .reduce(0) { $0 + $1.points }
            
            stats.insert(dayPoints, at: 0)
        }
        
        return stats
    }
    
    // MARK: - 调试功能
    
    /// 重置所有数据（仅调试用）
    func resetAllData() {
        levelData = UserLevelData()
        recentPointsEarned = []
        saveData()
        print("📊 UserLevelManager: 已重置所有等级数据")
    }
    
    /// 添加测试积分（仅调试用）
    func addTestPoints(_ points: Int) {
        levelData.totalPoints += points
        levelData.totalExperience += points
        levelData.lastUpdated = Date()
        
        let newLevel = calculateLevel(for: levelData.totalExperience)
        if newLevel > levelData.currentLevel {
            let oldLevel = levelData.currentLevel
            levelData.currentLevel = newLevel
            NotificationCenter.default.post(
                name: Self.levelUpNotification,
                object: self,
                userInfo: ["oldLevel": oldLevel, "newLevel": newLevel]
            )
        }
        
        saveData()
        print("📊 UserLevelManager: 添加测试积分 +\(points)")
    }
}