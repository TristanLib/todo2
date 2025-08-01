# TaskMate 用户留存功能技术实施指南

**版本**: v1.0  
**创建日期**: 2025-08-01  
**适用版本**: iOS 15.0+, Swift 6, Xcode 16  
**维护者**: 技术团队

## 📋 文档目的

本文档为TaskMate应用用户留存功能的技术实施提供详细指导，包括代码架构、具体实现方案、最佳实践和调试指南。

## 🏗️ 技术架构概览

### 核心架构原则
- **单一职责**: 每个管理器类负责单一功能领域
- **依赖注入**: 通过环境对象实现松耦合
- **响应式编程**: 使用Combine框架实现数据流
- **本地优先**: 数据优先存储在本地，减少网络依赖

### 模块依赖关系
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Views Layer   │    │  Managers Layer │    │   Data Layer    │
│                 │    │                 │    │                 │
│ StreakCardView  │◄──►│ StreakManager   │◄──►│ UserDefaults   │
│ AchievementView │◄──►│AchievementMgr   │◄──►│ CoreData       │
│ StatsView       │◄──►│ UserLevelMgr    │◄──►│ FileManager    │
│ ChallengeView   │◄──►│ ChallengeManager│◄──►│                │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🎯 Phase 1: 连续使用天数系统实施

### 1.1 StreakManager 核心实现

#### 数据模型设计
```swift
// Models/StreakData.swift
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
enum StreakStatus {
    case continuing     // 连续进行中
    case gracePeriod   // 宽限期
    case broken        // 已中断
    case newStart      // 新开始
}

/// 里程碑数据
struct StreakMilestone {
    let days: Int
    let title: String
    let description: String
    let rewardPoints: Int
    let isUnlocked: Bool
}
```

#### StreakManager 完整实现
```swift
// Services/StreakManager.swift
import Foundation
import Combine

class StreakManager: ObservableObject {
    static let shared = StreakManager()
    
    // MARK: - Published Properties
    @Published var streakData = StreakData()
    @Published var todayMarkedActive = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let streakDataKey = "streakData"
    private let calendar = Calendar.current
    private let gracePeriodHours: Int = 24
    
    // MARK: - Milestone Configuration
    private let milestones = [
        StreakMilestone(days: 3, title: "新的开始", description: "连续使用3天", rewardPoints: 100, isUnlocked: false),
        StreakMilestone(days: 7, title: "小有成就", description: "连续使用7天", rewardPoints: 200, isUnlocked: false),
        StreakMilestone(days: 30, title: "习惯初成", description: "连续使用30天", rewardPoints: 500, isUnlocked: false),
        StreakMilestone(days: 100, title: "终身习惯", description: "连续使用100天", rewardPoints: 1000, isUnlocked: false)
    ]
    
    // MARK: - Initialization
    private init() {
        loadStreakData()
        checkStreakStatusOnLaunch()
    }
    
    // MARK: - Public Methods
    
    /// 标记今天为活跃状态
    func markTodayAsActive() {
        let today = calendar.startOfDay(for: Date())
        
        // 避免重复标记同一天
        if let lastActiveDate = streakData.lastActiveDate,
           calendar.isDate(lastActiveDate, inSameDayAs: today) {
            return
        }
        
        updateStreakForToday()
        checkForMilestoneUnlock()
        saveStreakData()
        
        // 通知其他系统用户今日活跃
        NotificationCenter.default.post(name: .userMarkedActiveToday, object: nil)
    }
    
    /// 获取当前连续状态
    func getCurrentStatus() -> StreakStatus {
        let today = calendar.startOfDay(for: Date())
        
        guard let lastActiveDate = streakData.lastActiveDate else {
            return .newStart
        }
        
        let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDate, to: today).day ?? 0
        
        switch daysSinceLastActive {
        case 0:
            return .continuing
        case 1:
            return streakData.isInGracePeriod ? .gracePeriod : .broken
        default:
            return .broken
        }
    }
    
    /// 获取下一个里程碑
    func getNextMilestone() -> StreakMilestone? {
        return milestones.first { $0.days > streakData.currentStreak }
    }
    
    /// 获取已解锁的里程碑
    func getUnlockedMilestones() -> [StreakMilestone] {
        return milestones.filter { $0.days <= streakData.currentStreak }
    }
    
    // MARK: - Private Methods
    
    private func loadStreakData() {
        if let data = userDefaults.data(forKey: streakDataKey),
           let decoded = try? JSONDecoder().decode(StreakData.self, from: data) {
            self.streakData = decoded
        }
    }
    
    private func saveStreakData() {
        if let encoded = try? JSONEncoder().encode(streakData) {
            userDefaults.set(encoded, forKey: streakDataKey)
        }
    }
    
    private func checkStreakStatusOnLaunch() {
        let status = getCurrentStatus()
        
        switch status {
        case .broken:
            resetStreak()
        case .gracePeriod:
            // 保持当前状态，但提醒用户
            scheduleGracePeriodReminder()
        default:
            break
        }
    }
    
    private func updateStreakForToday() {
        let today = calendar.startOfDay(for: Date())
        
        if let lastActiveDate = streakData.lastActiveDate {
            let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDate, to: today).day ?? 0
            
            switch daysSinceLastActive {
            case 0:
                // 同一天，不需要更新
                return
            case 1:
                // 连续的下一天
                streakData.currentStreak += 1
            default:
                // 中断了，重新开始
                streakData.currentStreak = 1
            }
        } else {
            // 首次使用
            streakData.currentStreak = 1
        }
        
        streakData.lastActiveDate = today
        streakData.totalActiveDays += 1
        streakData.graceEndDate = calendar.date(byAdding: .hour, value: gracePeriodHours, to: Date())
        
        // 更新最长连续记录
        if streakData.currentStreak > streakData.longestStreak {
            streakData.longestStreak = streakData.currentStreak
        }
        
        todayMarkedActive = true
    }
    
    private func resetStreak() {
        streakData.currentStreak = 0
        streakData.graceEndDate = nil
        saveStreakData()
    }
    
    private func checkForMilestoneUnlock() {
        let newlyUnlockedMilestones = milestones.filter { milestone in
            milestone.days == streakData.currentStreak
        }
        
        for milestone in newlyUnlockedMilestones {
            // 触发里程碑解锁事件
            NotificationCenter.default.post(
                name: .streakMilestoneUnlocked,
                object: milestone
            )
            
            // 给用户奖励积分
            UserLevelManager.shared.addPoints(milestone.rewardPoints, for: .streakMilestone)
        }
    }
    
    private func scheduleGracePeriodReminder() {
        // 实现宽限期提醒逻辑
        NotificationManager.shared.scheduleStreakGracePeriodReminder()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userMarkedActiveToday = Notification.Name("userMarkedActiveToday")
    static let streakMilestoneUnlocked = Notification.Name("streakMilestoneUnlocked")
}
```

#### 与现有系统集成
```swift
// 在 FocusTimerManager.swift 中添加
class FocusTimerManager {
    // ... 现有代码 ...
    
    func completeCurrentSession() {
        // ... 现有逻辑 ...
        
        // 标记用户今日活跃
        StreakManager.shared.markTodayAsActive()
    }
}

// 在 TaskStore.swift 中添加  
class TaskStore {
    // ... 现有代码 ...
    
    func addTask(_ task: Task) {
        // ... 现有逻辑 ...
        
        // 标记用户今日活跃
        StreakManager.shared.markTodayAsActive()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        // ... 现有逻辑 ...
        
        // 完成任务时标记活跃
        if !task.isCompleted { // 任务从未完成变为完成
            StreakManager.shared.markTodayAsActive()
        }
    }
}
```

### 1.2 StreakCardView UI组件实现

```swift
// Views/Components/StreakCardView.swift
import SwiftUI

struct StreakCardView: View {
    @StateObject private var streakManager = StreakManager.shared
    @State private var showCelebration = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("连续使用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(streakManager.streakData.currentStreak)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("天")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 状态指示器
                StatusIndicatorView(status: streakManager.getCurrentStatus())
            }
            
            // 进度条和下一里程碑
            if let nextMilestone = streakManager.getNextMilestone() {
                ProgressTowardsMilestone(
                    current: streakManager.streakData.currentStreak,
                    target: nextMilestone.days,
                    title: nextMilestone.title
                )
            }
            
            // 最长记录显示
            if streakManager.streakData.longestStreak > streakManager.streakData.currentStreak {
                HStack {
                    Text("最长记录: \(streakManager.streakData.longestStreak)天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onReceive(NotificationCenter.default.publisher(for: .streakMilestoneUnlocked)) { notification in
            if let milestone = notification.object as? StreakMilestone {
                showMilestoneCelebration(milestone)
            }
        }
        .overlay(
            // 庆祝动画覆盖层
            celebrationOverlay
        )
    }
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        if showCelebration {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                CelebrationAnimationView()
                    .transition(.scale.combined(with: .opacity))
            }
            .onTapGesture {
                withAnimation {
                    showCelebration = false
                }
            }
        }
    }
    
    private func showMilestoneCelebration(_ milestone: StreakMilestone) {
        withAnimation(.spring()) {
            showCelebration = true
        }
        
        // 自动隐藏庆祝动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showCelebration = false
            }
        }
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// 状态指示器组件
struct StatusIndicatorView: View {
    let status: StreakStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .continuing:
            return .green
        case .gracePeriod:
            return .orange
        case .broken:
            return .red
        case .newStart:
            return .blue
        }
    }
    
    private var statusText: String {
        switch status {
        case .continuing:
            return "进行中"
        case .gracePeriod:
            return "宽限期"
        case .broken:
            return "已中断"
        case .newStart:
            return "新开始"
        }
    }
}

// 里程碑进度组件
struct ProgressTowardsMilestone: View {
    let current: Int
    let target: Int
    let title: String
    
    private var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("距离 \"\(title)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(current)/\(target)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 4)
            .cornerRadius(2)
        }
    }
}

// 庆祝动画组件
struct CelebrationAnimationView: View {
    @State private var animationAmount = 0.0
    @State private var sparkleOpacity = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            // 主图标动画
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .scaleEffect(1 + animationAmount)
                .rotation3DEffect(.degrees(animationAmount * 360), axis: (x: 0, y: 1, z: 0))
            
            // 恭喜文字
            VStack {
                Text("🎉 恭喜！")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("达成新的里程碑")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // 火花效果
            HStack {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .opacity(sparkleOpacity)
                        .offset(
                            x: CGFloat.random(in: -50...50),
                            y: CGFloat.random(in: -30...30)
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
                animationAmount = 0.3
            }
            
            withAnimation(.easeInOut(duration: 0.3).delay(0.2).repeatCount(6, autoreverses: true)) {
                sparkleOpacity = 1.0
            }
        }
    }
}
```

### 1.3 HomeView 集成

```swift
// Views/HomeView.swift 中添加
struct HomeView: View {
    // ... 现有属性 ...
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 添加连续天数卡片
                StreakCardView()
                    .padding(.horizontal)
                
                // ... 现有内容 ...
            }
        }
        .navigationTitle("TaskMate")
    }
}
```

## 🏆 Phase 1: 徽章系统实施

### 2.1 Achievement 数据模型

```swift
// Models/Achievement.swift
import Foundation
import SwiftUI

/// 徽章类别
enum AchievementCategory: String, CaseIterable, Codable {
    case focus = "focus"           // 专注相关
    case task = "task"            // 任务相关  
    case habit = "habit"          // 习惯相关
    case special = "special"      // 特殊成就
    
    var localizedName: String {
        switch self {
        case .focus: return NSLocalizedString("专注大师", comment: "Achievement category")
        case .task: return NSLocalizedString("任务管理", comment: "Achievement category")
        case .habit: return NSLocalizedString("习惯养成", comment: "Achievement category")
        case .special: return NSLocalizedString("特殊成就", comment: "Achievement category")
        }
    }
    
    var color: Color {
        switch self {
        case .focus: return .blue
        case .task: return .green
        case .habit: return .orange
        case .special: return .purple
        }
    }
}

/// 徽章稀有度
enum AchievementRarity: String, Codable, CaseIterable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .yellow
        }
    }
}

/// 徽章数据模型
struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let pointsReward: Int
    
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    var progress: Double = 0.0
    var targetValue: Int = 1
    
    /// 本地化标题
    var localizedTitle: String {
        return NSLocalizedString(title, comment: "Achievement title")
    }
    
    /// 本地化描述
    var localizedDescription: String {
        return NSLocalizedString(description, comment: "Achievement description")
    }
}

/// 用户事件类型 - 用于触发成就检测
enum UserEvent {
    case taskCompleted(count: Int)
    case focusSessionCompleted(duration: Int) // 分钟
    case streakDayReached(days: Int)
    case taskCreated
    case customCategoryCreated
    case perfectDay // 完成率100%
    case lateNightFocus(hour: Int)
    case earlyMorningFocus(hour: Int)
    case longFocusSession(duration: Int)
    case achievementShared
}
```

### 2.2 AchievementManager 实现

```swift
// Services/AchievementManager.swift
import Foundation
import Combine

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    // MARK: - Published Properties
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: [Achievement] = []
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "userAchievements"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        initializeAchievements()
        loadUserProgress()
        setupEventListeners()
    }
    
    // MARK: - Public Methods
    
    /// 处理用户事件并检查是否解锁新成就
    func handleUserEvent(_ event: UserEvent) {
        var newlyUnlocked: [Achievement] = []
        
        for i in achievements.indices {
            if !achievements[i].isUnlocked && checkAchievementCondition(achievements[i], for: event) {
                achievements[i].isUnlocked = true
                achievements[i].unlockedDate = Date()
                newlyUnlocked.append(achievements[i])
                
                // 奖励积分
                UserLevelManager.shared.addPoints(achievements[i].pointsReward, for: .achievementUnlocked)
            }
        }
        
        if !newlyUnlocked.isEmpty {
            recentlyUnlocked.append(contentsOf: newlyUnlocked)
            saveUserProgress()
            
            // 发送解锁通知
            for achievement in newlyUnlocked {
                NotificationCenter.default.post(
                    name: .achievementUnlocked,
                    object: achievement
                )
            }
        }
    }
    
    /// 获取已解锁的成就
    func getUnlockedAchievements() -> [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    /// 获取特定类别的成就
    func getAchievements(for category: AchievementCategory) -> [Achievement] {
        return achievements.filter { $0.category == category }
    }
    
    /// 计算总体解锁进度
    func getOverallProgress() -> Double {
        let totalAchievements = achievements.count
        let unlockedAchievements = getUnlockedAchievements().count
        return totalAchievements > 0 ? Double(unlockedAchievements) / Double(totalAchievements) : 0.0
    }
    
    /// 清除最近解锁的成就通知
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func initializeAchievements() {
        achievements = createDefaultAchievements()
    }
    
    private func createDefaultAchievements() -> [Achievement] {
        return [
            // 专注大师系列
            Achievement(
                id: "focus_first_session",
                title: "初试身手",
                description: "完成第一个番茄钟",
                iconName: "timer",
                category: .focus,
                rarity: .common,
                pointsReward: 50
            ),
            Achievement(
                id: "focus_10_hours",
                title: "专注新手",
                description: "累计专注10小时", 
                iconName: "clock.fill",
                category: .focus,
                rarity: .common,
                pointsReward: 100,
                targetValue: 600 // 10小时 = 600分钟
            ),
            Achievement(
                id: "focus_50_hours",
                title: "专注能手",
                description: "累计专注50小时",
                iconName: "gauge.high",
                category: .focus,
                rarity: .rare,
                pointsReward: 300,
                targetValue: 3000 // 50小时 = 3000分钟
            ),
            Achievement(
                id: "focus_night_owl",
                title: "夜猫子",
                description: "深夜23:00后还在专注",
                iconName: "moon.stars.fill",
                category: .focus,
                rarity: .epic,
                pointsReward: 150
            ),
            Achievement(
                id: "focus_early_bird",
                title: "早起鸟",
                description: "早上6:00前开始专注",
                iconName: "sunrise.fill",
                category: .focus,
                rarity: .epic,
                pointsReward: 150
            ),
            
            // 任务管理系列
            Achievement(
                id: "task_first_create",
                title: "任务新手",
                description: "创建第一个任务",
                iconName: "plus.circle",
                category: .task,
                rarity: .common,
                pointsReward: 25
            ),
            Achievement(
                id: "task_daily_10",
                title: "高效达人",
                description: "单日完成10个任务",
                iconName: "checkmark.circle.fill",
                category: .task,
                rarity: .rare,
                pointsReward: 200,
                targetValue: 10
            ),
            Achievement(
                id: "task_perfect_week",
                title: "完美主义者",
                description: "连续7天完成率100%",
                iconName: "star.circle.fill",
                category: .task,
                rarity: .epic,
                pointsReward: 400,
                targetValue: 7
            ),
            Achievement(
                id: "task_500_completed",
                title: "清单杀手",
                description: "累计完成500个任务",
                iconName: "list.bullet.circle.fill",
                category: .task,
                rarity: .legendary,
                pointsReward: 800,
                targetValue: 500
            ),
            
            // 习惯养成系列
            Achievement(
                id: "habit_3_days",
                title: "新的开始",
                description: "连续使用3天",
                iconName: "3.circle.fill",
                category: .habit,
                rarity: .common,
                pointsReward: 75
            ),
            Achievement(
                id: "habit_7_days",
                title: "小有成就", 
                description: "连续使用7天",
                iconName: "7.circle.fill",
                category: .habit,
                rarity: .common,
                pointsReward: 150
            ),
            Achievement(
                id: "habit_30_days",
                title: "习惯初成",
                description: "连续使用30天",
                iconName: "30.circle.fill",
                category: .habit,
                rarity: .rare,
                pointsReward: 500
            ),
            Achievement(
                id: "habit_100_days",
                title: "终身习惯",
                description: "连续使用100天",
                iconName: "100.circle.fill",
                category: .habit,
                rarity: .legendary,
                pointsReward: 1500
            ),
            
            // 特殊成就系列
            Achievement(
                id: "special_8_hour_day",
                title: "工作狂",
                description: "单日专注超过8小时",
                iconName: "laptopcomputer",
                category: .special,
                rarity: .epic,
                pointsReward: 300,
                targetValue: 480 // 8小时 = 480分钟
            ),
            Achievement(
                id: "special_custom_category",
                title: "自定义达人",
                description: "创建10个自定义分类",
                iconName: "folder.badge.plus",
                category: .special,
                rarity: .rare,
                pointsReward: 200,
                targetValue: 10
            )
        ]
    }
    
    private func checkAchievementCondition(_ achievement: Achievement, for event: UserEvent) -> Bool {
        switch (achievement.id, event) {
        case ("focus_first_session", .focusSessionCompleted):
            return true
            
        case ("focus_10_hours", .focusSessionCompleted):
            let totalMinutes = FocusTimerManager.shared.getTotalFocusMinutes()
            return totalMinutes >= achievement.targetValue
            
        case ("focus_50_hours", .focusSessionCompleted):
            let totalMinutes = FocusTimerManager.shared.getTotalFocusMinutes()
            return totalMinutes >= achievement.targetValue
            
        case ("focus_night_owl", .lateNightFocus(let hour)):
            return hour >= 23
            
        case ("focus_early_bird", .earlyMorningFocus(let hour)):
            return hour <= 6
            
        case ("task_first_create", .taskCreated):
            return true
            
        case ("task_daily_10", .taskCompleted(let count)):
            return count >= achievement.targetValue
            
        case ("task_perfect_week", .perfectDay):
            // 需要检查连续7天完成率100% - 这里简化处理
            return checkPerfectWeekCondition()
            
        case ("task_500_completed", .taskCompleted):
            let totalCompleted = TaskStore.shared.getTotalCompletedTasksCount()
            return totalCompleted >= achievement.targetValue
            
        case ("habit_3_days", .streakDayReached(let days)):
            return days >= 3
            
        case ("habit_7_days", .streakDayReached(let days)):
            return days >= 7
            
        case ("habit_30_days", .streakDayReached(let days)):
            return days >= 30
            
        case ("habit_100_days", .streakDayReached(let days)):
            return days >= 100
            
        case ("special_8_hour_day", .focusSessionCompleted):
            let todayMinutes = FocusTimerManager.shared.getTodayFocusMinutes()
            return todayMinutes >= achievement.targetValue
            
        case ("special_custom_category", .customCategoryCreated):
            let customCategoryCount = CategoryManager.shared.getCustomCategoriesCount()
            return customCategoryCount >= achievement.targetValue
            
        default:
            return false
        }
    }
    
    private func checkPerfectWeekCondition() -> Bool {
        // 实现检查连续7天完成率100%的逻辑
        // 这里需要从TaskStore获取历史数据进行检查
        return false // 简化实现
    }
    
    private func loadUserProgress() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let savedAchievements = try? JSONDecoder().decode([Achievement].self, from: data) {
            
            // 合并保存的进度与默认成就
            for savedAchievement in savedAchievements {
                if let index = achievements.firstIndex(where: { $0.id == savedAchievement.id }) {
                    achievements[index] = savedAchievement
                }
            }
        }
    }
    
    private func saveUserProgress() {
        if let data = try? JSONEncoder().encode(achievements) {
            userDefaults.set(data, forKey: achievementsKey)
        }
    }
    
    private func setupEventListeners() {
        // 监听焦点会话完成事件
        NotificationCenter.default.publisher(for: .focusSessionCompleted)
            .sink { [weak self] notification in
                if let duration = notification.object as? Int {
                    self?.handleUserEvent(.focusSessionCompleted(duration: duration))
                    
                    // 检查时间相关的特殊成就
                    let hour = Calendar.current.component(.hour, from: Date())
                    if hour >= 23 || hour <= 1 {
                        self?.handleUserEvent(.lateNightFocus(hour: hour))
                    } else if hour <= 6 {
                        self?.handleUserEvent(.earlyMorningFocus(hour: hour))
                    }
                }
            }
            .store(in: &cancellables)
        
        // 监听任务完成事件
        NotificationCenter.default.publisher(for: .taskCompleted)
            .sink { [weak self] notification in
                // 获取今日完成任务数
                let todayCompletedCount = TaskStore.shared.getTodayCompletedTasksCount()
                self?.handleUserEvent(.taskCompleted(count: todayCompletedCount))
                
                // 检查是否是完美的一天
                if TaskStore.shared.getTodayCompletionRate() >= 1.0 {
                    self?.handleUserEvent(.perfectDay)
                }
            }
            .store(in: &cancellables)
        
        // 监听连续天数里程碑事件
        NotificationCenter.default.publisher(for: .streakMilestoneUnlocked)
            .sink { [weak self] notification in
                if let milestone = notification.object as? StreakMilestone {
                    self?.handleUserEvent(.streakDayReached(days: milestone.days))
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
    static let focusSessionCompleted = Notification.Name("focusSessionCompleted")
    static let taskCompleted = Notification.Name("taskCompleted")
}
```

### 2.3 徽章展示UI组件

```swift
// Views/AchievementGridView.swift
import SwiftUI

struct AchievementGridView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showUnlockedOnly = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选控制
                filterControls
                
                // 进度总览
                progressOverview
                
                // 成就网格
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCardView(achievement: achievement)
                                .onTapGesture {
                                    showAchievementDetail(achievement)
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("我的成就")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var filterControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部按钮
                FilterChip(
                    title: "全部",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                // 分类筛选
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.localizedName,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
                
                Spacer(minLength: 0)
                
                // 显示开关
                Toggle("仅已解锁", isOn: $showUnlockedOnly)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .scaleEffect(0.8)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var progressOverview: some View {
        VStack(spacing: 8) {
            HStack {
                Text("解锁进度")
                    .font(.headline)
                Spacer()
                Text("\(achievementManager.getUnlockedAchievements().count)/\(achievementManager.achievements.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: achievementManager.getOverallProgress())
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var filteredAchievements: [Achievement] {
        var filtered = achievementManager.achievements
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if showUnlockedOnly {
            filtered = filtered.filter { $0.isUnlocked }
        }
        
        return filtered.sorted { first, second in
            // 已解锁的排在前面
            if first.isUnlocked != second.isUnlocked {
                return first.isUnlocked
            }
            // 相同解锁状态按稀有度排序
            return first.rarity.rawValue < second.rarity.rawValue
        }
    }
    
    private func showAchievementDetail(_ achievement: Achievement) {
        // 显示成就详情
        // 可以导航到详情页面或显示弹窗
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct AchievementCardView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            // 徽章图标
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.category.color : Color(.systemGray4))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? .white : .secondary)
            }
            .overlay(
                // 稀有度边框
                Circle()
                    .stroke(achievement.rarity.color, lineWidth: achievement.isUnlocked ? 2 : 0)
                    .frame(width: 54, height: 54)
            )
            
            // 标题和描述
            VStack(spacing: 2) {
                Text(achievement.localizedTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                
                Text(achievement.localizedDescription)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 解锁状态
            if achievement.isUnlocked {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    if let date = achievement.unlockedDate {
                        Text(formatDate(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: achievement.isUnlocked)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
```

## 📱 调试与测试指南

### 调试工具

```swift
// Debug/AchievementDebugView.swift
#if DEBUG
import SwiftUI

struct AchievementDebugView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    
    var body: some View {
        List {
            Section("测试事件") {
                Button("完成专注会话") {
                    achievementManager.handleUserEvent(.focusSessionCompleted(duration: 25))
                }
                
                Button("完成10个任务") {
                    achievementManager.handleUserEvent(.taskCompleted(count: 10))
                }
                
                Button("达成7天连续") {
                    achievementManager.handleUserEvent(.streakDayReached(days: 7))
                }
                
                Button("深夜专注") {
                    achievementManager.handleUserEvent(.lateNightFocus(hour: 23))
                }
            }
            
            Section("重置数据") {
                Button("重置所有成就", role: .destructive) {
                    resetAllAchievements()
                }
            }
        }
        .navigationTitle("成就调试")
    }
    
    private func resetAllAchievements() {
        UserDefaults.standard.removeObject(forKey: "userAchievements")
        achievementManager.achievements = achievementManager.achievements.map { achievement in
            var reset = achievement
            reset.isUnlocked = false
            reset.unlockedDate = nil
            reset.progress = 0.0
            return reset
        }
    }
}
#endif
```

### 单元测试示例

```swift
// Tests/AchievementManagerTests.swift
import XCTest
@testable import TaskMate

class AchievementManagerTests: XCTestCase {
    var achievementManager: AchievementManager!
    
    override func setUp() {
        super.setUp()
        achievementManager = AchievementManager.shared
        // 重置测试环境
        resetTestEnvironment()
    }
    
    func testFirstFocusSessionUnlocksAchievement() {
        // Given
        let achievement = achievementManager.achievements.first { $0.id == "focus_first_session" }
        XCTAssertNotNil(achievement)
        XCTAssertFalse(achievement!.isUnlocked)
        
        // When
        achievementManager.handleUserEvent(.focusSessionCompleted(duration: 25))
        
        // Then
        let updatedAchievement = achievementManager.achievements.first { $0.id == "focus_first_session" }
        XCTAssertTrue(updatedAchievement!.isUnlocked)
        XCTAssertNotNil(updatedAchievement!.unlockedDate)
    }
    
    func testMultipleTaskCompletionUnlocksAchievement() {
        // Given
        let achievement = achievementManager.achievements.first { $0.id == "task_daily_10" }
        XCTAssertFalse(achievement!.isUnlocked)
        
        // When
        achievementManager.handleUserEvent(.taskCompleted(count: 10))
        
        // Then
        let updatedAchievement = achievementManager.achievements.first { $0.id == "task_daily_10" }
        XCTAssertTrue(updatedAchievement!.isUnlocked)
    }
    
    private func resetTestEnvironment() {
        UserDefaults.standard.removeObject(forKey: "userAchievements")
        achievementManager.achievements = achievementManager.achievements.map { achievement in
            var reset = achievement
            reset.isUnlocked = false
            reset.unlockedDate = nil
            reset.progress = 0.0
            return reset
        }
    }
}
```

## 📋 最佳实践与注意事项

### 1. 性能优化
- **延迟加载**: 成就图标和动画资源使用延迟加载
- **数据缓存**: 统计数据进行适当缓存，避免重复计算
- **批量更新**: 避免频繁的UserDefaults写入操作

### 2. 用户体验
- **渐进式揭示**: 新用户不应看到过多未解锁的成就
- **即时反馈**: 成就解锁时提供明显的视觉和触觉反馈
- **个性化**: 根据用户使用习惯推荐相关成就

### 3. 数据安全
- **本地存储**: 成就数据优先存储在本地设备
- **数据验证**: 防止用户恶意修改成就数据
- **备份机制**: 支持成就数据的备份和恢复

### 4. 国际化支持
- **文本本地化**: 所有用户可见文本都要本地化
- **文化适应**: 考虑不同文化背景下的成就设计
- **时间格式**: 使用用户本地的时间格式

---

**文档更新**: 随着开发进度持续更新技术细节  
**代码审查**: 所有代码都需要经过同行评审  
**测试覆盖**: 确保核心功能有充分的单元测试覆盖