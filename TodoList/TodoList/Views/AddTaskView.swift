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
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .foregroundColor(appSettings.accentColor.color)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(appSettings.accentColor.color, lineWidth: 1)
                    )
                }
                
                Spacer()
                
                Text("新建任务")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 平衡布局的空视图
                Color.clear
                    .frame(width: 70, height: 10)
            }
            .padding()
            .background(Color(.systemBackground))
            
            ScrollView {
                VStack(spacing: 24) {
                    // 任务标题和描述区域
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("任务标题")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("你需要做什么？", text: $title)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("描述")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("添加任务详情")
                                        .foregroundColor(.gray)
                                        .padding(.top, 16)
                                        .padding(.leading, 16)
                                }
                                
                                TextEditor(text: $description)
                                    .padding(8)
                                    .frame(minHeight: 120)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    )
                    
                    // 分类和截止日期
                    HStack(spacing: 16) {
                        // 分类选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("分类")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("选择分类", selection: $selectedCategory) {
                                Text("选择分类").tag(nil as TaskCategory?)
                                ForEach(TaskCategory.allCases, id: \.self) { category in
                                    Text(category.rawValue).tag(category as TaskCategory?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        // 截止日期选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("截止日期")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                DatePicker("", selection: $dueDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .onChange(of: dueDate) { _, _ in
                                        hasDueDate = true
                                    }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    
                    // 时间和优先级
                    HStack(spacing: 16) {
                        // 时间选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("时间")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .onChange(of: dueDate) { _, _ in
                                    hasDueDate = true
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        // 优先级选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("优先级")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases, id: \.self) { priority in
                                    Button(action: {
                                        selectedPriority = priority
                                    }) {
                                        Text(priorityLabel(for: priority))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .foregroundColor(selectedPriority == priority ? .white : priorityColor(for: priority))
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedPriority == priority ? priorityColor(for: priority) : priorityColor(for: priority).opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    
                    // 子任务
                    VStack(alignment: .leading, spacing: 16) {
                        Text("子任务")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(0..<subtasks.count, id: \.self) { index in
                            HStack {
                                TextField("添加子任务", text: $subtasks[index])
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                
                                if subtasks.count > 1 {
                                    Button(action: {
                                        subtasks.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        
                        Button(action: {
                            subtasks.append("")
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(appSettings.accentColor.color)
                                
                                Text("添加另一个子任务")
                                    .foregroundColor(appSettings.accentColor.color)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // 创建任务按钮
                    Button(action: saveTask) {
                        Text("创建任务")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(title.isEmpty ? Color.gray : appSettings.accentColor.color)
                            )
                    }
                    .disabled(title.isEmpty)
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                }
                .padding()
            }
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