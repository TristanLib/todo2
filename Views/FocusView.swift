import SwiftUI

struct FocusView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject private var timerManager = FocusTimerManager.shared
    
    @State private var selectedTask: Task?
    @State private var showingTaskSelection = false
    @State private var showingSettings = false
    @State private var animateProgress = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景颜色
                backgroundForCurrentState()
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // 计时器显示
                    ZStack {
                        // 灰色背景圆圈
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 20)
                            .frame(width: 280, height: 280)
                        
                        // 进度圆圈
                        Circle()
                            .trim(from: 0, to: animateProgress ? CGFloat(timerManager.progress) : 0)
                            .stroke(progressColor(), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.6), value: timerManager.progress)
                            .onAppear {
                                animateProgress = true
                            }
                        
                        VStack(spacing: 10) {
                            // 状态显示
                            Text(timerManager.currentStateDisplayName())
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 5)
                            
                            // 剩余时间
                            Text(timerManager.formattedTimeRemaining())
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            // 已完成会话
                            if timerManager.completedFocusSessions > 0 {
                                HStack {
                                    ForEach(0..<min(timerManager.completedFocusSessions, 8), id: \.self) { _ in
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(appSettings.accentColor.color)
                                    }
                                    
                                    if timerManager.completedFocusSessions > 8 {
                                        Text("+\(timerManager.completedFocusSessions - 8)")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .padding(.top, 5)
                            }
                            
                            // 当前任务
                            if let task = selectedTask {
                                Text(task.title)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                            } else {
                                Button(action: {
                                    showingTaskSelection = true
                                }) {
                                    Text("选择一个任务")
                                        .font(.headline)
                                        .foregroundColor(appSettings.accentColor.color)
                                        .padding(.top, 10)
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.top, 20)
                    
                    // 控制按钮
                    HStack(spacing: 30) {
                        // 重置按钮
                        Button(action: {
                            withAnimation {
                                timerManager.stopTimer()
                                if appSettings.enableAnimations {
                                    animateProgress = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        animateProgress = true
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title)
                                .foregroundColor(appSettings.accentColor.color)
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        
                        // 开始/暂停按钮
                        Button(action: {
                            withAnimation {
                                if timerManager.currentState == .idle || timerManager.currentState == .paused {
                                    timerManager.startTimer()
                                } else {
                                    timerManager.pauseTimer()
                                }
                            }
                        }) {
                            Image(systemName: (timerManager.currentState == .idle || timerManager.currentState == .paused) ? "play.fill" : "pause.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(appSettings.accentColor.color)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        
                        // 跳过按钮
                        Button(action: {
                            switch timerManager.currentState {
                            case .focusing:
                                timerManager.handleFocusCompletion()
                            case .shortBreak, .longBreak:
                                timerManager.handleBreakCompletion()
                            default:
                                break
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.title)
                                .foregroundColor(appSettings.accentColor.color)
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // 当前状态指示器
                    HStack(spacing: 20) {
                        stateIndicator(for: .focusing, text: "专注")
                        stateIndicator(for: .shortBreak, text: "短休息")
                        stateIndicator(for: .longBreak, text: "长休息")
                    }
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("专注")
            .navigationBarItems(
                leading: Button(action: {
                    selectedTask = nil
                    showingTaskSelection = true
                }) {
                    Label("选择任务", systemImage: "list.bullet")
                },
                trailing: Button(action: {
                    showingSettings = true
                }) {
                    Label("设置", systemImage: "gear")
                }
            )
            .onAppear {
                timerManager.updateSettings(from: appSettings.focusSettings)
            }
            .sheet(isPresented: $showingTaskSelection) {
                taskSelectionView()
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    FocusSettingsView()
                        .navigationTitle("专注设置")
                        .navigationBarItems(trailing: Button("完成") {
                            showingSettings = false
                        })
                }
            }
        }
    }
    
    // 任务选择视图
    private func taskSelectionView() -> some View {
        NavigationView {
            List {
                Section(header: Text("选择一个任务进行专注")) {
                    ForEach(taskStore.getIncompleteTasks()) { task in
                        Button(action: {
                            selectedTask = task
                            showingTaskSelection = false
                        }) {
                            HStack {
                                Text(task.title)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedTask?.id == task.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(appSettings.accentColor.color)
                                }
                            }
                        }
                    }
                }
                
                if taskStore.getIncompleteTasks().isEmpty {
                    Section {
                        Text("没有未完成的任务")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                
                Section {
                    Button(action: {
                        selectedTask = nil
                        showingTaskSelection = false
                    }) {
                        Text("不选择任务")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("选择任务")
            .navigationBarItems(trailing: Button("取消") {
                showingTaskSelection = false
            })
        }
    }
    
    // 根据当前状态返回背景颜色
    private func backgroundForCurrentState() -> some View {
        switch timerManager.currentState {
        case .focusing:
            return Color(.systemBackground)
        case .shortBreak, .longBreak:
            return Color(.systemBackground).opacity(0.95)
        default:
            return Color(.systemBackground)
        }
    }
    
    // 根据当前状态返回进度颜色
    private func progressColor() -> Color {
        switch timerManager.currentState {
        case .focusing:
            return appSettings.accentColor.color
        case .shortBreak:
            return Color.green
        case .longBreak:
            return Color.blue
        case .paused:
            return Color.orange
        default:
            return appSettings.accentColor.color
        }
    }
    
    // 状态指示器
    private func stateIndicator(for state: FocusTimerState, text: String) -> some View {
        VStack {
            Circle()
                .fill(timerManager.currentState == state ? progressColor() : Color(.systemGray5))
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(.caption)
                .foregroundColor(timerManager.currentState == state ? .primary : .secondary)
        }
    }
}

// FocusTimerManager 扩展，添加方便的方法
extension FocusTimerManager {
    func handleFocusCompletion() {
        // 停止当前计时器
        stopTimer()
        
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
    }
    
    func handleBreakCompletion() {
        // 播放休息结束声音
        soundManager.playSound(.endBreak)
        
        // 发送通知
        notificationManager.scheduleNotification(for: .breakEnd)
        
        // 休息结束后回到空闲状态
        stopTimer()
    }
}

struct FocusView_Previews: PreviewProvider {
    static var previews: some View {
        FocusView()
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
    }
} 