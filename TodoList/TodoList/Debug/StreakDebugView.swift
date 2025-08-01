#if DEBUG
import SwiftUI

struct StreakDebugView: View {
    @StateObject private var streakManager = StreakManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("当前状态") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("连续天数: \(streakManager.streakData.currentStreak)")
                        Text("最长记录: \(streakManager.streakData.longestStreak)")
                        Text("总活跃天数: \(streakManager.streakData.totalActiveDays)")
                        Text("今日已标记: \(streakManager.todayMarkedActive ? "是" : "否")")
                        Text("当前状态: \(streakManager.getCurrentStatus().localizedDescription)")
                        
                        if let nextMilestone = streakManager.getNextMilestone() {
                            Text("下一里程碑: \(nextMilestone.localizedTitle) (\(nextMilestone.days)天)")
                        } else {
                            Text("下一里程碑: 已达到最高级别")
                        }
                    }
                    .font(.system(.body, design: .monospaced))
                }
                
                Section("测试操作") {
                    Button("标记今日活跃") {
                        streakManager.markTodayAsActive()
                        showAlert("已标记今日活跃")
                    }
                    
                    Button("查看详细状态") {
                        let statusInfo = streakManager.getStatusInfo()
                        showAlert(statusInfo)
                    }
                    
                    Button("模拟专注完成") {
                        // 模拟FocusTimerManager的调用
                        streakManager.markTodayAsActive()
                        showAlert("模拟专注完成，已标记活跃")
                    }
                    
                    Button("模拟任务完成") {
                        // 模拟TaskStore的调用
                        streakManager.markTodayAsActive()
                        showAlert("模拟任务完成，已标记活跃")
                    }
                }
                
                Section("数据管理") {
                    Button("重置所有数据", role: .destructive) {
                        UserDefaults.standard.removeObject(forKey: "streakData_v1")
                        // 重新初始化StreakManager（这里简化处理）
                        showAlert("数据已重置，请重启应用查看效果")
                    }
                    
                    Button("模拟昨天活跃") {
                        simulateYesterdayActive()
                        showAlert("模拟昨天活跃，连续天数应该会增加")
                    }
                }
                
                Section("里程碑进度") {
                    ForEach(getAllMilestones(), id: \.days) { milestone in
                        HStack {
                            Image(systemName: milestone.days <= streakManager.streakData.currentStreak ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(milestone.days <= streakManager.streakData.currentStreak ? .green : .secondary)
                            
                            VStack(alignment: .leading) {
                                Text(milestone.localizedTitle)
                                    .font(.headline)
                                Text("\(milestone.days)天 - \(milestone.rewardPoints)积分")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Streak调试")
            .alert("调试信息", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
        print("🔍 StreakDebugView: \(message)")
    }
    
    private func simulateYesterdayActive() {
        // 手动设置昨天的活跃记录来测试连续逻辑
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayStart = Calendar.current.startOfDay(for: yesterday)
        
        // 临时修改数据进行测试
        var testData = streakManager.streakData
        testData.lastActiveDate = yesterdayStart
        testData.currentStreak = max(1, testData.currentStreak) // 确保至少有1天
        
        // 保存测试数据
        if let encoded = try? JSONEncoder().encode(testData) {
            UserDefaults.standard.set(encoded, forKey: "streakData_v1")
        }
        
        // 现在标记今日活跃，应该会连续+1
        streakManager.markTodayAsActive()
    }
    
    private func getAllMilestones() -> [StreakMilestone] {
        return [
            StreakMilestone(days: 3, title: "新的开始", description: "连续使用3天", rewardPoints: 100),
            StreakMilestone(days: 7, title: "小有成就", description: "连续使用7天", rewardPoints: 200),
            StreakMilestone(days: 30, title: "习惯初成", description: "连续使用30天", rewardPoints: 500),
            StreakMilestone(days: 100, title: "终身习惯", description: "连续使用100天", rewardPoints: 1000)
        ]
    }
}

struct StreakDebugView_Previews: PreviewProvider {
    static var previews: some View {
        StreakDebugView()
    }
}
#endif