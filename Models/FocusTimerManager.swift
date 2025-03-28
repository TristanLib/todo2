import Foundation
import Combine

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
    @Published var completedFocusSessions: Int = 0
    @Published var totalFocusSessions: Int = 0
    @Published var progress: Double = 0
    
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
    
    private var notificationManager = NotificationManager.shared
    private var soundManager = SoundManager.shared
    
    private init() {}
    
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
        let newState = state ?? (currentState == .paused ? currentState : .focusing)
        
        // 如果是从暂停状态恢复
        if currentState == .paused && newState != .idle {
            currentState = newState
            timeRemaining = pausedTimeRemaining
        } else {
            // 设置新状态的时间
            currentState = newState
            switch newState {
            case .focusing:
                timeRemaining = focusDuration
                soundManager.playSound(.startFocus)
                notificationManager.scheduleNotification(for: .focusStart)
            case .shortBreak:
                timeRemaining = shortBreakDuration
                soundManager.playSound(.startBreak)
                notificationManager.scheduleNotification(for: .breakStart)
            case .longBreak:
                timeRemaining = longBreakDuration
                soundManager.playSound(.startBreak)
                notificationManager.scheduleNotification(for: .breakStart)
            default:
                timeRemaining = focusDuration
            }
        }
        
        // 设置开始和结束时间
        startTime = Date()
        endTime = startTime?.addingTimeInterval(TimeInterval(timeRemaining))
        
        // 停止现有计时器
        stopTimer()
        
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
    }
    
    // 停止计时器
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        currentState = .idle
        timeRemaining = focusDuration
        progress = 0
    }
    
    // 更新计时器
    private func updateTimer() {
        guard timeRemaining > 0 else {
            handleTimerCompletion()
            return
        }
        
        timeRemaining -= 1
        
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
            
            // 播放完成声音
            soundManager.playSound(.endFocus)
            
            // 发送通知
            notificationManager.scheduleNotification(for: .focusEnd)
            
            // 决定下一个状态是短休息还是长休息
            if completedFocusSessions % sessionsBeforeLongBreak == 0 {
                startTimer(state: .longBreak)
            } else {
                startTimer(state: .shortBreak)
            }
            
        case .shortBreak, .longBreak:
            // 播放休息结束声音
            soundManager.playSound(.endBreak)
            
            // 发送通知
            notificationManager.scheduleNotification(for: .breakEnd)
            
            // 休息结束后回到空闲状态
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
            return "准备开始"
        case .focusing:
            return "专注中"
        case .shortBreak:
            return "短休息"
        case .longBreak:
            return "长休息"
        case .paused:
            if let previousState = previousStateBeforePause {
                switch previousState {
                case .focusing:
                    return "专注已暂停"
                case .shortBreak:
                    return "短休息已暂停"
                case .longBreak:
                    return "长休息已暂停"
                default:
                    return "已暂停"
                }
            } else {
                return "已暂停"
            }
        }
    }
} 