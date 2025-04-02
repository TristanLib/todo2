import SwiftUI

struct FocusView: View {
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject private var focusTimer = FocusTimerManager.shared
    @State private var showStopConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 标题和状态
                VStack(spacing: 10) {
                    Text(focusTimer.currentStateDisplayName())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .animation(.none)
                    
                    Text("已完成 \(focusTimer.completedFocusSessions) 个专注")
                        .foregroundColor(.secondary)
                }
                
                // 计时器显示
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 20)
                        .frame(width: 280, height: 280)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(focusTimer.progress))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.25), value: focusTimer.progress)
                    
                    Text(focusTimer.formattedTimeRemaining())
                        .font(.system(size: 70, weight: .medium, design: .rounded))
                }
                
                // 控制按钮
                HStack(spacing: 40) {
                    Button(action: {
                        // 重置会话按钮
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
                
                Spacer()
                
                // ---- START: Added Completed Sessions Display ----
                Divider()
                    .padding(.vertical)
                
                VStack(alignment: .leading) {
                    Text("已完成的专注：")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if focusTimer.completedFocusSessions > 0 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 2) {
                                ForEach(0..<focusTimer.completedFocusSessions, id: \.self) { _ in
                                    Text("🌸")
                                        .font(.title)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        .frame(height: 50) // Limit height to prevent large vertical space
                    } else {
                        Text("今天还没有完成专注。")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 5)
                    }
                }
                .padding(.horizontal)
                // ---- END: Added Completed Sessions Display ----

                // 设置按钮
                NavigationLink(destination: FocusSettingsView()) {
                    HStack {
                        Image(systemName: "gear")
                        Text("专注设置")
                    }
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("专注")
            .navigationBarTitleDisplayMode(.inline)
            .alert("终止专注", isPresented: $showStopConfirmation) {
                Button("取消", role: .cancel) { }
                Button("终止", role: .destructive) {
                    focusTimer.stopTimer()
                }
            } message: {
                let message = focusTimer.currentState == .focusing ? 
                    "提前终止专注将不会计入统计。确定要终止当前专注吗？" : 
                    "确定要终止当前休息吗？"
                Text(message)
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
    
    private let focusTimer = FocusTimerManager.shared
    
    init() {
        let settings = AppSettings().focusSettings
        _focusDuration = State(initialValue: settings.focusDuration)
        _shortBreakDuration = State(initialValue: settings.shortBreakDuration)
        _longBreakDuration = State(initialValue: settings.longBreakDuration)
        _pomoBeforeBreak = State(initialValue: settings.pomoBeforeBreak)
        _enableSound = State(initialValue: settings.enableSound)
        _enableNotification = State(initialValue: settings.enableNotification)
    }
    
    var body: some View {
        Form {
            Section(header: Text("时间设置（分钟）")) {
                VStack {
                    HStack {
                        Text("专注时长")
                        Spacer()
                        Text("\(Int(focusDuration))分钟")
                    }
                    Slider(value: $focusDuration, in: 1...60, step: 1)
                }
                
                VStack {
                    HStack {
                        Text("短休息时长")
                        Spacer()
                        Text("\(Int(shortBreakDuration))分钟")
                    }
                    Slider(value: $shortBreakDuration, in: 1...30, step: 1)
                }
                
                VStack {
                    HStack {
                        Text("长休息时长")
                        Spacer()
                        Text("\(Int(longBreakDuration))分钟")
                    }
                    Slider(value: $longBreakDuration, in: 1...45, step: 1)
                }
                
                Stepper("长休息前专注次数: \(pomoBeforeBreak)", value: $pomoBeforeBreak, in: 1...10)
            }
            
            Section(header: Text("通知与声音")) {
                Toggle("启用音效", isOn: $enableSound)
                Toggle("启用通知", isOn: $enableNotification)
            }
            
            Section {
                Button("保存设置") {
                    saveSettings()
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("专注设置")
        .onAppear {
            DispatchQueue.main.async {
                // 初始化设置
                let settings = appSettings.focusSettings
                focusDuration = settings.focusDuration
                shortBreakDuration = settings.shortBreakDuration
                longBreakDuration = settings.longBreakDuration
                pomoBeforeBreak = settings.pomoBeforeBreak
                enableSound = settings.enableSound
                enableNotification = settings.enableNotification
            }
        }
    }
    
    private func saveSettings() {
        var updatedSettings = appSettings.focusSettings
        updatedSettings.focusDuration = focusDuration
        updatedSettings.shortBreakDuration = shortBreakDuration
        updatedSettings.longBreakDuration = longBreakDuration
        updatedSettings.pomoBeforeBreak = pomoBeforeBreak
        updatedSettings.enableSound = enableSound
        updatedSettings.enableNotification = enableNotification
        
        appSettings.focusSettings = updatedSettings
        focusTimer.updateSettings(from: updatedSettings)
    }
} 