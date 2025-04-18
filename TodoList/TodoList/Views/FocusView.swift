import SwiftUI

struct FocusView: View {
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject private var focusTimer = FocusTimerManager.shared
    @State private var showStopConfirmation = false
    @State private var viewAppeared = false

    var body: some View {
        NavigationView {
            // 使用onAppear和onDisappear来跟踪视图的生命周期
            // 这有助于解决从设置页面返回时按钮状态不同步的问题
            VStack(spacing: 20) {
                // 标题和目标信息
                VStack(spacing: 8) {
                    Text(focusTimer.currentStateDisplayName())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .animation(.none)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    // 目标和已完成信息
                    VStack(spacing: 8) {
                        // 番茄目标和已完成
                        HStack(spacing: 4) {
                            Text(String.localizedStringWithFormat(
                                NSLocalizedString("目标: %d", comment: "Target: X"),
                                appSettings.focusSettings.dailyFocusSessionsTarget
                            ))
                            
                            // 番茄图标
                            Image("TomatoCompleted")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .shadow(color: Color.orange.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            Text(String.localizedStringWithFormat(
                                NSLocalizedString("(已完成: %d)", comment: "(Done: X)"),
                                focusTimer.todayCompletedFocusSessions
                            ))
                        }
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)

                        // 目标时间和已累计时间
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("目标时间: %d分钟 (已累计: %@)", comment: "Target time: X min (Accumulated: Y)"),
                            appSettings.focusSettings.dailyFocusTimeTarget,
                            focusTimer.formattedTodayTotalFocusTime()
                        ))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.top)

                // 计时器显示 - 使用 GeometryReader 使其自适应
                GeometryReader { geometry in
                    let timerSize = min(geometry.size.width * 0.8, geometry.size.height * 0.6)
                    let lineWidth: CGFloat = max(timerSize * 0.05, 12)

                    ZStack {
                        // 背景圆环
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: lineWidth)

                        // 进度圆环 - 使用橙色渐变
                        Circle()
                            .trim(from: 0, to: CGFloat(focusTimer.progress))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.25), value: focusTimer.progress)

                        // 时间显示
                        Text(focusTimer.formattedTimeRemaining())
                            .font(.system(size: timerSize * 0.25, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    .frame(width: timerSize, height: timerSize)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .frame(maxHeight: 350)

                // 控制按钮
                HStack(spacing: 40) {
                    // 重置按钮
                    Button(action: {
                        focusTimer.resetSessions()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 50, height: 50)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .disabled(focusTimer.completedFocusSessions == 0)
                    .opacity(focusTimer.completedFocusSessions == 0 ? 0.5 : 1)

                    // 开始/暂停按钮
                    if focusTimer.currentState == .idle || focusTimer.currentState == .paused {
                        Button(action: {
                            focusTimer.startTimer()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                    } else {
                        Button(action: {
                            focusTimer.pauseTimer()
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                    }

                    // 跳过/停止按钮
                    Button(action: {
                        if focusTimer.currentState != .idle {
                            showStopConfirmation = true
                        }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 50, height: 50)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .disabled(focusTimer.currentState == .idle)
                    .opacity(focusTimer.currentState == .idle ? 0.5 : 1)
                }
                .padding(.horizontal)

                // 今日进度
                VStack(alignment: .center, spacing: 12) {
                    Text(NSLocalizedString("今日进度", comment: "Today's progress"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    // 使用番茄图标来可视化进度
                    let targetSessions = appSettings.focusSettings.dailyFocusSessionsTarget
                    let completedSessions = focusTimer.todayCompletedFocusSessions

                    // 计算每行显示的番茄数量
                    let itemsPerRow = min(6, targetSessions) // 每行最多显示6个
                    let rowCount = (targetSessions + itemsPerRow - 1) / itemsPerRow // 向上取整

                    VStack(spacing: 12) {
                        ForEach(0..<rowCount, id: \.self) { rowIndex in
                            HStack(spacing: 12) {
                                ForEach(0..<min(itemsPerRow, targetSessions - rowIndex * itemsPerRow), id: \.self) { colIndex in
                                    let index = rowIndex * itemsPerRow + colIndex
                                    let isCompleted = index < completedSessions

                                    if isCompleted {
                                        // 已完成的番茄
                                        Image("TomatoCompleted")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                            .shadow(color: Color.orange.opacity(0.3), radius: 2, x: 0, y: 1)
                                    } else {
                                        // 未完成的番茄
                                        Image("TomatoUncompleted")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: 160)

                Spacer()
            }
            .padding(.vertical)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FocusSettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                // 视图出现时，强制刷新状态
                viewAppeared = true
                // 确保UI状态与计时器状态同步
                DispatchQueue.main.async {
                    focusTimer.objectWillChange.send()
                }
            }
            .onDisappear {
                viewAppeared = false
            }

            .alert(NSLocalizedString("跳过当前阶段", comment: "Skip current phase"), isPresented: $showStopConfirmation) {
                Button(NSLocalizedString("取消", comment: "Cancel button"), role: .cancel) { }
                Button(NSLocalizedString("跳过", comment: "Skip button"), role: .destructive) {
                    focusTimer.stopTimer()
                }
            } message: {
                let messageKey = focusTimer.currentState == .focusing ?
                    "提前结束专注将不会计入统计。确定要跳过当前专注吗？" :
                    "确定要跳过当前休息吗？"
                Text(NSLocalizedString(messageKey, comment: "Skip confirmation message"))
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
                        .onChange(of: focusDuration) { _ in
                            saveSettings()
                        }
                }

                VStack {
                    HStack {
                        Text(NSLocalizedString("短休息时长", comment: "Short break duration setting"))
                        Spacer()
                        Text(String.localizedStringWithFormat(NSLocalizedString("%d分钟", comment: "Duration in minutes format"), Int(shortBreakDuration)))
                    }
                    Slider(value: $shortBreakDuration, in: 1...30, step: 1)
                        .onChange(of: shortBreakDuration) { _ in
                            saveSettings()
                        }
                }

                VStack {
                    HStack {
                        Text(NSLocalizedString("长休息时长", comment: "Long break duration setting"))
                        Spacer()
                        Text(String.localizedStringWithFormat(NSLocalizedString("%d分钟", comment: "Duration in minutes format"), Int(longBreakDuration)))
                    }
                    Slider(value: $longBreakDuration, in: 1...45, step: 1)
                        .onChange(of: longBreakDuration) { _ in
                            saveSettings()
                        }
                }

                Stepper(String.localizedStringWithFormat(NSLocalizedString("长休息前专注次数: %d", comment: "Pomodoros before long break stepper"), pomoBeforeBreak), value: $pomoBeforeBreak, in: 1...10)
                    .onChange(of: pomoBeforeBreak) { _ in
                        saveSettings()
                    }
            }

            Section(header: Text(NSLocalizedString("今日目标", comment: "Daily target header"))) {
                Stepper(String.localizedStringWithFormat(NSLocalizedString("每日专注次数目标: %d", comment: "Daily focus sessions target stepper"), dailyFocusSessionsTarget), value: $dailyFocusSessionsTarget, in: 1...30)
                    .onChange(of: dailyFocusSessionsTarget) { _ in
                        saveSettings()
                    }

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
                        saveSettings()
                    }
                Toggle(NSLocalizedString("启用通知", comment: "Enable notifications toggle"), isOn: $enableNotification)
                    .onChange(of: enableNotification) { _ in
                        saveSettings()
                    }

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
                        saveSettings()
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
                                    saveSettings()
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("专注设置", comment: "Focus Settings navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("完成", comment: "Done button")) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
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

        // 保存白噪音设置到SoundManager
        if enableSound && whiteNoiseType != .none {
            // 只更新设置，不播放白噪音
            soundManager.currentWhiteNoise = whiteNoiseType
            soundManager.setWhiteNoiseVolume(whiteNoiseVolume)
            UserDefaults.standard.set(whiteNoiseType.rawValue, forKey: "currentWhiteNoise")

            // 只有在专注状态下才播放白噪音
            if focusTimer.currentState == .focusing {
                soundManager.playWhiteNoise(whiteNoiseType)
                print("保存设置并在专注状态下播放白噪音: \(whiteNoiseType.displayName)")
            }
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

            // 使用工具栏代替确认按钮
        }
        .navigationTitle(NSLocalizedString("白噪音", comment: "White noise navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("确认", comment: "Confirm button")) {
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
                }
            }
        }
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

            // 只有在专注状态下才重新播放白噪音
            let focusTimer = FocusTimerManager.shared
            if selectedNoise != .none && focusTimer.currentState == .focusing {
                soundManager.playWhiteNoise(selectedNoise)
                print("离开白噪音选择页面，恢复专注状态下的白噪音播放")
            }
        }
    }
}