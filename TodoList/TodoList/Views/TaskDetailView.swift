import SwiftUI

struct TaskDetailView: View {
    var task: Task
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    if let category = task.category {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(categoryColor(for: category).opacity(0.15))
                            )
                            .foregroundColor(categoryColor(for: category))
                    }
                    
                    Spacer()
                    
                    Text(task.priority.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(priorityColor(for: task.priority).opacity(0.15))
                        )
                        .foregroundColor(priorityColor(for: task.priority))
                }
                
                Text(task.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let dueDate = task.dueDate {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(appSettings.accentColor.color)
                        Text("截止日期: \(formattedDate(dueDate))")
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack(spacing: 16) {
                    Button(action: {
                        var updatedTask = task
                        updatedTask.isCompleted.toggle()
                        taskStore.updateTask(updatedTask)
                    }) {
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : appSettings.accentColor.color)
                            Text(task.isCompleted ? "已完成" : "标记为完成")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        isEditing = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(appSettings.accentColor.color)
                            Text("编辑")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if !task.subtasks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("子任务")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        ForEach(task.subtasks) { subtask in
                            Button(action: {
                                var updatedTask = task
                                if let index = updatedTask.subtasks.firstIndex(where: { $0.id == subtask.id }) {
                                    updatedTask.subtasks[index].isCompleted.toggle()
                                    taskStore.updateTask(updatedTask)
                                }
                            }) {
                                HStack {
                                    Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(subtask.isCompleted ? .green : .gray)
                                    Text(subtask.title)
                                        .strikethrough(subtask.isCompleted)
                                        .foregroundColor(subtask.isCompleted ? .gray : .primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    )
                }
            }
            .padding()
        }
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: task)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func categoryColor(for category: TaskCategory) -> Color {
        switch category {
        case .work:
            return .blue
        case .personal:
            return .purple
        case .health:
            return .green
        case .important:
            return .red
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

struct EditTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    
    var task: Task
    
    @State private var title: String
    @State private var description: String
    @State private var selectedCategory: TaskCategory?
    @State private var selectedPriority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var subtasks: [Subtask] = []
    @State private var newSubtaskTitle: String = ""
    
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
    
    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _selectedCategory = State(initialValue: task.category)
        _selectedPriority = State(initialValue: task.priority)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? EditTaskView.defaultDueDate())
        _subtasks = State(initialValue: task.subtasks)
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
                
                Text("编辑任务")
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
                        
                        ForEach(subtasks.indices, id: \.self) { index in
                            HStack {
                                Button(action: {
                                    subtasks[index].isCompleted.toggle()
                                }) {
                                    Image(systemName: subtasks[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(subtasks[index].isCompleted ? .green : .gray)
                                }
                                
                                TextField("子任务", text: Binding(
                                    get: { subtasks[index].title },
                                    set: { subtasks[index].title = $0 }
                                ))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                
                                Button(action: {
                                    subtasks.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("添加新子任务", text: $newSubtaskTitle)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            
                            Button(action: {
                                if !newSubtaskTitle.isEmpty {
                                    subtasks.append(Subtask(title: newSubtaskTitle))
                                    newSubtaskTitle = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(appSettings.accentColor.color)
                                    .font(.title2)
                            }
                        }
                        
                    }
                    
                    // 保存按钮
                    Button(action: saveTask) {
                        Text("保存更改")
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
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description
        updatedTask.category = selectedCategory
        updatedTask.priority = selectedPriority
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        updatedTask.subtasks = subtasks
        
        taskStore.updateTask(updatedTask)
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