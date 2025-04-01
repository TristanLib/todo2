import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @Binding var selectedTab: Int
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: TaskCategory? = nil
    @State private var selectedPriority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = defaultDueDate()
    @State private var subtasks: [String] = [""]
    
    // 设置默认截止日期为当天晚上10点
    private static func defaultDueDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 获取当天日期的年、月、日部分
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        
        // 创建一个新的日期组件，设置时间为22:00:00
        var targetComponents = DateComponents()
        targetComponents.year = components.year
        targetComponents.month = components.month
        targetComponents.day = components.day
        targetComponents.hour = 22
        targetComponents.minute = 0
        targetComponents.second = 0
        
        // 将组件转换为日期
        return calendar.date(from: targetComponents) ?? now
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("新建任务")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: saveTask) {
                    Text("保存")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                        )
                }
                .disabled(title.isEmpty)
                .opacity(title.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            ScrollView {
                VStack(spacing: 20) {
                    // 任务标题
                    VStack(alignment: .leading, spacing: 6) {
                        Text("任务名称")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("项目会议准备", text: $title)
                            .font(.system(size: 16))
                            .padding(.vertical, 10)
                            .background(
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 40)
                            )
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(.systemGray4))
                                    .offset(y: 20),
                                alignment: .bottom
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 任务详情
                    VStack(alignment: .leading, spacing: 6) {
                        Text("任务详情（可选）")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("准备明天的项目演示幻灯片，整理演示流程")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(.systemGray))
                                    .padding(.top, 8)
                            }
                            
                            TextEditor(text: $description)
                                .font(.system(size: 16))
                                .frame(minHeight: 80)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                        }
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(.systemGray4)),
                            alignment: .bottom
                        )
                    }
                    .padding(.horizontal)
                    
                    // 日期和时间
                    HStack {
                        Text("日期")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        DatePicker("", selection: $dueDate, displayedComponents: [.date])
                            .labelsHidden()
                            .onChange(of: dueDate) { _, _ in
                                hasDueDate = true
                            }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    
                    HStack {
                        Text("时间")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .onChange(of: dueDate) { _, _ in
                                hasDueDate = true
                            }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    
                    // 优先级
                    VStack(alignment: .leading, spacing: 10) {
                        Text("优先级")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            // 低优先级按钮
                            Button(action: {
                                selectedPriority = .low
                            }) {
                                VStack {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                    Text("低")
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedPriority == .low ? Color.green : Color(.systemGray4), lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedPriority == .low ? Color.green.opacity(0.1) : Color.clear)
                                        )
                                )
                            }
                            
                            // 中优先级按钮
                            Button(action: {
                                selectedPriority = .medium
                            }) {
                                VStack {
                                    Image(systemName: "equal")
                                        .font(.system(size: 18))
                                        .foregroundColor(.orange)
                                    Text("中")
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedPriority == .medium ? Color.orange : Color(.systemGray4), lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedPriority == .medium ? Color.orange.opacity(0.1) : Color.clear)
                                        )
                                )
                            }
                            
                            // 高优先级按钮
                            Button(action: {
                                selectedPriority = .high
                            }) {
                                VStack {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                    Text("高")
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedPriority == .high ? Color.red : Color(.systemGray4), lineWidth: 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedPriority == .high ? Color.red.opacity(0.1) : Color.clear)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    
                    // 标签
                    VStack(alignment: .leading, spacing: 10) {
                        Text("标签")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button(action: {
                                    selectedCategory = .work
                                }) {
                                    Text("工作")
                                        .font(.system(size: 14))
                                        .foregroundColor(selectedCategory == .work ? .white : .blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedCategory == .work ? Color.blue : Color.blue.opacity(0.1))
                                        )
                                }
                                
                                Button(action: {
                                    selectedCategory = .personal
                                }) {
                                    Text("个人")
                                        .font(.system(size: 14))
                                        .foregroundColor(selectedCategory == .personal ? .white : .yellow)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedCategory == .personal ? Color.yellow : Color.yellow.opacity(0.1))
                                        )
                                }
                                
                                Button(action: {
                                    selectedCategory = .health
                                }) {
                                    Text("健康")
                                        .font(.system(size: 14))
                                        .foregroundColor(selectedCategory == .health ? .white : .green)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedCategory == .health ? Color.green : Color.green.opacity(0.1))
                                        )
                                }
                                
                                Button(action: {
                                    selectedCategory = .important
                                }) {
                                    Text("购物")
                                        .font(.system(size: 14))
                                        .foregroundColor(.purple)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.purple.opacity(0.1))
                                        )
                                }
                                
                                Button(action: {
                                    // 添加新标签
                                }) {
                                    Text("学习")
                                        .font(.system(size: 14))
                                        .foregroundColor(.indigo)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.indigo.opacity(0.1))
                                        )
                                }
                                
                                Button(action: {
                                    // 添加新标签
                                }) {
                                    Text("+ 新标签")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 估计时间
                    HStack {
                        Text("估计时间")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // 这里可以添加估计时间的选择器，暂时只做UI展示
                        Text("选择时长")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .padding(.trailing, 4)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 15)
                    
                    Spacer()
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
    
    private func saveTask() {
        // 过滤掉空子任务
        let validSubtasks = subtasks.filter { !$0.isEmpty }
            .map { Subtask(title: $0) }
        
        let newTask = Task(
            title: title,
            description: description,
            category: selectedCategory,
            dueDate: hasDueDate ? dueDate : nil,
            priority: selectedPriority,
            subtasks: validSubtasks
        )
        
        taskStore.addTask(newTask)
        
        // 关闭视图
        presentationMode.wrappedValue.dismiss()
    }
    
    private func priorityLabel(for priority: TaskPriority) -> String {
        switch priority {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        }
    }
    
    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

struct AddTaskView_Previews: PreviewProvider {
    @State static var selectedTab = 0
    
    static var previews: some View {
        AddTaskView(selectedTab: $selectedTab)
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
    }
} 