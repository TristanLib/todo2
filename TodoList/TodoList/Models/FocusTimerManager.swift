import Foundation
import Combine
import UIKit
import UserNotifications

// 计时器状态
enum FocusTimerState: String {
    case idle = "idle"               // 空闲
    case focusing = "focusing"       // 专注中
    case shortBreak = "shortBreak"   // 短休息
    case longBreak = "longBreak"     // 长休息
    case paused = "paused"           // 暂停
}

class FocusTimerManager: ObservableObject {
    // 单例
    static let shared = FocusTimerManager()

    // 发布者
    @Published var timeRemaining: Int = 0
    @Published var currentState: FocusTimerState = .idle
    @Published var completedFocusSessions: Int = 0 {
        didSet {
            // 保存到 UserDefaults
            UserDefaults.standard.set(completedFocusSessions, forKey: "completedFocusSessions")
        }
    }
    @Published var totalFocusSessions: Int = 0
    @Published var progress: Double = 0

    // 今日完成的专注次数
    @Published var todayCompletedFocusSessions: Int = 0 {
        didSet {
            // 保存到 UserDefaults，带上日期标记
            let today = Calendar.current.startOfDay(for: Date())
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: today)

            UserDefaults.standard.set(todayCompletedFocusSessions, forKey: "todayCompletedFocusSessions_\(todayString)")
        }
    }

    // 今日累计专注时间（秒）
    @Published var todayTotalFocusTime: Int = 0 {
        didSet {
            // 保存到 UserDefaults，带上日期标记
            let today = Calendar.current.startOfDay(for: Date())
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: today)

            UserDefaults.standard.set(todayTotalFocusTime, forKey: "todayTotalFocusTime_\(todayString)")
        }
    }

    // 设置
    private var focusDuration: Int = 25 * 60  // 默认25分钟
    private var shortBreakDuration: Int = 5 * 60  // 默认5分钟
    private var longBreakDuration: Int = 15 * 60  // 默认15分钟
    private var sessionsBeforeLongBreak: Int = 4  // 默认4个专注后长休息

    // 内部属性
    private var timer: Timer?
    private var startTime: Date?
    private var endTime: Date?
    private var pausedTimeRemaining: Int = 0
    private var backgroundTime: Date? // 进入后台的时间

    private var notificationManager = NotificationManager.shared
    private var soundManager = SoundManager.shared
    private var taskStore: TaskStore?

    private init() {
        // 从 UserDefaults 加载已完成的专注会话数
        completedFocusSessions = UserDefaults.standard.integer(forKey: "completedFocusSessions")

        // 加载今日完成的专注次数和累计专注时间
        loadTodayData()

        // 添加应用生命周期的观察者
        setupAppLifecycleObservers()

        // 延迟获取TaskStore实例，避免循环引用
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.taskStore = TaskStore.shared
        }
    }

    // 加载今日数据（完成的专注次数和累计专注时间）
    private func loadTodayData() {
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)

        todayCompletedFocusSessions = UserDefaults.standard.integer(forKey: "todayCompletedFocusSessions_\(todayString)")
        todayTotalFocusTime = UserDefaults.standard.integer(forKey: "todayTotalFocusTime_\(todayString)")
    }

    // 设置应用生命周期观察者
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // 应用将要进入非活跃状态（如锁屏、切换到其他应用）
    @objc private func appWillResignActive() {
        // 记录当前时间
        backgroundTime = Date()
    }

    // 应用进入后台
    @objc private func appDidEnterBackground() {
        if currentState != .idle && currentState != .paused {
            // 暂停Timer，但不改变计时器状态
            timer?.invalidate()
            timer = nil

            // 记录剩余时间，但不改变currentState
            if backgroundTime == nil {
                backgroundTime = Date()
            }
        }
    }

    // 应用将要进入前台
    @objc private func appWillEnterForeground() {
        if currentState != .idle && currentState != .paused && backgroundTime != nil {
            handleBackgroundToForeground()
        }
    }

    // 应用成为活跃状态
    @objc private func appDidBecomeActive() {
        if currentState != .idle && currentState != .paused && backgroundTime != nil {
            handleBackgroundToForeground()
        }
    }

    // 处理应用从后台回到前台的逻辑
    private func handleBackgroundToForeground() {
        guard let backgroundTime = backgroundTime, let endTime = endTime else { return }

        // 计算在后台经过的时间
        let now = Date()
        let elapsedBackgroundTime = Int(now.timeIntervalSince(backgroundTime))

        // 更新剩余时间
        let newRemainingTime = max(0, Int(endTime.timeIntervalSince(now)))

        // 如果计时器结束
        if newRemainingTime <= 0 {
            // 计时器已结束，处理完成
            timeRemaining = 0
            handleTimerCompletion()
        } else {
            // 更新剩余时间
            timeRemaining = newRemainingTime

            // 重新启动计时器
            startTimerWithoutReset()
        }

        // 重置后台时间
        self.backgroundTime = nil
    }

    // 重新启动计时器但不重置时间
    private func startTimerWithoutReset() {
        // 停止现有计时器
        timer?.invalidate()
        timer = nil

        // 开始新计时器
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }

        updateProgress()
    }

    // 更新设置
    func updateSettings(from settings: FocusSettings) {
        let shouldRestartTimer = timer != nil && currentState != .idle && currentState != .paused

        if shouldRestartTimer {
            stopTimer()
        }

        focusDuration = Int(settings.focusDuration * 60)
        shortBreakDuration = Int(settings.shortBreakDuration * 60)
        longBreakDuration = Int(settings.longBreakDuration * 60)
        sessionsBeforeLongBreak = settings.pomoBeforeBreak

        soundManager.setEnabled(settings.enableSound)

        if settings.enableNotification {
            notificationManager.requestAuthorization { _ in }
            notificationManager.setEnabled(true)
        } else {
            notificationManager.setEnabled(false)
        }

        // 如果计时器正在运行，需要用新设置重新启动
        if shouldRestartTimer {
            startTimer(state: currentState)
        } else if currentState == .idle {
            timeRemaining = focusDuration
            updateProgress()
        }
    }

    // 开始计时器
    func startTimer(state: FocusTimerState? = nil) {
        // 如果是从暂停状态恢复
        if currentState == .paused {
            // 如果指定了新状态，使用新状态，否则恢复到暂停前的状态
            if let newState = state, newState != .paused {
                currentState = newState

                // 根据新状态设置时间
                switch newState {
                case .focusing:
                    timeRemaining = focusDuration
                    soundManager.playSound(.startFocus)
                    // 在专注模式启动时播放当前设置的白噪音
                    if soundManager.currentWhiteNoise != .none && soundManager.isEnabled {
                        soundManager.playWhiteNoise(soundManager.currentWhiteNoise)
                        print("从暂停恢复到专注状态，播放白噪音: \(soundManager.currentWhiteNoise.displayName)")
                    } else {
                        print("从暂停恢复到专注状态，但不播放白噪音")
                    }
                    notificationManager.scheduleNotification(for: .focusStart)
                case .shortBreak:
                    timeRemaining = shortBreakDuration
                    soundManager.playSound(.startBreak)
                    // 休息时停止白噪音
                    soundManager.stopWhiteNoise()
                    notificationManager.scheduleNotification(for: .breakStart)
                case .longBreak:
                    timeRemaining = longBreakDuration
                    soundManager.playSound(.startBreak)
                    // 休息时停止白噪音
                    soundManager.stopWhiteNoise()
                    notificationManager.scheduleNotification(for: .breakStart)
                default:
                    timeRemaining = focusDuration
                }
            } else if let previousState = previousStateBeforePause {
                // 恢复到暂停前的状态
                currentState = previousState
                timeRemaining = pausedTimeRemaining

                // 如果恢复到专注状态，重新播放白噪音
                if previousState == .focusing && soundManager.currentWhiteNoise != .none && soundManager.isEnabled {
                    soundManager.playWhiteNoise(soundManager.currentWhiteNoise)
                    print("恢复到暂停前的专注状态，播放白噪音: \(soundManager.currentWhiteNoise.displayName)")
                } else if previousState == .focusing {
                    print("恢复到暂停前的专注状态，但不播放白噪音")
                }
            } else {
                // 默认恢复到专注状态
                currentState = .focusing
                timeRemaining = pausedTimeRemaining

                // 重新播放白噪音
                if soundManager.currentWhiteNoise != .none && soundManager.isEnabled {
                    soundManager.playWhiteNoise(soundManager.currentWhiteNoise)
                    print("默认恢复到专注状态，播放白噪音: \(soundManager.currentWhiteNoise.displayName)")
                } else {
                    print("默认恢复到专注状态，但不播放白噪音")
                }
            }
        } else {
            // 设置新状态的时间
            let newState = state ?? .focusing
            currentState = newState

            switch newState {
            case .focusing:
                timeRemaining = focusDuration
                soundManager.playSound(.startFocus)
                // 在专注模式启动时播放当前设置的白噪音
                if soundManager.currentWhiteNoise != .none && soundManager.isEnabled {
                    // 确保在开始专注时播放白噪音
                    soundManager.playWhiteNoise(soundManager.currentWhiteNoise)
                    print("开始专注，播放白噪音: \(soundManager.currentWhiteNoise.displayName)")
                } else {
                    print("开始专注，但不播放白噪音: \(soundManager.isEnabled ? "无白噪音选择" : "音效已禁用")")
                }
                notificationManager.scheduleNotification(for: .focusStart)
            case .shortBreak:
                timeRemaining = shortBreakDuration
                soundManager.playSound(.startBreak)
                // 休息时停止白噪音
                soundManager.stopWhiteNoise()
                notificationManager.scheduleNotification(for: .breakStart)
            case .longBreak:
                timeRemaining = longBreakDuration
                soundManager.playSound(.startBreak)
                // 休息时停止白噪音
                soundManager.stopWhiteNoise()
                notificationManager.scheduleNotification(for: .breakStart)
            default:
                timeRemaining = focusDuration
            }
        }

        // 设置开始和结束时间
        startTime = Date()
        endTime = startTime?.addingTimeInterval(TimeInterval(timeRemaining))

        // 停止现有计时器
        timer?.invalidate()
        timer = nil

        // 开始新计时器
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }

        updateProgress()
    }

    // 暂停计时器
    func pauseTimer() {
        guard currentState != .idle && currentState != .paused else { return }

        pausedTimeRemaining = timeRemaining
        currentState = .paused
        timer?.invalidate()
        timer = nil

        // 在专注暂停时停止白噪音播放
        soundManager.stopWhiteNoise()
    }

    // 停止计时器
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        currentState = .idle
        timeRemaining = focusDuration
        progress = 0
        backgroundTime = nil

        // 在专注停止时停止白噪音播放
        soundManager.stopWhiteNoise()

        // 清除应用图标标记
        notificationManager.clearApplicationBadge()

        // 恢复显示未完成任务数量
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.taskStore?.updateApplicationBadge()

            // 确保UI更新
            self?.objectWillChange.send()
        }
    }

    // 更新计时器
    private func updateTimer() {
        guard let endTime = endTime else {
            handleTimerCompletion()
            return
        }

        // 计算剩余时间
        let now = Date()
        let newTimeRemaining = max(0, Int(endTime.timeIntervalSince(now)))

        // 如果计时完成
        if newTimeRemaining <= 0 {
            handleTimerCompletion()
            return
        }

        // 更新剩余时间
        timeRemaining = newTimeRemaining

        // 更新进度
        updateProgress()

        // 在最后10秒播放滴答声
        if timeRemaining <= 10 && timeRemaining > 0 {
            soundManager.playSound(.tick)
        }
    }

    // 处理计时器完成
    private func handleTimerCompletion() {
        switch currentState {
        case .focusing:
            // 完成一个专注会话
            completedFocusSessions += 1
            totalFocusSessions = max(totalFocusSessions, completedFocusSessions)

            // 显式保存到UserDefaults，确保数据持久化
            UserDefaults.standard.set(completedFocusSessions, forKey: "completedFocusSessions")
            UserDefaults.standard.synchronize()

            // 更新今日结果
            updateTodayData()

            // 确保UI立即更新
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }

            // 播放完成声音
            soundManager.playSound(.endFocus)

            // 发送通知
            notificationManager.scheduleNotification(for: .focusEnd)

            // 清除应用图标标记
            notificationManager.clearApplicationBadge()

            // 恢复显示未完成任务数量
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.taskStore?.updateApplicationBadge()
            }
            
            // 修改：专注结束后回到空闲状态，等待用户手动开始休息
            // 不再自动启动休息模式
            stopTimer()

        case .shortBreak, .longBreak:
            // 播放休息结束声音
            soundManager.playSound(.endBreak)

            // 发送通知
            notificationManager.scheduleNotification(for: .breakEnd)

            // 清除应用图标标记
            notificationManager.clearApplicationBadge()

            // 恢复显示未完成任务数量
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.taskStore?.updateApplicationBadge()
            }

            // 休息结束后回到空闲状态
            // 确保UI更新
            objectWillChange.send()
            stopTimer()

        default:
            stopTimer()
        }
    }

    // 更新进度
    private func updateProgress() {
        let totalTime: Double

        switch currentState {
        case .focusing:
            totalTime = Double(focusDuration)
        case .shortBreak:
            totalTime = Double(shortBreakDuration)
        case .longBreak:
            totalTime = Double(longBreakDuration)
        case .paused:
            // 暂停状态使用对应状态的总时间
            if let lastState = previousStateBeforePause {
                switch lastState {
                case .focusing:
                    totalTime = Double(focusDuration)
                case .shortBreak:
                    totalTime = Double(shortBreakDuration)
                case .longBreak:
                    totalTime = Double(longBreakDuration)
                default:
                    totalTime = Double(focusDuration)
                }
            } else {
                totalTime = Double(focusDuration)
            }
        default:
            totalTime = Double(focusDuration)
        }

        // 避免除以零
        if totalTime > 0 {
            progress = 1.0 - Double(timeRemaining) / totalTime
        } else {
            progress = 0
        }
    }

    // 重置会话计数
    func resetSessions() {
        completedFocusSessions = 0
        // 保存到 UserDefaults
        UserDefaults.standard.set(0, forKey: "completedFocusSessions")
    }

    // 更新今日数据（专注次数和累计时间）
    private func updateTodayData() {
        // 更新今日专注次数
        todayCompletedFocusSessions += 1

        // 将完成的专注时间（默认为focusDuration）添加到今日累计时间
        todayTotalFocusTime += focusDuration

        // 确保数据持久化
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)

        UserDefaults.standard.set(todayCompletedFocusSessions, forKey: "todayCompletedFocusSessions_\(todayString)")
        UserDefaults.standard.set(todayTotalFocusTime, forKey: "todayTotalFocusTime_\(todayString)")
        UserDefaults.standard.synchronize()

        // 强制刷新UI
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }

    // 获取格式化的今日累计专注时间
    func formattedTodayTotalFocusTime() -> String {
        let hours = todayTotalFocusTime / 3600
        let minutes = (todayTotalFocusTime % 3600) / 60

        if hours > 0 {
            return String(format: NSLocalizedString("%d小时%02d分钟", comment: "Hours and minutes format"), hours, minutes)
        } else {
            return String(format: NSLocalizedString("%d分钟", comment: "Minutes only format"), minutes)
        }
    }

    // 获取暂停前的状态
    private var previousStateBeforePause: FocusTimerState? {
        guard currentState == .paused else { return nil }

        // 根据pausedTimeRemaining判断之前的状态
        if pausedTimeRemaining <= focusDuration && pausedTimeRemaining > 0 {
            return .focusing
        } else if pausedTimeRemaining <= shortBreakDuration && pausedTimeRemaining > 0 {
            return .shortBreak
        } else if pausedTimeRemaining <= longBreakDuration && pausedTimeRemaining > 0 {
            return .longBreak
        }

        return .focusing // 默认
    }

    // 格式化时间
    func formattedTimeRemaining() -> String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // 获取当前状态的显示名称
    func currentStateDisplayName() -> String {
        switch currentState {
        case .idle:
            return NSLocalizedString("准备开始", comment: "Focus timer idle state")
        case .focusing:
            return NSLocalizedString("专注中", comment: "Focusing state")
        case .shortBreak:
            return NSLocalizedString("短休息", comment: "Short break state")
        case .longBreak:
            return NSLocalizedString("长休息", comment: "Long break state")
        case .paused:
            if let previousState = previousStateBeforePause {
                switch previousState {
                case .focusing:
                    return NSLocalizedString("专注已暂停", comment: "Focus paused state")
                case .shortBreak:
                    return NSLocalizedString("短休息已暂停", comment: "Short break paused state")
                case .longBreak:
                    return NSLocalizedString("长休息已暂停", comment: "Long break paused state")
                default:
                    return NSLocalizedString("已暂停", comment: "Generic paused state")
                }
            } else {
                return NSLocalizedString("已暂停", comment: "Generic paused state")
            }
        }
    }
}