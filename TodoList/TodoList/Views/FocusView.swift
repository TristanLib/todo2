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
    @ObservedObject private var soundManager = SoundManager.shared
    
    @State private var focusDuration: Double
    @State private var shortBreakDuration: Double
    @State private var longBreakDuration: Double
    @State private var pomoBeforeBreak: Int
    @State private var enableSound: Bool
    @State private var enableNotification: Bool
    @State private var dailyFocusSessionsTarget: Int
    @State private var whiteNoiseType: WhiteNoiseType = .none
    @State private var whiteNoiseVolume: Float = 0.5
    @State private var showWhiteNoiseSelector = false
    
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
                    .onChange(of: enableSound) { newValue in
                        soundManager.setEnabled(newValue)
                    }
                Toggle(NSLocalizedString("启用通知", comment: "Enable notifications toggle"), isOn: $enableNotification)
                
                // 白噪音选择器
                if enableSound {
                    NavigationLink(destination: WhiteNoiseSelectionView(selectedNoise: $whiteNoiseType, volume: $whiteNoiseVolume)) {
                        HStack {
                            Text(NSLocalizedString("白噪音", comment: "White noise setting"))
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: whiteNoiseType.iconName)
                                    .foregroundColor(.blue)
                                Text(whiteNoiseType.displayName)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onChange(of: whiteNoiseType) { newValue in
                        // 当白噪音类型变化时更新UI
                        print("白噪音类型变化为: \(newValue.displayName)")
                    }
                    
                    if whiteNoiseType != .none {
                        VStack {
                            HStack {
                                Text(NSLocalizedString("音量", comment: "Volume setting"))
                                Spacer()
                                Text("\(Int(whiteNoiseVolume * 100))%")
                            }
                            Slider(value: $whiteNoiseVolume, in: 0...1, step: 0.05)
                                .onChange(of: whiteNoiseVolume) { newValue in
                                    soundManager.setWhiteNoiseVolume(newValue)
                                }
                        }
                    }
                }
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
            
            // 首先从SoundManager加载白噪音设置，因为它可能包含最新的选择
            if soundManager.currentWhiteNoise != .none {
                whiteNoiseType = soundManager.currentWhiteNoise
                whiteNoiseVolume = soundManager.whiteNoiseVolume
                print("从SoundManager加载白噪音设置: \(soundManager.currentWhiteNoise.displayName)")
                
                // 同步更新AppSettings中的设置
                var focusSettings = appSettings.focusSettings
                focusSettings.whiteNoiseType = soundManager.currentWhiteNoise.rawValue
                focusSettings.whiteNoiseVolume = soundManager.whiteNoiseVolume
                appSettings.focusSettings = focusSettings
            } 
            // 如果从SoundManager加载失败，则从AppSettings加载
            else if let noiseType = WhiteNoiseType(rawValue: appSettings.focusSettings.whiteNoiseType), noiseType != .none {
                whiteNoiseType = noiseType
                whiteNoiseVolume = appSettings.focusSettings.whiteNoiseVolume
                print("从AppSettings加载白噪音设置: \(noiseType.displayName)")
            } else {
                // 如果两者都加载失败，使用默认值
                whiteNoiseType = .none
                whiteNoiseVolume = 0.5
                print("使用默认白噪音设置: 无白噪音")
            }
        }
    }
    
    private func saveSettings() {
        // 计算每日专注时间目标 = 专注时长 × 每日专注次数目标
        let calculatedDailyFocusTimeTarget = Int(focusDuration * Double(dailyFocusSessionsTarget))
        
        var newSettings = FocusSettings(
            focusDuration: focusDuration,
            shortBreakDuration: shortBreakDuration,
            longBreakDuration: longBreakDuration,
            pomoBeforeBreak: pomoBeforeBreak,
            enableSound: enableSound,
            enableNotification: enableNotification,
            dailyFocusSessionsTarget: dailyFocusSessionsTarget,
            dailyFocusTimeTarget: calculatedDailyFocusTimeTarget
        )
        
        // 保存白噪音设置
        newSettings.whiteNoiseType = whiteNoiseType.rawValue
        newSettings.whiteNoiseVolume = whiteNoiseVolume
        
        appSettings.focusSettings = newSettings
        focusTimer.updateSettings(from: newSettings)
        
        // 如果启用了音效且选择了白噪音，播放白噪音
        if enableSound && whiteNoiseType != .none {
            soundManager.playWhiteNoise(whiteNoiseType)
        } else if !enableSound || whiteNoiseType == .none {
            soundManager.stopWhiteNoise()
        }
    }
}

// 白噪音选择视图
struct WhiteNoiseSelectionView: View {
    @Binding var selectedNoise: WhiteNoiseType
    @Binding var volume: Float
    @ObservedObject private var soundManager = SoundManager.shared
    
    // 预览时使用的临时选择
    @State private var previewNoise: WhiteNoiseType = .none
    @State private var isPreviewPlaying = false
    
    var body: some View {
        List {
            Section(header: Text(NSLocalizedString("选择白噪音", comment: "Select white noise header"))) {
                ForEach(WhiteNoiseType.allCases) { noiseType in
                    Button(action: {
                        // 如果选择了当前正在播放的预览噪音，则停止预览
                        if isPreviewPlaying && previewNoise == noiseType {
                            soundManager.stopWhiteNoise()
                            isPreviewPlaying = false
                            previewNoise = .none
                        } else {
                            // 否则开始预览新选择的噪音
                            previewNoise = noiseType
                            soundManager.playWhiteNoise(noiseType)
                            isPreviewPlaying = true
                        }
                    }) {
                        HStack {
                            Image(systemName: noiseType.iconName)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            Text(noiseType.displayName)
                            
                            Spacer()
                            
                            if selectedNoise == noiseType {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                            
                            if isPreviewPlaying && previewNoise == noiseType {
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            if isPreviewPlaying && previewNoise != .none {
                Section(header: Text(NSLocalizedString("预览音量", comment: "Preview volume header"))) {
                    VStack {
                        HStack {
                            Image(systemName: "speaker.wave.1.fill")
                            Slider(value: $volume, in: 0...1, step: 0.05)
                                .onChange(of: volume) { newValue in
                                    soundManager.setWhiteNoiseVolume(newValue)
                                }
                            Image(systemName: "speaker.wave.3.fill")
                        }
                        Text("\(Int(volume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(action: {
                    // 停止预览
                    if isPreviewPlaying {
                        soundManager.stopWhiteNoise()
                        isPreviewPlaying = false
                    }
                    
                    // 设置选择的噪音
                    selectedNoise = previewNoise
                    
                    // 确保当前选择的白噪音被保存到SoundManager
                    if previewNoise != .none {
                        soundManager.currentWhiteNoise = previewNoise
                        UserDefaults.standard.set(previewNoise.rawValue, forKey: "currentWhiteNoise")
                        
                        // 同时也更新AppSettings中的设置
                        let appSettings = AppSettings()
                        var focusSettings = appSettings.focusSettings
                        focusSettings.whiteNoiseType = previewNoise.rawValue
                        focusSettings.whiteNoiseVolume = volume
                        appSettings.focusSettings = focusSettings
                        
                        print("已将白噪音设置保存到AppSettings: \(previewNoise.displayName)")
                    }
                    
                    // 返回上一个页面
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.dismiss(animated: true, completion: nil)
                    }
                }) {
                    Text(NSLocalizedString("确认选择", comment: "Confirm selection button"))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .navigationTitle(NSLocalizedString("白噪音", comment: "White noise navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 预览默认选择当前的噪音
            previewNoise = selectedNoise
            if selectedNoise != .none {
                soundManager.playWhiteNoise(selectedNoise)
                isPreviewPlaying = true
            }
        }
        .onDisappear {
            // 离开页面时停止预览
            if isPreviewPlaying {
                soundManager.stopWhiteNoise()
                isPreviewPlaying = false
            }
            
            // 如果有选择噪音，则重新播放原来的噪音
            if selectedNoise != .none {
                soundManager.playWhiteNoise(selectedNoise)
            }
        }
    }
}