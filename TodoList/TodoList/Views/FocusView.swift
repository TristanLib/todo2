import SwiftUI

struct FocusView: View {
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject private var focusTimer = FocusTimerManager.shared
    @State private var showStopConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题和状态
                VStack(spacing: 8) {
                    Text(focusTimer.currentStateDisplayName())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .animation(.none)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    // 今日目标
                    VStack(spacing: 4) {
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("今日目标: %d个专注，%d分钟", comment: "Daily focus target"), 
                            appSettings.focusSettings.dailyFocusSessionsTarget,
                            appSettings.focusSettings.dailyFocusTimeTarget
                        ))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(spacing: 4) {
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("已完成 %d 个专注", comment: "Number of completed focus sessions"), 
                            focusTimer.todayCompletedFocusSessions
                        ))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // 显示今日累计专注时间
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("今日已累计完成 %@", comment: "Total focus time today"), 
                            focusTimer.formattedTodayTotalFocusTime()
                        ))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 计时器显示 - 使用 GeometryReader 使其自适应
                GeometryReader { geometry in
                    let timerSize = min(geometry.size.width * 0.7, geometry.size.height * 0.4)
                    let lineWidth: CGFloat = max(timerSize * 0.07, 15)
                    
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: lineWidth)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(focusTimer.progress))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [appSettings.accentColor.color, appSettings.accentColor.color.opacity(0.6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.25), value: focusTimer.progress)
                        
                        Text(focusTimer.formattedTimeRemaining())
                            .font(.system(size: timerSize * 0.25, weight: .medium, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .frame(width: timerSize, height: timerSize)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .frame(maxHeight: 350)

                // 控制按钮
                HStack(spacing: 30) {
                    // 重置按钮 - 用于清除已完成的专注会话记录
                    Button(action: {
                        // 重置会话按钮 - 清除已完成的专注会话计数
                        focusTimer.resetSessions()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                            .foregroundColor(.secondary)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .disabled(focusTimer.completedFocusSessions == 0)
                    .opacity(focusTimer.completedFocusSessions == 0 ? 0.5 : 1)
                    
                    if focusTimer.currentState == .idle {
                        Button(action: {
                            focusTimer.startTimer()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                    } else if focusTimer.currentState == .paused {
                        Button(action: {
                            focusTimer.startTimer()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                    } else {
                        Button(action: {
                            focusTimer.pauseTimer()
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                    }
                    
                    Button(action: {
                        // 仅在非空闲状态下显示确认对话框
                        if focusTimer.currentState != .idle {
                            showStopConfirmation = true
                        }
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .disabled(focusTimer.currentState == .idle)
                    .opacity(focusTimer.currentState == .idle ? 0.5 : 1)
                }
                .padding(.horizontal)
                
                // 专注进度可视化部分
                VStack(alignment: .center, spacing: 8) {
                    Text(NSLocalizedString("今日专注进度", comment: "Today's focus progress"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 使用番茄图标来可视化进度
                    let targetSessions = appSettings.focusSettings.dailyFocusSessionsTarget
                    let completedSessions = focusTimer.todayCompletedFocusSessions
                    
                    // 计算每行显示的番茄数量
                    let itemsPerRow = min(6, targetSessions) // 每行最多显示6个
                    let rowCount = (targetSessions + itemsPerRow - 1) / itemsPerRow // 向上取整
                    
                    VStack(spacing: 8) {
                        ForEach(0..<rowCount, id: \.self) { rowIndex in
                            HStack(spacing: 8) {
                                ForEach(0..<min(itemsPerRow, targetSessions - rowIndex * itemsPerRow), id: \.self) { colIndex in
                                    let index = rowIndex * itemsPerRow + colIndex
                                    let isCompleted = index < completedSessions
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(.systemGray6))
                                            .frame(width: 40, height: 40)
                                        
                                        if isCompleted {
                                            Text("🍅") // 番茄图标
                                                .font(.title)
                                        } else {
                                            Text("🍅")
                                                .font(.title)
                                                .foregroundColor(Color(.systemGray4))
                                                .opacity(0.3)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: 160)

                // 设置按钮
                NavigationLink(destination: FocusSettingsView()) {
                    HStack {
                        Image(systemName: "gear")
                        Text(NSLocalizedString("专注设置", comment: "Focus Settings button"))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(appSettings.accentColor.color)
                    .cornerRadius(10)
                    .shadow(color: appSettings.accentColor.color.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .padding(.bottom)
            }
            .padding(.vertical)
            .navigationTitle(NSLocalizedString("专注", comment: "Focus view navigation title"))
            .navigationBarTitleDisplayMode(.inline)

            .alert(NSLocalizedString("终止专注", comment: "Stop focus alert title"), isPresented: $showStopConfirmation) {
                Button(NSLocalizedString("取消", comment: "Cancel button"), role: .cancel) { }
                Button(NSLocalizedString("终止", comment: "Stop button"), role: .destructive) {
                    focusTimer.stopTimer()
                }
            } message: {
                let messageKey = focusTimer.currentState == .focusing ? 
                    "提前终止专注将不会计入统计。确定要终止当前专注吗？" : 
                    "确定要终止当前休息吗？"
                Text(NSLocalizedString(messageKey, comment: "Stop focus confirmation message"))
            }
        }
    }
}

struct FocusSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode
    
    @State private var focusDuration: Double
    @State private var shortBreakDuration: Double
    @State private var longBreakDuration: Double
    @State private var pomoBeforeBreak: Int
    @State private var enableSound: Bool
    @State private var enableNotification: Bool
    @State private var dailyFocusSessionsTarget: Int
    
    private let focusTimer = FocusTimerManager.shared
    
    // 使用 onAppear 来加载设置，而不是在初始化时加载
    init() {
        // 初始化时设置默认值，稍后在 onAppear 中更新
        _focusDuration = State(initialValue: 25)
        _shortBreakDuration = State(initialValue: 5)
        _longBreakDuration = State(initialValue: 15)
        _pomoBeforeBreak = State(initialValue: 4)
        _enableSound = State(initialValue: true)
        _enableNotification = State(initialValue: true)
        _dailyFocusSessionsTarget = State(initialValue: 10)
    }
    
    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("时间设置（分钟）", comment: "Time settings header (minutes)"))) {
                VStack {
                    HStack {
                        Text(NSLocalizedString("专注时长", comment: "Focus duration setting"))
                        Spacer()
                        Text(String.localizedStringWithFormat(NSLocalizedString("%d分钟", comment: "Duration in minutes format"), Int(focusDuration)))
                    }
                    Slider(value: $focusDuration, in: 1...60, step: 1)
                }
                
                VStack {
                    HStack {
                        Text(NSLocalizedString("短休息时长", comment: "Short break duration setting"))
                        Spacer()
                        Text(String.localizedStringWithFormat(NSLocalizedString("%d分钟", comment: "Duration in minutes format"), Int(shortBreakDuration)))
                    }
                    Slider(value: $shortBreakDuration, in: 1...30, step: 1)
                }
                
                VStack {
                    HStack {
                        Text(NSLocalizedString("长休息时长", comment: "Long break duration setting"))
                        Spacer()
                        Text(String.localizedStringWithFormat(NSLocalizedString("%d分钟", comment: "Duration in minutes format"), Int(longBreakDuration)))
                    }
                    Slider(value: $longBreakDuration, in: 1...45, step: 1)
                }
                
                Stepper(String.localizedStringWithFormat(NSLocalizedString("长休息前专注次数: %d", comment: "Pomodoros before long break stepper"), pomoBeforeBreak), value: $pomoBeforeBreak, in: 1...10)
            }
            
            Section(header: Text(NSLocalizedString("今日目标", comment: "Daily target header"))) {
                Stepper(String.localizedStringWithFormat(NSLocalizedString("每日专注次数目标: %d", comment: "Daily focus sessions target stepper"), dailyFocusSessionsTarget), value: $dailyFocusSessionsTarget, in: 1...30)
                
                VStack {
                    HStack {
                        Text(NSLocalizedString("每日专注时间目标", comment: "Daily focus time target setting"))
                        Spacer()
                        Text(String.localizedStringWithFormat(NSLocalizedString("%d分钟", comment: "Duration in minutes format"), Int(focusDuration * Double(dailyFocusSessionsTarget))))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text(NSLocalizedString("通知与声音", comment: "Notifications and sound header"))) {
                Toggle(NSLocalizedString("启用音效", comment: "Enable sound effects toggle"), isOn: $enableSound)
                Toggle(NSLocalizedString("启用通知", comment: "Enable notifications toggle"), isOn: $enableNotification)
            }
            
            Section {
                Button(NSLocalizedString("保存设置", comment: "Save settings button")) {
                    saveSettings()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle(NSLocalizedString("专注设置", comment: "Focus Settings navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 在视图出现时加载当前设置
            focusDuration = appSettings.focusSettings.focusDuration
            shortBreakDuration = appSettings.focusSettings.shortBreakDuration
            longBreakDuration = appSettings.focusSettings.longBreakDuration
            pomoBeforeBreak = appSettings.focusSettings.pomoBeforeBreak
            enableSound = appSettings.focusSettings.enableSound
            enableNotification = appSettings.focusSettings.enableNotification
            dailyFocusSessionsTarget = appSettings.focusSettings.dailyFocusSessionsTarget
        }
    }
    
    private func saveSettings() {
        // 计算每日专注时间目标 = 专注时长 × 每日专注次数目标
        let calculatedDailyFocusTimeTarget = Int(focusDuration * Double(dailyFocusSessionsTarget))
        
        let newSettings = FocusSettings(
            focusDuration: focusDuration,
            shortBreakDuration: shortBreakDuration,
            longBreakDuration: longBreakDuration,
            pomoBeforeBreak: pomoBeforeBreak,
            enableSound: enableSound,
            enableNotification: enableNotification,
            dailyFocusSessionsTarget: dailyFocusSessionsTarget,
            dailyFocusTimeTarget: calculatedDailyFocusTimeTarget
        )
        appSettings.focusSettings = newSettings
        focusTimer.updateSettings(from: newSettings)
    }
} 